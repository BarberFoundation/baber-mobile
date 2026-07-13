# Code Review — BarberFoundation Mobile (Flutter)

**Data:** 2026-07-12
**Escopo:** `lib/` completo (core + 8 features).
**Stack:** flutter_bloc, dio, go_router, flutter_secure_storage, dartz, firebase_auth.
**Gerenciamento de estado:** BLoC (flutter_bloc) em todo o app.

**Veredito: NÃO pronto para produção.** Ver [bloqueadores](#veredito-final) no fim.

---

## 1. Segurança

### 🟢 Pontos corretos primeiro
- Tokens em `flutter_secure_storage` (Keystore/Keychain), não SharedPreferences — correto (`lib/core/auth/token_storage.dart`).
- Nenhum `print`/log de telefone ou token no fluxo normal.
- Manifest Android sem `usesCleartextTraffic` — cleartext bloqueado por padrão (API 28+).

### 🟠 S1: `API_BASE_URL` default HTTP e sem validação de scheme

**Onde:** `lib/main.dart:28`

```dart
const apiHost = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
```

Build de release sem `--dart-define` compila silenciosamente apontando para `http://localhost:3000`. Não falha no build — falha no primeiro request do usuário, com erro de rede genérico. E se alguém passar `http://` por engano num define de produção, nada impede.

**Correção:** fail-fast no `main()` antes de `runApp`:

```dart
void _assertSecureBaseUrl() {
  if (kReleaseMode && !apiHost.startsWith('https://')) {
    throw StateError('API_BASE_URL deve usar HTTPS em release: $apiHost');
  }
}
```

### 🟡 S2: Interceptor envia `Authorization` velho para `/auth/refresh`

**Onde:** `lib/core/api/api_client.dart:70-74`. O `Options(headers: {})` não impede nada — o `onRequest` do interceptor roda para **todo** request do mesmo `Dio`, incluindo o refresh, e adiciona o access token expirado no header. Não é exploração direta, mas manda credencial morta desnecessariamente.

**Correção:** flag `extra: {'skipAuth': true}` no request de refresh; `onRequest` pula quando presente.

### 🔵 S3: `debugPrint` de erro Firebase com marcador TEMP

**Onde:** `lib/core/firebase/firebase_auth_gateway.dart:37` e fallback `'Erro ao verificar telefone ($code)'` em `lib/features/auth/data/auth_repository_impl.dart:82`. Ambos marcados TEMP. Não vazam telefone, mas expõem código interno ao usuário. Remover antes de release.

---

## 2. Violação de Arquitetura em Camadas

| Regra | Status |
|---|---|
| HTTP direto em Page/ViewModel | ❌ **violado 2×** (A1, A2) |
| `jsonDecode`/parsing fora de `data/models` | ❌ **violado sistematicamente** (A3) |
| Import de `data/` dentro de `domain/` | ✅ ok |
| Regra de negócio em widget | ❌ violado (A4) |
| ViewModel retorna Model em vez de Entity | ⚠️ N/A — camada de model não existe (A3) |

### 🔴 A1: `Dio` injetado no `HomeBloc` e usado direto

**Onde:** `lib/features/home/presentation/home_bloc.dart:24` — `await dio.get('/me')` dentro do bloc.

BLoC é camada de presentation. HTTP ali quebra a regra central: o bloc conhece endpoint, formato de resposta e `DioException`. Lógica de "401 = sessão expirada" duplicada fora do interceptor.

**Correção:** criar `ProfileRepository` (domain) com `getMe()`; bloc recebe o repository, nunca o `Dio`.

### 🔴 A2: HTTP e parsing dentro do router

**Onde:** `lib/core/router/app_router.dart:138-155` — rota `/booking/confirm`:

```dart
future: dio.get('/me').then((r) => r.data as Map<String, dynamic>).catchError((_) => <String, dynamic>{}),
```

Chamada HTTP + cast de JSON dentro de `FutureBuilder` no builder da rota. Sem camada, sem teste, sem erro tipado, e o `catchError` engole tudo (incluindo 401). Mesma correção do A1 — `ProfileRepository.getMe()` serve para os dois.

### 🟠 A3: `fromJson` nas entities de domain — camada `data/models` não existe

**Onde:** `auth_user.dart:12`, `service.dart:18`, `tenant.dart`, `time_slot.dart`, `appointment.dart` — todas as entities de `domain/` fazem parsing de JSON.

Domain conhece o formato do wire: se o backend renomear um campo, quem muda é a entity de domínio. Decisão a tomar conscientemente: criar os models agora (~10 arquivos mecânicos) ou documentar que entities fazem double-duty. Não pode ficar implícito.

### 🟠 A4: Regra de negócio duplicada em widget

**Onde:** `lib/features/appointments/presentation/my_appointments_screen.dart:131-137` — filtro de "próximas vs histórico" (status + parse de data + comparação com `now`) dentro do `build()`. Mesma regra reescrita em `home_bloc.dart:40-47`. Já divergem: o Home ordena, a tela não.

**Correção:** mover para a entity:

```dart
bool get isUpcoming =>
    status != AppointmentStatus.cancelled &&
    status != AppointmentStatus.completed &&
    startDateTime.isAfter(DateTime.now());

DateTime get startDateTime => DateTime.parse('${date}T$startTime:00');
```

### 🟡 A5: Logout implementado dentro do widget

**Onde:** `lib/features/home/presentation/home_screen.dart:47-51` — `HomeScreen` recebe `TokenStorage`/`TenantStorage` no construtor e limpa sessão direto. Deveria ser evento num `SessionBloc`/`AuthBloc`.

---

## 3. Correção e Lógica

### 🔴 C1: Errar o código OTP uma vez mata o fluxo — `verificationId` perdido

**Onde:** `lib/features/auth/presentation/auth_state.dart:27` + `auth_bloc.dart:47-59`.

`AuthState.error(message)` zera **todos** os campos, incluindo `verificationId`. Sequência: código errado → `error` → `verificationId = null` → código **certo** → "Código expirado. Solicite um novo." Todo erro de digitação força reenvio de SMS (que esbarra no rate limit do Firebase).

Mesmo defeito apaga `codeSentToPhone`: após erro, header da tela OTP mostra "Enviado para " vazio, e `_submit` passa `phone: ''` no resend.

**Correção:** estado único com `copyWith`, erro não destrói contexto (mesmo padrão que `BookingState` já usa):

```dart
emit(state.copyWith(errorMessage: failureMessage(failure), isLoading: false));
```

### 🟠 C2: Auto-verificação do Android deixa usuário preso na tela de telefone

**Onde:** `lib/features/auth/presentation/phone_screen.dart:50-58`. Listener só trata `errorMessage` e `codeSentToPhone`. No Android, `verificationCompleted` pode disparar **antes** do `codeSent` (verificação instantânea). O `AuthBloc` emite `authenticated`/`needsName` — e o `PhoneScreen` ignora ambos. Usuário logado, tela parada.

**Correção:** replicar no `PhoneScreen` o bloco do listener do `OtpScreen` (`needsName → /name`, `authenticated → /home`).

### 🟠 C3: Refresh de token sem single-flight — 401 concorrente desloga usuário

**Onde:** `lib/core/api/api_client.dart:41-49`.

`HomeBloc._onLoad` dispara `/me`, `/appointments/my` e `/services` quase juntos. Token expirado → três 401 → **três** `_tryRefresh()` paralelos. Backend rotaciona refresh token → primeiro ganha, outros falham com token consumido → `tokenStorage.clear()` → usuário deslogado no cenário mais comum (voltar ao app após expiração).

**Correção:** mutex com `Completer`:

```dart
Future<bool>? _refreshing;
Future<bool> _tryRefresh() {
  return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
}
```

### 🟠 C4: Sessão expirada sem rota de saída fora da Home

**Onde:** `lib/core/error/failure.dart:24` + todos os `_mapError`. `UnauthorizedFailure` existe mas **nenhum** repositório a produz — `_mapError` sempre devolve `ApiFailure(401, ...)`. Quando o refresh falha e o interceptor limpa tokens, telas fora da Home só mostram snackbar cru e continuam renderizando. Só a Home trata 401 (`home_bloc.dart:27-29`), na mão.

**Correção:** `_mapError` compartilhado mapeando `401 → UnauthorizedFailure` + telas navegando para `/phone`. Melhor: stream de sessão no `ApiClient` escutada pelo router via `refreshListenable`.

### 🟡 C5: Tela de slots sem estado de erro — falha de rede vira "nenhum horário disponível"

**Onde:** `lib/features/booking/presentation/slot_selection_screen.dart:22-30` + `booking_bloc.dart:20-24`. No failure, bloc emite só `errorMessage` — tela não tem listener nem exibe. Com `slots == null`, cai no empty state: rede ruim vira "Nenhum horário disponível nesta data". Empty state mentiroso = bug de receita. Pior: `copyWith` preserva `slots` antigos — falha ao trocar de data mostra horários **da data anterior**.

**Correção:** `BlocConsumer` com listener de erro + "Tentar novamente"; limpar slots ao selecionar data.

### 🟡 C6: Cancelamento com falha apaga a lista da tela

**Onde:** `lib/features/appointments/presentation/my_appointments_bloc.dart:43-52`. `_onCancel` emite `loading()` (lista some), erro emite `MyAppointmentsState.error(...)` sem `appointments`. Tela mostra "Você ainda não tem consultas" + snackbar. Dados sumiram até pull-to-refresh.

**Correção:** estado com `copyWith` preservando a lista.

### 🟡 C7: `DateTime.parse` cru dentro do `build()`

**Onde:** `my_appointments_screen.dart:135`. `date`/`startTime` malformado → `FormatException` no build → tela vermelha. Parsing pertence à entity (getter `startDateTime`, ver A4) com `DateTime.tryParse`.

### 🟡 C8: `state.extra as Service` — cast duro no router

**Onde:** `app_router.dart:130`. Restore de processo (Android mata app em background) → `extra` não serializado pelo go_router → `TypeError` no boot da rota.

**Correção:** `serviceId` como path param + fetch do repository, ou `as Service?` com redirect para `/services`.

### 🔵 C9: Duplo null-assert no gateway

**Onde:** `firebase_auth_gateway.dart:56` — `(await userCredential.user!.getIdToken())!`. Se `user` for null, crash sem mensagem em vez de `FirebaseAuthFailure`. Guard barato.

### 🟢 Concorrência de duplo-tap: OK
Todos os botões de submit guardam `state.isLoading`. Duplo agendamento coberto.

---

## 4. Performance Mobile

Nada bloqueante. App pequeno, listas curtas.

- 🔵 **P1:** `home_bloc.dart:36` busca catálogo inteiro só para resolver nome de 1 agendamento (repetido em `my_appointments_bloc`). Fix certo: backend devolver `serviceName` embutido.
- 🔵 **P2:** cancelar 1 agendamento recarrega lista + serviços. OK neste volume.
- 🔵 **P3:** `my_appointments_screen` usa `ListView` com spread em vez de `.builder` — fine para dezenas de itens; `GridView.builder`/`ListView.separated` corretos onde importa.
- 🟢 `const` bem aplicado; blocs escopados por rota via `BlocProvider` (dispose automático correto).

---

## 5. Legibilidade e Manutenção

### 🟠 L1: `_mapError` copiado 6 vezes

Método idêntico em 6 repositórios. Quando C4 for corrigido, serão 6 lugares para mudar. Extrair `mapDioError` para `core/error/`.

### 🟡 L2: `AuthState` com 6 campos nullable órfãos
Causa-raiz do C1. Cada construtor nomeado é combinação implícita de nulls que ninguém valida. `BookingState` (copyWith) é o padrão certo — unificar.

### 🔵 L3: Identidade do app
`pubspec.yaml` description "A new Flutter project", `android:label="baber_mobile"`, versão `1.0.0+1`. Trocar antes de build de distribuição.

### 🟢 Positivos
- Cobertura de testes rara em app mobile novo: bloc tests, repository tests, widget tests, e `isRefreshRequestPath` extraído para testabilidade do guard de recursão.
- Comentários explicando porquês não-óbvios.
- `sealed class Failure` + switch exaustivo — Failure novo quebra compilação até tratar. Correto.
- Feature-first folders consistentes, DI manual limpa.

---

## Veredito final

**NÃO pronto para produção.** Bloqueiam release, em ordem:

| # | Item | Severidade |
|---|------|-----------|
| 1 | C1 — Errar OTP uma vez destrói `verificationId`; código correto passa a falhar | 🔴 Crítico |
| 2 | C2 — Auto-verificação Android deixa usuário autenticado preso na tela de telefone | 🟠 Alto |
| 3 | C3 — Refresh sem single-flight desloga usuário em 401 concorrente | 🟠 Alto |
| 4 | C4 — Sessão expirada sem redirect fora da Home | 🟠 Alto |
| 5 | S1 — Release compila apontando para `http://localhost` sem reclamar | 🟠 Alto |

C1+C2+C3 juntos: o funil inteiro de login e retorno ao app tem três buracos.

Follow-up (não bloqueia): A1/A2 (HTTP na presentation), A3 (camada de models), C5/C6 (estados de erro), L1 (`mapDioError` compartilhado), A4/C7, C8, S2/S3, L3.

Arquitetura no geral é sólida — camadas existem, testes existem. Problemas concentrados em gestão de estado de erro (`AuthState`) e ciclo de vida de sessão, não estruturais.

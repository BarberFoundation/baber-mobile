# Mobile Firebase Phone Auth — Design

Status: aprovado. Depende de: backend `POST /auth/client/exchange` (já implementado em `baber-plataform`, branch `master`). Bloqueia: nenhum plano existente.

## Contexto

O backend (`baber-plataform`) removeu a stack custom de OTP/Evolution e substituiu por Firebase phone auth nativo. O app mobile (`baber-mobile`) ainda chama os endpoints antigos `POST /auth/otp/request` e `POST /auth/otp/verify`, que não existem mais — o login por telefone está quebrado. Este spec cobre a migração do app para usar `firebase_auth` no lugar do fluxo OTP customizado.

O painel web (`baber-plataform/apps/web`) já fez a mesma migração usando o Firebase JS SDK (`signInWithPhoneNumber` + `RecaptchaVerifier`). O mobile usa uma API diferente do SDK (`verifyPhoneNumber`, callback-based, sem reCAPTCHA em device real), então a implementação não é um port direto — mas o endpoint de troca de token no backend é o mesmo padrão: obter um Firebase `idToken` client-side e trocá-lo por um par de tokens da aplicação via `POST /auth/client/exchange` (`{ idToken, tenantId }` → `{ accessToken, refreshToken, expiresIn, user }`).

## Escopo

Migrar o fluxo de login por telefone do app mobile (Flutter) de OTP customizado para Firebase Phone Auth nativo, mantendo a etapa de "completar nome" (`NameSubmitted` → `PATCH /me`) inalterada.

Fora de escopo: configuração nativa do Firebase (Android/iOS), habilitação de Phone Auth no console, cadastro de SHA-1/SHA-256, configuração de APNs — todos ficam como follow-up manual do usuário (ver seção final), pois exigem acesso autenticado ao Firebase Console/CLI que este agente não tem.

## Arquitetura

### Novas dependências (`pubspec.yaml`)

```yaml
firebase_core: ^3.x
firebase_auth: ^5.x
```

### Wrapper de testabilidade — `lib/core/firebase/firebase_auth_gateway.dart`

`FirebaseAuth`/`PhoneAuthCredential` do SDK nativo são difíceis de mockar diretamente com `mocktail` (classes finais, sem construtores triviais). Um wrapper fino isola o SDK atrás de uma interface própria, testável:

```dart
abstract class FirebaseAuthGateway {
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String idToken) onAutoVerified,
    required void Function(String code, String message) onVerificationFailed,
  });

  Future<String> confirmCode({
    required String verificationId,
    required String smsCode,
  }); // returns idToken
}

class FirebaseAuthGatewayImpl implements FirebaseAuthGateway {
  final FirebaseAuth _auth;
  const FirebaseAuthGatewayImpl(this._auth);
  // internamente chama _auth.verifyPhoneNumber(...) e _auth.signInWithCredential(...),
  // extrai idToken via credential.user.getIdToken() antes de expor pros callers.
}
```

Isso espelha o padrão já usado no web (`apps/web/src/lib/firebase.ts` isola `firebaseAuth` do resto do app).

### Novo tipo de erro — `lib/core/error/failure.dart`

```dart
class FirebaseAuthFailure extends Failure {
  final String code;
  final String message;
  const FirebaseAuthFailure({required this.code, required this.message});

  @override
  List<Object?> get props => [code, message];
}
```

`lib/core/error/failure_message.dart` ganha o case:
```dart
FirebaseAuthFailure(:final message) => message,
```

Mapeamento código Firebase → mensagem pt-BR (dentro do repository, mesmo conteúdo do web):

| Código Firebase | Mensagem |
|---|---|
| `invalid-phone-number` | Número de telefone inválido. |
| `too-many-requests` | Muitas tentativas. Tente novamente mais tarde. |
| `invalid-verification-code` | Código de verificação inválido. |
| `session-expired` | Código expirado. Solicite um novo. |
| (outro) | Erro ao verificar telefone. |

## Fluxo de dados

### `AuthRepository` (interface) — `lib/features/auth/domain/auth_repository.dart`

Remove `requestOtp`/`verifyOtp`. Adiciona:

```dart
abstract class AuthRepository {
  Future<void> requestPhoneCode({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(Either<Failure, AuthResult> result) onAutoVerified,
    required void Function(Failure failure) onVerificationFailed,
  });

  Future<Either<Failure, AuthResult>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  Future<Either<Failure, AuthUser>> updateName(String name); // inalterado
}
```

### `AuthRepositoryImpl` — `lib/features/auth/data/auth_repository_impl.dart`

Passa a depender de `FirebaseAuthGateway` além de `Dio`/`TenantStorage`:

```dart
const AuthRepositoryImpl(this._gateway, this._dio, this._tenantStorage);

Future<void> requestPhoneCode({...}) async {
  await _gateway.verifyPhoneNumber(
    phoneNumber: phone,
    onCodeSent: onCodeSent,
    onAutoVerified: (idToken) async {
      final result = await _exchangeToken(idToken);
      onAutoVerified(result);
    },
    onVerificationFailed: (code, message) =>
        onVerificationFailed(FirebaseAuthFailure(code: code, message: _mapCode(code))),
  );
}

Future<Either<Failure, AuthResult>> confirmPhoneCode({...}) async {
  try {
    final idToken = await _gateway.confirmCode(verificationId: verificationId, smsCode: smsCode);
    return _exchangeToken(idToken);
  } on FirebaseAuthException catch (e) {
    return Left(FirebaseAuthFailure(code: e.code, message: _mapCode(e.code)));
  }
}

Future<Either<Failure, AuthResult>> _exchangeToken(String idToken) async {
  try {
    final tenantId = (await _tenantStorage.readTenantId())!;
    final response = await _dio.post('/auth/client/exchange', data: {'idToken': idToken, 'tenantId': tenantId});
    return Right(AuthResult.fromJson(response.data as Map<String, dynamic>));
  } on DioException catch (e) {
    return Left(_mapDioError(e)); // reaproveita _mapError existente
  }
}
```

### `AuthBloc` — `lib/features/auth/presentation/auth_bloc.dart`

Ganha 3 eventos internos, não expostos às telas (adicionados via `add()` de dentro dos próprios callbacks passados ao repository — padrão padrão para empacotar APIs callback-based em bloc):

```dart
on<PhoneSubmitted>(_onPhoneSubmitted);
on<_CodeSent>(_onCodeSent);
on<_AutoVerified>(_onAutoVerified);
on<_VerificationFailed>(_onVerificationFailed);
on<CodeSubmitted>(_onCodeSubmitted);
on<NameSubmitted>(_onNameSubmitted); // inalterado
```

`_onPhoneSubmitted` chama `repository.requestPhoneCode(...)` passando lambdas que fazem `add(_CodeSent(...))` / `add(_AutoVerified(...))` / `add(_VerificationFailed(...))`.

`_onCodeSent` guarda `verificationId` no estado e emite `codeSent(phone)` (como hoje).

`_onAutoVerified` — se sucesso, salva tokens e emite `needsName`/`authenticated` (mesma lógica que `_onCodeSubmitted` já tem hoje); se falha, emite `error`.

`_onCodeSubmitted` agora usa `verificationId` do estado (não mais `phone`+`code` direto pro backend) para chamar `repository.confirmPhoneCode(...)`.

### `AuthState` — ganha campo `verificationId` (String?), setado por `codeSent` e lido por `_onCodeSubmitted`.

### Telas

- `phone_screen.dart`: sem mudança de UI. O listener do `BlocConsumer` precisa também reagir a `authenticatedUser`/`userNeedingName` diretamente (hoje só reage a `codeSentToPhone`), para o caso de auto-verificação Android pular a tela de código.
- `otp_screen.dart`: sem mudança de UI. "Reenviar código" continua disparando `PhoneSubmitted(phone)`.

### `main.dart` / `baber_app.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // usa firebase_options.dart gerado por `flutterfire configure`
  // ...resto inalterado, exceto:
  final authRepository = AuthRepositoryImpl(
    FirebaseAuthGatewayImpl(FirebaseAuth.instance),
    apiClient.dio,
    tenantStorage,
  );
  // ...
}
```

## Testes

- `test/features/auth/data/auth_repository_impl_test.dart`: reescrito. Mocka `FirebaseAuthGateway` (interface própria, via `mocktail`) e `Dio` — não toca SDK nativo do Firebase. Cobre: código enviado, auto-verificação com sucesso/falha, confirmação de código com sucesso/falha, mapeamento de erros de `FirebaseAuthException` e de `DioException`.
- `test/features/auth/presentation/auth_bloc_test.dart`: reescrito com `bloc_test`, cobrindo sequências de estado incluindo o caminho de auto-verificação (`loading` → `authenticated`, pulando `codeSent`) e o caminho manual (`loading` → `codeSent` → `loading` → `authenticated`/`needsName`).

## Follow-up manual (fora do escopo deste agente)

1. ~~`flutterfire configure`~~ — feito. Projeto `baber-fundation` (mesmo do web), apps Android/iOS registrados, `lib/firebase_options.dart` gerado com valores reais, `android/app/google-services.json` + wiring do Gradle plugin adicionados.
2. Habilitar Phone Auth no Firebase Console (se ainda não habilitado).
3. Android: cadastrar SHA-1/SHA-256 do app no Firebase (necessário para SMS Retriever / auto-verificação).
4. iOS: `flutterfire configure` não gerou `ios/Runner/GoogleService-Info.plist` (limitação do CLI rodando fora do macOS/sem Xcode). Precisa rodar `flutterfire configure --platforms=ios` (ou baixar manualmente pelo Firebase Console) numa máquina com Xcode, e então configurar APNs (Phone Auth no iOS depende de push silencioso para verificação).

Sem os passos 2–4, o app compila e `Firebase.initializeApp()` funciona (config Android real já presente), mas o fluxo de phone auth em si (SMS real, auto-verificação) só é testável end-to-end depois de habilitar Phone Auth no console e cadastrar SHA-1/SHA-256. iOS além disso precisa do plist gerado numa máquina com Xcode.

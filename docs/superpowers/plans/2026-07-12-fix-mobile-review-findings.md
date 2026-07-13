# Fix Mobile Review Findings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir os bloqueadores (C1, C2, C3, C4, S1) e follow-ups (C5, C6, L1, A1/A2) do review `docs/reviews/2026-07-12-review-mobile-flutter.md` no app Flutter.

**Architecture:** Manter camadas existentes (presentation/domain/data por feature + core). Introduzir `mapDioError` compartilhado em `core/error/`, utilitário `SingleFlight` em `core/api/`, feature `profile/` com `ProfileRepository` para tirar `Dio` da presentation, e refatorar `AuthState` para o padrão `copyWith` (igual `BookingState`), preservando contexto entre erros.

**Tech Stack:** Flutter, flutter_bloc, dio, go_router, dartz, mocktail, bloc_test.

**Diretório de trabalho:** `C:\Users\gabry\Documents\baber-mobile` (todos os comandos rodam daqui).

---

## Setup (antes da Task 1)

O repo tem 2 arquivos modificados não commitados (`lib/core/firebase/firebase_auth_gateway.dart` e `lib/features/auth/data/auth_repository_impl.dart` — debug logging TEMP do S3). Eles ficam como estão; não fazem parte deste plano.

```bash
git checkout -b fix/mobile-review-findings
git add docs/reviews/2026-07-12-review-mobile-flutter.md docs/superpowers/plans/2026-07-12-fix-mobile-review-findings.md
git commit -m "docs: add mobile code review and fix plan"
```

Verificar baseline verde antes de começar:

```bash
flutter test
```

Expected: todos os testes passam. Se algo falhar, PARAR e reportar.

---

## Mapa de arquivos

| Task | Achado | Cria | Modifica |
|---|---|---|---|
| 1 | L1 + C4a | `lib/core/error/dio_failure_mapper.dart`, teste | 6 repositórios (remove `_mapError`) |
| 2 | C1/L2 | — | `auth_state.dart`, `auth_bloc.dart`, testes de auth |
| 3 | C2 | — | `phone_screen.dart`, `phone_screen_test.dart` |
| 4 | C3 | `lib/core/api/single_flight.dart`, teste | `api_client.dart` |
| 5 | A1/A2 | `lib/features/profile/domain/profile_repository.dart`, `lib/features/profile/data/profile_repository_impl.dart`, teste | `home_bloc.dart`, `app_router.dart`, `main.dart`, `baber_app.dart`, `home_bloc_test.dart` |
| 6 | C4b | — | `my_appointments_state.dart`, `my_appointments_bloc.dart`, `my_appointments_screen.dart`, `notifications_state.dart`, `notifications_bloc.dart`, `notifications_screen.dart`, `home_screen.dart`, bloc tests |
| 7 | C5 | — | `booking_bloc.dart`, `slot_selection_screen.dart`, testes |
| 8 | C6 | — | `my_appointments_bloc.dart`, `my_appointments_screen.dart`, teste |
| 9 | S1 | `lib/core/config/base_url_guard.dart`, teste | `main.dart` |
| 10 | — | — | verificação final |

---

### Task 1: `mapDioError` compartilhado com 401 → `UnauthorizedFailure` (L1 + C4 parte 1)

**Files:**
- Create: `lib/core/error/dio_failure_mapper.dart`
- Test: `test/core/error/dio_failure_mapper_test.dart`
- Modify: `lib/features/auth/data/auth_repository_impl.dart`, `lib/features/booking/data/booking_repository_impl.dart`, `lib/features/appointments/data/appointment_repository_impl.dart`, `lib/features/tenant_selection/data/tenant_repository_impl.dart`, `lib/features/notifications/data/notifications_repository_impl.dart`, `lib/features/catalog/data/service_repository_impl.dart`

- [ ] **Step 1: Write the failing test**

Criar `test/core/error/dio_failure_mapper_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/error/dio_failure_mapper.dart';
import 'package:baber_mobile/core/error/failure.dart';

DioException _dioError({int? statusCode, dynamic data, String? message}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    message: message,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode, data: data),
  );
}

void main() {
  test('maps missing response to NetworkFailure with dio message', () {
    expect(mapDioError(_dioError(message: 'timeout')), const NetworkFailure('timeout'));
  });

  test('maps missing response and null message to generic NetworkFailure', () {
    expect(mapDioError(_dioError()), const NetworkFailure('network error'));
  });

  test('maps 401 to UnauthorizedFailure regardless of body', () {
    expect(
      mapDioError(_dioError(statusCode: 401, data: {'message': 'Unauthorized'})),
      const UnauthorizedFailure(),
    );
  });

  test('maps other status codes to ApiFailure with backend message', () {
    expect(
      mapDioError(_dioError(statusCode: 409, data: {'message': 'conflito'})),
      const ApiFailure(statusCode: 409, message: 'conflito'),
    );
  });

  test('falls back to generic message when body is not a map', () {
    expect(
      mapDioError(_dioError(statusCode: 500, data: 'oops')),
      const ApiFailure(statusCode: 500, message: 'api error'),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/error/dio_failure_mapper_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'baber_mobile/core/error/dio_failure_mapper.dart'` (arquivo não existe).

- [ ] **Step 3: Write minimal implementation**

Criar `lib/core/error/dio_failure_mapper.dart`:

```dart
import 'package:dio/dio.dart';
import 'failure.dart';

/// Mapeamento único de DioException → Failure para todos os repositórios.
/// 401 vira UnauthorizedFailure para que as telas possam reagir a sessão
/// expirada de forma uniforme (ver C4 do review).
Failure mapDioError(DioException e) {
  final statusCode = e.response?.statusCode;
  if (statusCode == null) return NetworkFailure(e.message ?? 'network error');
  if (statusCode == 401) return const UnauthorizedFailure();
  final data = e.response?.data;
  final message = (data is Map) ? (data['message']?.toString() ?? 'api error') : 'api error';
  return ApiFailure(statusCode: statusCode, message: message);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/error/dio_failure_mapper_test.dart`
Expected: PASS (5 testes).

- [ ] **Step 5: Substituir `_mapError` nos 6 repositórios**

Em **cada** um dos 6 arquivos abaixo, fazer a mesma mudança:
1. Adicionar import: `import '../../../core/error/dio_failure_mapper.dart';`
2. Trocar toda chamada `_mapError(e)` por `mapDioError(e)`.
3. Deletar o método privado `_mapError` inteiro.

Arquivos:
- `lib/features/auth/data/auth_repository_impl.dart`
- `lib/features/booking/data/booking_repository_impl.dart`
- `lib/features/appointments/data/appointment_repository_impl.dart`
- `lib/features/tenant_selection/data/tenant_repository_impl.dart`
- `lib/features/notifications/data/notifications_repository_impl.dart`
- `lib/features/catalog/data/service_repository_impl.dart`

Verificar que nenhum sobrou: `grep -rn "_mapError" lib/` → deve retornar vazio.

- [ ] **Step 6: Rodar a suíte inteira e corrigir testes que esperavam `ApiFailure` 401**

Run: `flutter test`

Se algum teste de repositório falhar esperando `ApiFailure(statusCode: 401, ...)`, atualizar a expectativa para `const Left(UnauthorizedFailure())`. Exemplo do padrão de correção:

```dart
// ANTES
expect(result, const Left(ApiFailure(statusCode: 401, message: 'Unauthorized')));
// DEPOIS
expect(result, const Left(UnauthorizedFailure()));
```

Expected ao final: PASS completo.

- [ ] **Step 7: Commit**

```bash
git add lib/core/error/dio_failure_mapper.dart test/core/error/dio_failure_mapper_test.dart lib/features/*/data/*.dart test/
git commit -m "refactor(core): extract shared mapDioError, map 401 to UnauthorizedFailure"
```

---

### Task 2: `AuthState` com `copyWith` — erro preserva `verificationId` (C1/L2)

**Files:**
- Modify: `lib/features/auth/presentation/auth_state.dart`
- Modify: `lib/features/auth/presentation/auth_bloc.dart`
- Test: `test/features/auth/presentation/auth_bloc_test.dart` (novo teste + atualizar existentes)
- Modify: `test/features/auth/presentation/otp_screen_test.dart`, `test/features/auth/presentation/phone_screen_test.dart`, `test/features/auth/presentation/name_screen_test.dart` (trocar construtores nomeados removidos)

- [ ] **Step 1: Write the failing test**

Adicionar em `test/features/auth/presentation/auth_bloc_test.dart` (dentro do `main`, usa os mesmos `repository`/`tokenStorage`/`authResult`/`userNeedsName` já definidos no arquivo):

```dart
blocTest<AuthBloc, AuthState>(
  'preserva verificationId após erro: código errado seguido de código certo autentica',
  build: () {
    when(() => repository.confirmPhoneCode(verificationId: 'ver-123', smsCode: '000000'))
        .thenAnswer((_) async => const Left(FirebaseAuthFailure(
              code: 'invalid-verification-code',
              message: 'Código de verificação inválido.',
            )));
    when(() => repository.confirmPhoneCode(verificationId: 'ver-123', smsCode: '123456'))
        .thenAnswer((_) async => const Right(authResult));
    return AuthBloc(repository: repository, tokenStorage: tokenStorage);
  },
  seed: () => const AuthState(codeSentToPhone: '+5511999999999', verificationId: 'ver-123'),
  act: (bloc) async {
    bloc.add(const CodeSubmitted(phone: '+5511999999999', code: '000000'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const CodeSubmitted(phone: '+5511999999999', code: '123456'));
  },
  verify: (bloc) {
    expect(bloc.state.userNeedingName, userNeedsName);
    verify(() => repository.confirmPhoneCode(verificationId: 'ver-123', smsCode: '123456')).called(1);
  },
);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/auth_bloc_test.dart`
Expected: FAIL — o segundo `CodeSubmitted` cai em `verificationId == null` (estado de erro destruiu o campo) e o mock `confirmPhoneCode(..., smsCode: '123456')` nunca é chamado. (O teste novo também pode falhar em compilação se `seed` usar o construtor plain — ele já existe, então compila.)

- [ ] **Step 3: Reescrever `auth_state.dart`**

Substituir o conteúdo de `lib/features/auth/presentation/auth_state.dart` por:

```dart
import 'package:equatable/equatable.dart';
import '../domain/auth_user.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final String? codeSentToPhone;
  final String? verificationId;
  final AuthUser? userNeedingName;
  final AuthUser? authenticatedUser;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.codeSentToPhone,
    this.verificationId,
    this.userNeedingName,
    this.authenticatedUser,
    this.errorMessage,
  });

  const AuthState.initial() : this();

  /// errorMessage e isLoading resetam a cada transição, a menos que passados
  /// explicitamente. Os demais campos são preservados — um erro de código
  /// não pode destruir o verificationId do SMS em andamento (C1 do review).
  AuthState copyWith({
    bool isLoading = false,
    String? codeSentToPhone,
    String? verificationId,
    AuthUser? userNeedingName,
    AuthUser? authenticatedUser,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading,
      codeSentToPhone: codeSentToPhone ?? this.codeSentToPhone,
      verificationId: verificationId ?? this.verificationId,
      userNeedingName: userNeedingName ?? this.userNeedingName,
      authenticatedUser: authenticatedUser ?? this.authenticatedUser,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, codeSentToPhone, verificationId, userNeedingName, authenticatedUser, errorMessage];
}
```

(Construtores nomeados `loading`, `codeSent`, `needsName`, `authenticated`, `error` são **removidos** — eram a causa-raiz do bug.)

- [ ] **Step 4: Atualizar `auth_bloc.dart` para usar `copyWith`**

Substituir os handlers em `lib/features/auth/presentation/auth_bloc.dart`:

```dart
Future<void> _onPhoneSubmitted(PhoneSubmitted event, Emitter<AuthState> emit) async {
  emit(state.copyWith(isLoading: true));
  await repository.requestPhoneCode(
    phone: event.phone,
    onCodeSent: (verificationId) => add(PhoneCodeSent(phone: event.phone, verificationId: verificationId)),
    onAutoVerified: (result) => add(AutoVerificationCompleted(result)),
    onVerificationFailed: (failure) => add(PhoneVerificationFailed(failure)),
  );
}

void _onPhoneCodeSent(PhoneCodeSent event, Emitter<AuthState> emit) {
  emit(state.copyWith(codeSentToPhone: event.phone, verificationId: event.verificationId));
}

Future<void> _onAutoVerificationCompleted(AutoVerificationCompleted event, Emitter<AuthState> emit) async {
  await event.result.fold(
    (failure) async => emit(state.copyWith(errorMessage: failureMessage(failure))),
    (authResult) => _completeLogin(authResult, emit),
  );
}

void _onPhoneVerificationFailed(PhoneVerificationFailed event, Emitter<AuthState> emit) {
  emit(state.copyWith(errorMessage: failureMessage(event.failure)));
}

Future<void> _onCodeSubmitted(CodeSubmitted event, Emitter<AuthState> emit) async {
  final verificationId = state.verificationId;
  emit(state.copyWith(isLoading: true));
  if (verificationId == null) {
    emit(state.copyWith(errorMessage: 'Código expirado. Solicite um novo.'));
    return;
  }
  final result = await repository.confirmPhoneCode(verificationId: verificationId, smsCode: event.code);
  await result.fold(
    (failure) async => emit(state.copyWith(errorMessage: failureMessage(failure))),
    (authResult) => _completeLogin(authResult, emit),
  );
}

Future<void> _onNameSubmitted(NameSubmitted event, Emitter<AuthState> emit) async {
  emit(state.copyWith(isLoading: true));
  final result = await repository.updateName(event.name);
  result.fold(
    (failure) => emit(state.copyWith(errorMessage: failureMessage(failure))),
    (user) => emit(state.copyWith(authenticatedUser: user)),
  );
}

Future<void> _completeLogin(AuthResult authResult, Emitter<AuthState> emit) async {
  await tokenStorage.saveTokens(
    accessToken: authResult.accessToken,
    refreshToken: authResult.refreshToken,
  );
  if (authResult.user.needsName) {
    emit(state.copyWith(userNeedingName: authResult.user));
  } else {
    emit(state.copyWith(authenticatedUser: authResult.user));
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/auth/presentation/auth_bloc_test.dart`
Expected: o teste novo PASSA. Testes antigos do arquivo FALHAM em compilação/expectativa (usam construtores removidos) — corrigidos no próximo step.

- [ ] **Step 6: Atualizar testes existentes que usam os construtores removidos**

Mapa de substituição (aplicar em `auth_bloc_test.dart`, `otp_screen_test.dart`, `phone_screen_test.dart`, `name_screen_test.dart`):

| Antes | Depois |
|---|---|
| `const AuthState.loading()` | `const AuthState(isLoading: true)` |
| `const AuthState.codeSent(phone: P, verificationId: V)` | `const AuthState(codeSentToPhone: P, verificationId: V)` |
| `const AuthState.needsName(U)` | `const AuthState(userNeedingName: U)` |
| `const AuthState.authenticated(U)` | `const AuthState(authenticatedUser: U)` |
| `const AuthState.error(M)` | `const AuthState(errorMessage: M)` |

**Atenção às sequências `expect` de bloc_test:** com `copyWith`, estados subsequentes agora **preservam** campos anteriores. Exemplos concretos do `auth_bloc_test.dart`:

```dart
// Teste 'emits [loading, codeSent] ...' — partia de initial, não muda estrutura:
expect: () => [
  const AuthState(isLoading: true),
  const AuthState(codeSentToPhone: '+5511999999999', verificationId: 'ver-123'),
],

// Teste que parte de codeSent e erra o código — o erro agora PRESERVA phone/verificationId:
// antes: const AuthState.error('Código de verificação inválido.')
// depois:
const AuthState(
  codeSentToPhone: '+5511999999999',
  verificationId: 'ver-123',
  errorMessage: 'Código de verificação inválido.',
),
```

Regra geral: pegar o estado anterior da sequência e aplicar a mudança por cima, zerando `isLoading`/`errorMessage` a menos que definidos.

- [ ] **Step 7: Rodar todos os testes de auth**

Run: `flutter test test/features/auth/`
Expected: PASS completo.

- [ ] **Step 8: Commit**

```bash
git add lib/features/auth/presentation/ test/features/auth/presentation/
git commit -m "fix(auth): preserve verificationId across errors via AuthState copyWith"
```

---

### Task 3: `PhoneScreen` navega quando auto-verificação autentica direto (C2)

**Files:**
- Modify: `lib/features/auth/presentation/phone_screen.dart:50-58`
- Test: `test/features/auth/presentation/phone_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Adicionar em `test/features/auth/presentation/phone_screen_test.dart` (usa o `MockAuthBloc` já existente no arquivo; adicionar imports `package:go_router/go_router.dart` e `package:baber_mobile/features/auth/domain/auth_user.dart` se ausentes):

```dart
GoRouter _routerFor(MockAuthBloc bloc) => GoRouter(
      initialLocation: '/phone',
      routes: [
        GoRoute(
          path: '/phone',
          builder: (_, __) => BlocProvider<AuthBloc>.value(value: bloc, child: const PhoneScreen()),
        ),
        GoRoute(path: '/otp', builder: (_, __) => const Scaffold(body: Text('OTP_SCREEN'))),
        GoRoute(path: '/name', builder: (_, __) => const Scaffold(body: Text('NAME_SCREEN'))),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('HOME_SCREEN'))),
        GoRoute(path: '/tenant-selection', builder: (_, __) => const Scaffold(body: Text('TENANT'))),
      ],
    );

testWidgets('navega para /home quando auto-verificação autentica usuário com nome', (tester) async {
  whenListen(
    bloc,
    Stream.fromIterable([
      const AuthState(isLoading: true),
      const AuthState(authenticatedUser: AuthUser(id: 'u1', name: 'Gab', phone: '+5511999999999')),
    ]),
    initialState: const AuthState.initial(),
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: _routerFor(bloc)));
  await tester.pumpAndSettle();

  expect(find.text('HOME_SCREEN'), findsOneWidget);
});

testWidgets('navega para /name quando auto-verificação autentica usuário sem nome', (tester) async {
  whenListen(
    bloc,
    Stream.fromIterable([
      const AuthState(isLoading: true),
      const AuthState(userNeedingName: AuthUser(id: 'u1', name: null, phone: '+5511999999999')),
    ]),
    initialState: const AuthState.initial(),
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: _routerFor(bloc)));
  await tester.pumpAndSettle();

  expect(find.text('NAME_SCREEN'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/phone_screen_test.dart`
Expected: FAIL — `HOME_SCREEN`/`NAME_SCREEN` não encontrados (listener ignora os dois estados).

- [ ] **Step 3: Write minimal implementation**

Em `lib/features/auth/presentation/phone_screen.dart`, no `listener` do `BlocConsumer` (linhas 50-58), substituir por:

```dart
listener: (context, state) {
  if (state.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.errorMessage!)),
    );
  }
  // Android pode auto-verificar (SMS Retriever) antes mesmo do codeSent —
  // o login completa sem o usuário sair desta tela (C2 do review).
  if (state.userNeedingName != null) {
    context.go('/name');
  } else if (state.authenticatedUser != null) {
    context.go('/home');
  } else if (state.codeSentToPhone != null) {
    context.go('/otp');
  }
},
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/presentation/phone_screen_test.dart`
Expected: PASS completo (novos + existentes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/phone_screen.dart test/features/auth/presentation/phone_screen_test.dart
git commit -m "fix(auth): navigate from phone screen when Android auto-verification completes login"
```

---

### Task 4: Refresh single-flight (C3)

**Files:**
- Create: `lib/core/api/single_flight.dart`
- Test: `test/core/api/single_flight_test.dart`
- Modify: `lib/core/api/api_client.dart:66-82`

- [ ] **Step 1: Write the failing test**

Criar `test/core/api/single_flight_test.dart`:

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/api/single_flight.dart';

void main() {
  test('chamadas concorrentes compartilham a mesma execução', () async {
    final flight = SingleFlight<int>();
    var calls = 0;
    final completer = Completer<int>();

    Future<int> action() {
      calls++;
      return completer.future;
    }

    final f1 = flight.run(action);
    final f2 = flight.run(action);
    completer.complete(42);

    expect(await f1, 42);
    expect(await f2, 42);
    expect(calls, 1);
  });

  test('após conclusão, nova chamada executa de novo', () async {
    final flight = SingleFlight<int>();
    var calls = 0;
    Future<int> action() async => ++calls;

    await flight.run(action);
    await flight.run(action);

    expect(calls, 2);
  });

  test('falha não trava execuções futuras', () async {
    final flight = SingleFlight<int>();
    var calls = 0;
    Future<int> failing() async {
      calls++;
      throw StateError('boom');
    }

    await expectLater(flight.run(failing), throwsStateError);
    await expectLater(flight.run(failing), throwsStateError);
    expect(calls, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/api/single_flight_test.dart`
Expected: FAIL — package não resolve (arquivo não existe).

- [ ] **Step 3: Write minimal implementation**

Criar `lib/core/api/single_flight.dart`:

```dart
/// Garante uma única execução em voo por vez: chamadas concorrentes a [run]
/// recebem o mesmo Future da execução em andamento.
///
/// Usado pelo refresh de token do ApiClient: vários 401 simultâneos
/// (dashboard dispara 3 requests em paralelo) devem aguardar UM único
/// POST /auth/refresh — com rotação de refresh token no backend, refreshes
/// paralelos consomem o token uns dos outros e derrubam a sessão (C3).
///
/// Extraída como classe standalone para ser testável em isolamento,
/// seguindo o mesmo padrão de isRefreshRequestPath.
class SingleFlight<T> {
  Future<T>? _inFlight;

  Future<T> run(Future<T> Function() action) {
    return _inFlight ??= action().whenComplete(() => _inFlight = null);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/api/single_flight_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Usar no `ApiClient`**

Em `lib/core/api/api_client.dart`:

1. Adicionar import: `import 'single_flight.dart';`
2. Adicionar campo na classe: `final SingleFlight<bool> _refreshFlight = SingleFlight<bool>();`
3. Renomear o método `_tryRefresh` atual para `_doRefresh` e criar o wrapper:

```dart
Future<bool> _tryRefresh() => _refreshFlight.run(_doRefresh);

Future<bool> _doRefresh() async {
  final refreshToken = await tokenStorage.readRefreshToken();
  if (refreshToken == null) return false;
  try {
    final response = await dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {}),
    );
    final accessToken = response.data['accessToken'] as String;
    final newRefreshToken = response.data['refreshToken'] as String;
    await tokenStorage.saveTokens(accessToken: accessToken, refreshToken: newRefreshToken);
    return true;
  } catch (_) {
    return false;
  }
}
```

- [ ] **Step 6: Rodar testes do core**

Run: `flutter test test/core/`
Expected: PASS completo.

- [ ] **Step 7: Commit**

```bash
git add lib/core/api/ test/core/api/
git commit -m "fix(api): single-flight token refresh to survive concurrent 401s"
```

---

### Task 5: `ProfileRepository` — tirar `Dio` do `HomeBloc` e do router (A1/A2)

**Files:**
- Create: `lib/features/profile/domain/profile_repository.dart`
- Create: `lib/features/profile/data/profile_repository_impl.dart`
- Test: `test/features/profile/data/profile_repository_impl_test.dart`
- Modify: `lib/features/home/presentation/home_bloc.dart`, `lib/core/router/app_router.dart`, `lib/main.dart`, `lib/baber_app.dart`
- Modify: `test/features/home/presentation/home_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

Criar `test/features/profile/data/profile_repository_impl_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/profile/data/profile_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProfileRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = ProfileRepositoryImpl(dio);
  });

  test('getMe retorna AuthUser no sucesso', () async {
    when(() => dio.get('/me')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 200,
          data: {'id': 'u1', 'name': 'Gab', 'phone': '+5511999999999'},
        ));

    final result = await repository.getMe();

    expect(result, const Right(AuthUser(id: 'u1', name: 'Gab', phone: '+5511999999999')));
  });

  test('getMe retorna UnauthorizedFailure em 401', () async {
    when(() => dio.get('/me')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/me'),
      response: Response(requestOptions: RequestOptions(path: '/me'), statusCode: 401),
    ));

    final result = await repository.getMe();

    expect(result, const Left(UnauthorizedFailure()));
  });

  test('getMe retorna NetworkFailure sem resposta', () async {
    when(() => dio.get('/me')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/me'),
      message: 'timeout',
    ));

    final result = await repository.getMe();

    expect(result, const Left(NetworkFailure('timeout')));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/profile/data/profile_repository_impl_test.dart`
Expected: FAIL — package não resolve.

- [ ] **Step 3: Criar domain + data**

Criar `lib/features/profile/domain/profile_repository.dart`:

```dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import '../../auth/domain/auth_user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, AuthUser>> getMe();
}
```

Criar `lib/features/profile/data/profile_repository_impl.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../auth/domain/auth_user.dart';
import '../domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio _dio;
  const ProfileRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, AuthUser>> getMe() async {
    try {
      final response = await _dio.get('/me');
      return Right(AuthUser.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/profile/data/profile_repository_impl_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Refatorar `HomeBloc` para usar o repository**

Substituir `lib/features/home/presentation/home_bloc.dart` inteiro por:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/domain/appointment_repository.dart';
import '../../catalog/domain/service_repository.dart';
import '../../profile/domain/profile_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProfileRepository profileRepository;
  final AppointmentRepository appointmentRepository;
  final ServiceRepository serviceRepository;

  HomeBloc({
    required this.profileRepository,
    required this.appointmentRepository,
    required this.serviceRepository,
  }) : super(const HomeState()) {
    on<LoadHome>(_onLoad);
  }

  Future<void> _onLoad(LoadHome event, Emitter<HomeState> emit) async {
    emit(const HomeState(isLoading: true));

    final profileResult = await profileRepository.getMe();
    final unauthorized = profileResult.fold((f) => f is UnauthorizedFailure, (_) => false);
    if (unauthorized) {
      emit(const HomeState(sessionExpired: true));
      return;
    }
    // Falha não-auth (ex.: rede): segue sem nome em vez de travar o dashboard.
    final userName = profileResult.fold((_) => null, (user) => user.name);

    final appointmentsResult = await appointmentRepository.listMine();
    final servicesResult = await serviceRepository.listServices();

    final appointments = appointmentsResult.fold((_) => <Appointment>[], (a) => a);
    final now = DateTime.now();
    final upcoming = appointments
        .where((a) =>
            a.status != AppointmentStatus.cancelled &&
            a.status != AppointmentStatus.completed &&
            DateTime.parse('${a.date}T${a.startTime}:00').isAfter(now))
        .toList()
      ..sort((a, b) =>
          DateTime.parse('${a.date}T${a.startTime}:00').compareTo(DateTime.parse('${b.date}T${b.startTime}:00')));

    final next = upcoming.isEmpty ? null : upcoming.first;
    final serviceNames = servicesResult.fold(
      (_) => <String, String>{},
      (services) => {for (final s in services) s.id: s.name},
    );

    emit(HomeState(
      userName: userName,
      nextAppointment: next,
      nextAppointmentServiceName: next == null ? null : serviceNames[next.serviceId],
    ));
  }
}
```

- [ ] **Step 6: Atualizar `home_bloc_test.dart`**

Trocar `MockDio` (e stubs de `dio.get('/me')`) por:

```dart
class MockProfileRepository extends Mock implements ProfileRepository {}
```

Stubs correspondentes:

```dart
// sucesso com nome:
when(() => profileRepository.getMe())
    .thenAnswer((_) async => const Right(AuthUser(id: 'u1', name: 'Gab', phone: '+5511999999999')));

// sessão expirada:
when(() => profileRepository.getMe())
    .thenAnswer((_) async => const Left(UnauthorizedFailure()));

// falha de rede (dashboard segue sem nome):
when(() => profileRepository.getMe())
    .thenAnswer((_) async => const Left(NetworkFailure('timeout')));
```

Construção do bloc: `HomeBloc(profileRepository: profileRepository, appointmentRepository: ..., serviceRepository: ...)`.

Imports novos no teste: `package:baber_mobile/features/profile/domain/profile_repository.dart`, `package:baber_mobile/features/auth/domain/auth_user.dart`, `package:baber_mobile/core/error/failure.dart`, `package:dartz/dartz.dart`.

- [ ] **Step 7: Rewire `app_router.dart`, `main.dart`, `baber_app.dart`**

`lib/core/router/app_router.dart`:
1. Remover import de `package:dio/dio.dart`; adicionar:
   ```dart
   import 'package:dartz/dartz.dart';
   import '../error/failure.dart';
   import '../../features/auth/domain/auth_user.dart';
   import '../../features/profile/domain/profile_repository.dart';
   ```
2. Na assinatura de `buildAppRouter`, trocar `required Dio dio` por `required ProfileRepository profileRepository`.
3. Na rota `/home`, trocar `dio: dio` por `profileRepository: profileRepository` no construtor do `HomeBloc`.
4. Substituir a rota `/booking/confirm` por:

```dart
GoRoute(
  path: '/booking/confirm',
  builder: (context, state) => FutureBuilder<Either<Failure, AuthUser>>(
    future: profileRepository.getMe(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      // Best-effort prefill: qualquer falha (sessão, rede) cai em campos
      // vazios — o usuário ainda digita nome/telefone na mão, e sessão
      // realmente morta aparece quando BookingConfirmed falhar.
      return snapshot.data!.fold(
        (_) => const ConfirmBookingScreen(initialName: '', initialPhone: ''),
        (user) => ConfirmBookingScreen(initialName: user.name ?? '', initialPhone: user.phone),
      );
    },
  ),
),
```

`lib/baber_app.dart`: trocar o campo `final Dio dio;` por `final ProfileRepository profileRepository;` (import `features/profile/domain/profile_repository.dart`, remover import de dio), atualizar construtor e o repasse `profileRepository: profileRepository` em `buildAppRouter`.

`lib/main.dart`: após criar os outros repositórios, adicionar:

```dart
final profileRepository = ProfileRepositoryImpl(apiClient.dio);
```

(import `features/profile/data/profile_repository_impl.dart`), trocar `dio: apiClient.dio` por `profileRepository: profileRepository` no `BaberApp(...)`.

- [ ] **Step 8: Rodar suíte inteira**

Run: `flutter test`
Expected: PASS completo. Se `home_screen_test.dart` construir `HomeBloc` diretamente, aplicar a mesma troca de mock do Step 6.

- [ ] **Step 9: Commit**

```bash
git add lib/features/profile/ lib/features/home/ lib/core/router/ lib/main.dart lib/baber_app.dart test/
git commit -m "refactor(profile): add ProfileRepository, remove Dio from HomeBloc and router"
```

---

### Task 6: Redirect de sessão expirada em todas as abas (C4 parte 2)

**Files:**
- Modify: `lib/features/appointments/presentation/my_appointments_state.dart`, `my_appointments_bloc.dart`, `my_appointments_screen.dart`
- Modify: `lib/features/notifications/presentation/notifications_state.dart`, `notifications_bloc.dart`, `notifications_screen.dart`
- Modify: `lib/features/home/presentation/home_screen.dart:66-72`
- Test: `test/features/appointments/presentation/my_appointments_bloc_test.dart`, `test/features/notifications/presentation/notifications_bloc_test.dart`

- [ ] **Step 1: Write the failing tests**

Em `test/features/appointments/presentation/my_appointments_bloc_test.dart`, adicionar (import `package:baber_mobile/core/error/failure.dart` e `package:dartz/dartz.dart` se ausentes):

```dart
blocTest<MyAppointmentsBloc, MyAppointmentsState>(
  'emite sessionExpired quando listMine retorna UnauthorizedFailure',
  build: () {
    when(() => appointmentRepository.listMine())
        .thenAnswer((_) async => const Left(UnauthorizedFailure()));
    when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([]));
    return MyAppointmentsBloc(
      appointmentRepository: appointmentRepository,
      serviceRepository: serviceRepository,
    );
  },
  act: (bloc) => bloc.add(LoadMyAppointments()),
  expect: () => [
    const MyAppointmentsState.loading(),
    const MyAppointmentsState(sessionExpired: true),
  ],
);
```

Em `test/features/notifications/presentation/notifications_bloc_test.dart`:

```dart
blocTest<NotificationsBloc, NotificationsState>(
  'emite sessionExpired quando listMine retorna UnauthorizedFailure',
  build: () {
    when(() => repository.listMine())
        .thenAnswer((_) async => const Left(UnauthorizedFailure()));
    return NotificationsBloc(repository: repository);
  },
  act: (bloc) => bloc.add(LoadNotifications()),
  expect: () => [
    const NotificationsState.loading(),
    const NotificationsState(sessionExpired: true),
  ],
);
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/appointments/presentation/my_appointments_bloc_test.dart test/features/notifications/presentation/notifications_bloc_test.dart`
Expected: FAIL em compilação — `sessionExpired` não existe nos states.

- [ ] **Step 3: Adicionar `sessionExpired` aos states**

`lib/features/appointments/presentation/my_appointments_state.dart` — adicionar campo:

```dart
class MyAppointmentsState extends Equatable {
  final List<Appointment>? appointments;
  final Map<String, String> serviceNames;
  final String? errorMessage;
  final bool isLoading;
  final bool sessionExpired;

  const MyAppointmentsState({
    this.appointments,
    this.serviceNames = const {},
    this.errorMessage,
    this.isLoading = false,
    this.sessionExpired = false,
  });

  const MyAppointmentsState.initial() : this();
  const MyAppointmentsState.loading() : this(isLoading: true);
  const MyAppointmentsState.loaded({required List<Appointment> appointments, required Map<String, String> serviceNames})
      : this(appointments: appointments, serviceNames: serviceNames);
  const MyAppointmentsState.error(String message) : this(errorMessage: message);

  @override
  List<Object?> get props => [appointments, serviceNames, errorMessage, isLoading, sessionExpired];
}
```

`lib/features/notifications/presentation/notifications_state.dart` — mesmo padrão:

```dart
class NotificationsState extends Equatable {
  final List<NotificationItem>? items;
  final String? errorMessage;
  final bool isLoading;
  final bool sessionExpired;

  const NotificationsState({this.items, this.errorMessage, this.isLoading = false, this.sessionExpired = false});

  const NotificationsState.initial() : this();
  const NotificationsState.loading() : this(isLoading: true);
  const NotificationsState.loaded(List<NotificationItem> items) : this(items: items);
  const NotificationsState.error(String message) : this(errorMessage: message);

  @override
  List<Object?> get props => [items, errorMessage, isLoading, sessionExpired];
}
```

- [ ] **Step 4: Blocs detectam `UnauthorizedFailure`**

`lib/features/appointments/presentation/my_appointments_bloc.dart` — em `_onLoad`, substituir o bloco de fold do resultado de appointments (import `../../../core/error/failure.dart`):

```dart
Future<void> _onLoad(LoadMyAppointments event, Emitter<MyAppointmentsState> emit) async {
  emit(const MyAppointmentsState.loading());
  final appointmentsResult = await appointmentRepository.listMine();
  final servicesResult = await serviceRepository.listServices();

  final failure = appointmentsResult.fold<Failure?>((f) => f, (_) => null);
  if (failure is UnauthorizedFailure) {
    emit(const MyAppointmentsState(sessionExpired: true));
    return;
  }
  if (failure != null) {
    emit(MyAppointmentsState.error(failureMessage(failure)));
    return;
  }

  final appointments = appointmentsResult.fold((_) => <Appointment>[], (a) => a);
  final serviceNames = servicesResult.fold(
    (_) => <String, String>{},
    (services) => {for (final s in services) s.id: s.name},
  );

  emit(MyAppointmentsState.loaded(appointments: appointments, serviceNames: serviceNames));
}
```

`lib/features/notifications/presentation/notifications_bloc.dart` — em `_onLoad` (import `../../../core/error/failure.dart`):

```dart
Future<void> _onLoad(LoadNotifications event, Emitter<NotificationsState> emit) async {
  emit(const NotificationsState.loading());
  final result = await repository.listMine();
  result.fold(
    (failure) => failure is UnauthorizedFailure
        ? emit(const NotificationsState(sessionExpired: true))
        : emit(NotificationsState.error(failureMessage(failure))),
    (items) => emit(NotificationsState.loaded(items)),
  );
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/appointments/ test/features/notifications/`
Expected: PASS completo.

- [ ] **Step 6: Telas reagem com redirect para `/phone`**

`lib/features/appointments/presentation/my_appointments_screen.dart` — adicionar import `package:go_router/go_router.dart` e, no `listener` do `BlocConsumer`, adicionar antes do bloco de `errorMessage`:

```dart
if (state.sessionExpired) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
  );
  context.go('/phone');
  return;
}
```

`lib/features/notifications/presentation/notifications_screen.dart` — mesma mudança (mesmo import, mesmo bloco no listener).

`lib/features/home/presentation/home_screen.dart` — no listener (linhas 66-72), sessão expirada **não** apaga o tenant (o usuário volta pro login do mesmo salão; logout manual continua indo para `/tenant-selection`):

```dart
listener: (context, state) {
  if (state.sessionExpired) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
    );
    widget.tokenStorage.clear();
    context.go('/phone');
  }
},
```

- [ ] **Step 7: Rodar suíte inteira**

Run: `flutter test`
Expected: PASS. Se `home_screen_test.dart` cobrir o comportamento antigo (redirect para `/tenant-selection` em sessionExpired), atualizar a expectativa para `/phone`.

- [ ] **Step 8: Commit**

```bash
git add lib/features/appointments/ lib/features/notifications/ lib/features/home/ test/
git commit -m "fix(session): redirect to /phone on expired session from any tab"
```

---

### Task 7: Tela de slots com estado de erro real + slots antigos limpos (C5)

**Files:**
- Modify: `lib/features/booking/presentation/booking_bloc.dart:18-25`
- Modify: `lib/features/booking/presentation/slot_selection_screen.dart`
- Test: `test/features/booking/presentation/booking_bloc_test.dart`, `test/features/booking/presentation/slot_selection_screen_test.dart`

- [ ] **Step 1: Write the failing bloc test**

Em `test/features/booking/presentation/booking_bloc_test.dart`, adicionar (usa o `service` e `repository` já definidos no topo do arquivo):

```dart
blocTest<BookingBloc, BookingState>(
  'troca de data limpa slots antigos e falha expõe errorMessage sem slots velhos',
  build: () {
    when(() => repository.getAvailableSlots(serviceId: 's1', date: '2026-07-21'))
        .thenAnswer((_) async => const Left(NetworkFailure('sem rede')));
    return BookingBloc(repository: repository, service: service);
  },
  seed: () => const BookingState(
    service: service,
    selectedDate: '2026-07-20',
    slots: [TimeSlot(startTime: '09:00', endTime: '09:30')],
  ),
  act: (bloc) => bloc.add(const DateSelected('2026-07-21')),
  expect: () => [
    const BookingState(service: service, selectedDate: '2026-07-21', isLoading: true),
    const BookingState(service: service, selectedDate: '2026-07-21', errorMessage: 'sem rede'),
  ],
);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/booking/presentation/booking_bloc_test.dart`
Expected: FAIL — estados emitidos ainda carregam `slots: [slot1]` (copyWith preserva slots antigos).

- [ ] **Step 3: Corrigir `_onDateSelected`**

Em `lib/features/booking/presentation/booking_bloc.dart`, substituir `_onDateSelected`:

```dart
Future<void> _onDateSelected(DateSelected event, Emitter<BookingState> emit) async {
  // Estado fresco: trocar de data invalida slots e seleção anteriores —
  // manter slots velhos sob data nova induz agendamento errado (C5).
  emit(BookingState(service: state.service, selectedDate: event.date, isLoading: true));
  final result = await repository.getAvailableSlots(serviceId: state.service.id, date: event.date);
  result.fold(
    (failure) => emit(BookingState(
      service: state.service,
      selectedDate: event.date,
      errorMessage: failureMessage(failure),
    )),
    (slots) => emit(BookingState(service: state.service, selectedDate: event.date, slots: slots)),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/booking/presentation/booking_bloc_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing widget test**

Em `test/features/booking/presentation/slot_selection_screen_test.dart`, adicionar (usar o mock de bloc do próprio arquivo):

```dart
testWidgets('mostra erro com botão de tentar novamente quando errorMessage presente', (tester) async {
  whenListen(
    bloc,
    const Stream<BookingState>.empty(),
    initialState: BookingState(service: service, selectedDate: '2026-07-21', errorMessage: 'sem rede'),
  );

  await tester.pumpWidget(wrap(const SlotSelectionScreen()));

  expect(find.text('Não foi possível carregar os horários.'), findsOneWidget);
  expect(find.text('Nenhum horário disponível nesta data.'), findsNothing);

  await tester.tap(find.text('Tentar novamente'));

  verify(() => bloc.add(const DateSelected('2026-07-21'))).called(1);
});
```

(Se `setUpAll` do arquivo não registra fallback para `DateSelected`, adicionar `registerFallbackValue(const DateSelected(''));`.)

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/booking/presentation/slot_selection_screen_test.dart`
Expected: FAIL — tela mostra o empty state "Nenhum horário disponível nesta data." no lugar do erro.

- [ ] **Step 7: Adicionar UI de erro na tela**

Em `lib/features/booking/presentation/slot_selection_screen.dart`, no `builder`, adicionar entre o check de `isLoading` e o de lista vazia:

```dart
if (state.errorMessage != null) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Não foi possível carregar os horários.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            final date = state.selectedDate;
            if (date != null) {
              context.read<BookingBloc>().add(DateSelected(date));
            }
          },
          child: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 8: Rodar testes de booking**

Run: `flutter test test/features/booking/`
Expected: PASS completo.

- [ ] **Step 9: Commit**

```bash
git add lib/features/booking/presentation/ test/features/booking/presentation/
git commit -m "fix(booking): clear stale slots on date change and show retry UI on load failure"
```

---

### Task 8: Cancelamento com falha preserva a lista (C6)

**Files:**
- Modify: `lib/features/appointments/presentation/my_appointments_bloc.dart:43-52`
- Modify: `lib/features/appointments/presentation/my_appointments_screen.dart:127-129`
- Test: `test/features/appointments/presentation/my_appointments_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

Adicionar em `my_appointments_bloc_test.dart` (usa o `appointment` const já definido no topo do arquivo: `id: 'appt-1'`, `serviceId: 's1'`):

```dart
blocTest<MyAppointmentsBloc, MyAppointmentsState>(
  'falha no cancelamento preserva a lista carregada',
  build: () {
    when(() => appointmentRepository.cancel('appt-1'))
        .thenAnswer((_) async => const Left(ApiFailure(statusCode: 422, message: 'muito tarde para cancelar')));
    return MyAppointmentsBloc(
      appointmentRepository: appointmentRepository,
      serviceRepository: serviceRepository,
    );
  },
  seed: () => const MyAppointmentsState(
    appointments: [appointment],
    serviceNames: {'s1': 'Corte'},
  ),
  act: (bloc) => bloc.add(const CancelAppointmentRequested('appt-1')),
  expect: () => [
    const MyAppointmentsState(
      appointments: [appointment],
      serviceNames: {'s1': 'Corte'},
      isLoading: true,
    ),
    const MyAppointmentsState(
      appointments: [appointment],
      serviceNames: {'s1': 'Corte'},
      errorMessage: 'muito tarde para cancelar',
    ),
  ],
);
```

(Se `CancelAppointmentRequested` não for `const`-construtível no arquivo, verificar o construtor real em `my_appointments_event.dart` e ajustar o `const`.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/appointments/presentation/my_appointments_bloc_test.dart`
Expected: FAIL — bloc emite `loading()` e `error(...)` sem `appointments`.

- [ ] **Step 3: Corrigir `_onCancel`**

Em `my_appointments_bloc.dart`, substituir `_onCancel`:

```dart
Future<void> _onCancel(CancelAppointmentRequested event, Emitter<MyAppointmentsState> emit) async {
  // Loading e erro preservam a lista já carregada — cancelamento falho
  // não pode apagar os dados da tela (C6).
  emit(MyAppointmentsState(
    appointments: state.appointments,
    serviceNames: state.serviceNames,
    isLoading: true,
  ));
  final result = await appointmentRepository.cancel(event.appointmentId);
  final failure = result.fold<Failure?>((f) => f, (_) => null);
  if (failure is UnauthorizedFailure) {
    emit(const MyAppointmentsState(sessionExpired: true));
    return;
  }
  if (failure != null) {
    emit(MyAppointmentsState(
      appointments: state.appointments,
      serviceNames: state.serviceNames,
      errorMessage: failureMessage(failure),
    ));
    return;
  }
  add(LoadMyAppointments());
}
```

- [ ] **Step 4: Tela mostra spinner cheio só sem dados**

Em `my_appointments_screen.dart`, trocar o check de loading no `builder`:

```dart
// ANTES
if (state.isLoading) {
  return const Center(child: CircularProgressIndicator());
}
// DEPOIS — durante cancelamento a lista continua visível
if (state.isLoading && state.appointments == null) {
  return const Center(child: CircularProgressIndicator());
}
```

- [ ] **Step 5: Rodar testes de appointments**

Run: `flutter test test/features/appointments/`
Expected: PASS completo.

- [ ] **Step 6: Commit**

```bash
git add lib/features/appointments/presentation/ test/features/appointments/presentation/
git commit -m "fix(appointments): keep loaded list visible when cancellation fails"
```

---

### Task 9: Guard de HTTPS em release (S1)

**Files:**
- Create: `lib/core/config/base_url_guard.dart`
- Test: `test/core/config/base_url_guard_test.dart`
- Modify: `lib/main.dart:19-33`

- [ ] **Step 1: Write the failing test**

Criar `test/core/config/base_url_guard_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/config/base_url_guard.dart';

void main() {
  test('lança StateError para http em release', () {
    expect(
      () => assertSecureBaseUrl('http://localhost:3000', isRelease: true),
      throwsStateError,
    );
  });

  test('aceita https em release', () {
    expect(
      () => assertSecureBaseUrl('https://baber-api.fly.dev', isRelease: true),
      returnsNormally,
    );
  });

  test('aceita http em debug', () {
    expect(
      () => assertSecureBaseUrl('http://localhost:3000', isRelease: false),
      returnsNormally,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/config/base_url_guard_test.dart`
Expected: FAIL — package não resolve.

- [ ] **Step 3: Write minimal implementation**

Criar `lib/core/config/base_url_guard.dart`:

```dart
/// Falha no boot se a base URL da API não for HTTPS em build de release.
/// Um release sem --dart-define=API_BASE_URL compila apontando para
/// http://localhost:3000 e só falha no primeiro request com erro genérico
/// de rede (S1 do review) — melhor quebrar no boot com mensagem clara.
///
/// [isRelease] é parâmetro (em vez de ler kReleaseMode aqui) para a regra
/// ser testável — kReleaseMode é sempre false em flutter test.
void assertSecureBaseUrl(String baseUrl, {required bool isRelease}) {
  if (isRelease && !baseUrl.startsWith('https://')) {
    throw StateError('API_BASE_URL deve usar HTTPS em release: $baseUrl');
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/config/base_url_guard_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Chamar no `main()`**

Em `lib/main.dart`, adicionar imports:

```dart
import 'package:flutter/foundation.dart';
import 'core/config/base_url_guard.dart';
```

E logo após a declaração de `apiHost`:

```dart
const apiHost = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
assertSecureBaseUrl(apiHost, isRelease: kReleaseMode);
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/config/ test/core/config/ lib/main.dart
git commit -m "fix(config): fail fast at boot when release build has non-HTTPS API_BASE_URL"
```

---

### Task 10: Verificação final

- [ ] **Step 1: Análise estática**

Run: `flutter analyze`
Expected: `No issues found!` (ou apenas infos pré-existentes — nenhum warning/erro novo).

- [ ] **Step 2: Suíte completa**

Run: `flutter test`
Expected: PASS completo.

- [ ] **Step 3: Atualizar o review com nota de correção**

Em `docs/reviews/2026-07-12-review-mobile-flutter.md`, adicionar no topo da seção "Veredito final":

```markdown
> **Atualização:** bloqueadores C1, C2, C3, C4, S1 e follow-ups C5, C6, L1, A1/A2 corrigidos na branch `fix/mobile-review-findings`. Pendências: A3 (camada de models — decisão), A4/C7, C8, S2, S3 (remover debug TEMP), A5, L3.
```

- [ ] **Step 4: Commit final**

```bash
git add docs/reviews/2026-07-12-review-mobile-flutter.md
git commit -m "docs: mark mobile review blockers as fixed"
```

---

## Fora de escopo (explícito)

- **A3** (camada `data/models` com `.toEntity()`): decisão de arquitetura, não bug — tratar em plano próprio se decidido.
- **A4/C7** (lógica de upcoming na entity + `tryParse`): follow-up separado.
- **C8** (`state.extra as Service`): follow-up separado.
- **S2** (skipAuth no refresh), **S3** (remover debug TEMP — depende de resolver o bug de verificação no device), **A5** (logout via bloc), **L3** (identidade do app): follow-ups separados.

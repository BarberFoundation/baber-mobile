import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/auth/domain/auth_repository.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/auth/presentation/auth_bloc.dart';
import 'package:baber_mobile/features/auth/presentation/auth_event.dart';
import 'package:baber_mobile/features/auth/presentation/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRepository repository;
  late MockTokenStorage tokenStorage;

  const userNeedsName = AuthUser(id: 'u1', name: null, phone: '+5511999999999');
  const authResult = AuthResult(accessToken: 'a', refreshToken: 'r', user: userNeedsName);

  setUp(() {
    repository = MockAuthRepository();
    tokenStorage = MockTokenStorage();
    when(() => tokenStorage.saveTokens(accessToken: any(named: 'accessToken'), refreshToken: any(named: 'refreshToken')))
        .thenAnswer((_) async {});
  });

  blocTest<AuthBloc, AuthState>(
    'emits [loading, codeSent] when PhoneSubmitted triggers onCodeSent from the repository',
    build: () {
      when(() => repository.requestPhoneCode(
            phone: '+5511999999999',
            onCodeSent: any(named: 'onCodeSent'),
            onAutoVerified: any(named: 'onAutoVerified'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
          )).thenAnswer((invocation) async {
        final onCodeSent = invocation.namedArguments[#onCodeSent] as void Function(String);
        onCodeSent('ver-123');
      });
      return AuthBloc(repository: repository, tokenStorage: tokenStorage);
    },
    act: (bloc) => bloc.add(const PhoneSubmitted('+5511999999999')),
    expect: () => [
      const AuthState.loading(),
      const AuthState.codeSent(phone: '+5511999999999', verificationId: 'ver-123'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [loading, needsName] when PhoneSubmitted auto-verifies with a nameless user',
    build: () {
      when(() => repository.requestPhoneCode(
            phone: '+5511999999999',
            onCodeSent: any(named: 'onCodeSent'),
            onAutoVerified: any(named: 'onAutoVerified'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
          )).thenAnswer((invocation) async {
        final onAutoVerified =
            invocation.namedArguments[#onAutoVerified] as void Function(Either<Failure, AuthResult>);
        onAutoVerified(const Right(authResult));
      });
      return AuthBloc(repository: repository, tokenStorage: tokenStorage);
    },
    act: (bloc) => bloc.add(const PhoneSubmitted('+5511999999999')),
    expect: () => [
      const AuthState.loading(),
      const AuthState.needsName(userNeedsName),
    ],
    verify: (_) {
      verify(() => tokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r')).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits [loading, error] when PhoneSubmitted reports a verification failure',
    build: () {
      when(() => repository.requestPhoneCode(
            phone: '+5511999999999',
            onCodeSent: any(named: 'onCodeSent'),
            onAutoVerified: any(named: 'onAutoVerified'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
          )).thenAnswer((invocation) async {
        final onVerificationFailed = invocation.namedArguments[#onVerificationFailed] as void Function(Failure);
        onVerificationFailed(const FirebaseAuthFailure(code: 'invalid-phone-number', message: 'Número inválido.'));
      });
      return AuthBloc(repository: repository, tokenStorage: tokenStorage);
    },
    act: (bloc) => bloc.add(const PhoneSubmitted('+5511999999999')),
    expect: () => [
      const AuthState.loading(),
      const AuthState.error('Número inválido.'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [loading, needsName] when CodeSubmitted confirms the code with the stored verificationId',
    seed: () => const AuthState.codeSent(phone: '+5511999999999', verificationId: 'ver-123'),
    build: () {
      when(() => repository.confirmPhoneCode(verificationId: 'ver-123', smsCode: '123456'))
          .thenAnswer((_) async => const Right(authResult));
      return AuthBloc(repository: repository, tokenStorage: tokenStorage);
    },
    act: (bloc) => bloc.add(const CodeSubmitted(phone: '+5511999999999', code: '123456')),
    expect: () => [
      const AuthState.loading(),
      const AuthState.needsName(userNeedsName),
    ],
    verify: (_) {
      verify(() => tokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r')).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits [loading, error] with mapped message when CodeSubmitted fails',
    seed: () => const AuthState.codeSent(phone: '+5511999999999', verificationId: 'ver-123'),
    build: () {
      when(() => repository.confirmPhoneCode(verificationId: 'ver-123', smsCode: '000000')).thenAnswer(
        (_) async => const Left(FirebaseAuthFailure(code: 'invalid-verification-code', message: 'Código inválido.')),
      );
      return AuthBloc(repository: repository, tokenStorage: tokenStorage);
    },
    act: (bloc) => bloc.add(const CodeSubmitted(phone: '+5511999999999', code: '000000')),
    expect: () => [
      const AuthState.loading(),
      const AuthState.error('Código inválido.'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [authenticated] when NameSubmitted succeeds',
    build: () {
      const namedUser = AuthUser(id: 'u1', name: 'Gabryel', phone: '+5511999999999');
      when(() => repository.updateName('Gabryel')).thenAnswer((_) async => const Right(namedUser));
      return AuthBloc(repository: repository, tokenStorage: tokenStorage);
    },
    act: (bloc) => bloc.add(const NameSubmitted('Gabryel')),
    expect: () => [
      const AuthState.loading(),
      const AuthState.authenticated(AuthUser(id: 'u1', name: 'Gabryel', phone: '+5511999999999')),
    ],
  );
}

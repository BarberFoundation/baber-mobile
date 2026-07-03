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
    'emits [codeSent] when PhoneSubmitted succeeds',
    build: () {
      when(() => repository.requestOtp('+5511999999999')).thenAnswer((_) async => const Right(unit));
      return AuthBloc(repository: repository, tokenStorage: tokenStorage);
    },
    act: (bloc) => bloc.add(const PhoneSubmitted('+5511999999999')),
    expect: () => [
      const AuthState.loading(),
      const AuthState.codeSent('+5511999999999'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [needsName] when CodeSubmitted succeeds and user has no name',
    build: () {
      when(() => repository.verifyOtp(phone: '+5511999999999', code: '123456'))
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
    'emits [error] with mapped message when CodeSubmitted fails with ApiFailure',
    build: () {
      when(() => repository.verifyOtp(phone: '+5511999999999', code: '000000')).thenAnswer(
        (_) async => const Left(ApiFailure(statusCode: 400, message: 'invalid or expired code')),
      );
      return AuthBloc(repository: repository, tokenStorage: tokenStorage);
    },
    act: (bloc) => bloc.add(const CodeSubmitted(phone: '+5511999999999', code: '000000')),
    expect: () => [
      const AuthState.loading(),
      const AuthState.error('invalid or expired code'),
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

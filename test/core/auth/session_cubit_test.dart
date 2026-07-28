import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/session_cubit.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/auth/domain/auth_repository.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;
  late MockAuthRepository authRepository;

  setUp(() {
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    authRepository = MockAuthRepository();
    when(() => tokenStorage.clear()).thenAnswer((_) async {});
    when(() => tenantStorage.clear()).thenAnswer((_) async {});
    when(() => authRepository.signOut()).thenAnswer((_) async {});
  });

  blocTest<SessionCubit, SessionStatus>(
    'logout limpa tokens, tenant e sessão Firebase/Google, emite loggedOut',
    build: () => SessionCubit(
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
      authRepository: authRepository,
    ),
    act: (cubit) => cubit.logout(),
    expect: () => [SessionStatus.loggedOut],
    verify: (_) {
      verify(() => authRepository.signOut()).called(1);
      verify(() => tokenStorage.clear()).called(1);
      verify(() => tenantStorage.clear()).called(1);
    },
  );

  blocTest<SessionCubit, SessionStatus>(
    'expireTokens limpa só os tokens (tenant preservado), desloga Firebase/Google, emite expired',
    build: () => SessionCubit(
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
      authRepository: authRepository,
    ),
    act: (cubit) => cubit.expireTokens(),
    expect: () => [SessionStatus.expired],
    verify: (_) {
      verify(() => authRepository.signOut()).called(1);
      verify(() => tokenStorage.clear()).called(1);
      verifyNever(() => tenantStorage.clear());
    },
  );
}

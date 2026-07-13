import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/session_cubit.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;

  setUp(() {
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    when(() => tokenStorage.clear()).thenAnswer((_) async {});
    when(() => tenantStorage.clear()).thenAnswer((_) async {});
  });

  blocTest<SessionCubit, SessionStatus>(
    'logout limpa tokens e tenant e emite loggedOut',
    build: () => SessionCubit(tokenStorage: tokenStorage, tenantStorage: tenantStorage),
    act: (cubit) => cubit.logout(),
    expect: () => [SessionStatus.loggedOut],
    verify: (_) {
      verify(() => tokenStorage.clear()).called(1);
      verify(() => tenantStorage.clear()).called(1);
    },
  );

  blocTest<SessionCubit, SessionStatus>(
    'expireTokens limpa só os tokens (tenant preservado) e emite expired',
    build: () => SessionCubit(tokenStorage: tokenStorage, tenantStorage: tenantStorage),
    act: (cubit) => cubit.expireTokens(),
    expect: () => [SessionStatus.expired],
    verify: (_) {
      verify(() => tokenStorage.clear()).called(1);
      verifyNever(() => tenantStorage.clear());
    },
  );
}

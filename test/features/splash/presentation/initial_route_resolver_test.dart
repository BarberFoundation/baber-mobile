import 'package:app_links/app_links.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/splash/presentation/initial_route_resolver.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant_repository.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockTenantRepository extends Mock implements TenantRepository {}
class MockAppLinks extends Mock implements AppLinks {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;
  late MockTenantRepository tenantRepository;
  late MockAppLinks appLinks;
  late InitialRouteResolver resolver;

  setUp(() {
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    tenantRepository = MockTenantRepository();
    appLinks = MockAppLinks();
    resolver = InitialRouteResolver(
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
      tenantRepository: tenantRepository,
      appLinks: appLinks,
    );
  });

  test('tenant + token present -> /home', () async {
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => 't1');
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'access-token');

    expect(await resolver.resolve(), '/home');
  });

  test('tenant present, no token -> /phone', () async {
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => 't1');
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);

    expect(await resolver.resolve(), '/phone');
  });

  test('no tenant, deep link resolves -> saves tenant, /phone', () async {
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => null);
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    when(() => appLinks.getInitialLink())
        .thenAnswer((_) async => Uri.parse('baber://t/barbearia-do-amigo'));
    when(() => tenantRepository.findBySlug('barbearia-do-amigo')).thenAnswer(
      (_) async => const Right(Tenant(id: 't2', slug: 'barbearia-do-amigo', name: 'Barbearia do Amigo')),
    );
    when(() => tenantStorage.saveTenant(id: any(named: 'id'), slug: any(named: 'slug')))
        .thenAnswer((_) async {});

    expect(await resolver.resolve(), '/phone');
    verify(() => tenantStorage.saveTenant(id: 't2', slug: 'barbearia-do-amigo')).called(1);
  });

  test('no tenant, no deep link -> /tenant-selection', () async {
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => null);
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    when(() => appLinks.getInitialLink()).thenAnswer((_) async => null);

    expect(await resolver.resolve(), '/tenant-selection');
  });

  test('no tenant, deep link slug not found -> /tenant-selection', () async {
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => null);
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    when(() => appLinks.getInitialLink()).thenAnswer((_) async => Uri.parse('baber://t/unknown'));
    when(() => tenantRepository.findBySlug('unknown'))
        .thenAnswer((_) async => const Left(ApiFailure(statusCode: 404, message: 'not found')));

    expect(await resolver.resolve(), '/tenant-selection');
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/api/api_client.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockDio extends Mock implements Dio {}

void main() {
  late MockTokenStorage tokenStorage;
  late MockTenantStorage tenantStorage;
  late ApiClient client;

  setUp(() {
    tokenStorage = MockTokenStorage();
    tenantStorage = MockTenantStorage();
    client = ApiClient(
      baseUrl: 'https://baber-api.fly.dev/api/v1',
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
    );
  });

  test('dio instance has baseUrl configured', () {
    expect(client.dio.options.baseUrl, 'https://baber-api.fly.dev/api/v1');
  });

  test('request interceptor attaches Authorization header when access token present', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'abc');
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => 't1');

    final result = await client.buildAuthHeaders();

    expect(result['Authorization'], 'Bearer abc');
    expect(result['X-Tenant-Id'], 't1');
  });
}

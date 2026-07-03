import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage storage;
  late TenantStorage tenantStorage;

  setUp(() {
    storage = MockSecureStorage();
    tenantStorage = TenantStorage(storage);
  });

  test('saveTenant writes id and slug', () async {
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await tenantStorage.saveTenant(id: 't1', slug: 'barbearia-do-amigo');

    verify(() => storage.write(key: 'tenant_id', value: 't1')).called(1);
    verify(() => storage.write(key: 'tenant_slug', value: 'barbearia-do-amigo')).called(1);
  });

  test('readTenantId returns stored value', () async {
    when(() => storage.read(key: 'tenant_id')).thenAnswer((_) async => 't1');

    expect(await tenantStorage.readTenantId(), 't1');
  });
}

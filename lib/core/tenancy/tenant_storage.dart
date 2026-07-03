import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TenantStorage {
  final FlutterSecureStorage _storage;
  const TenantStorage(this._storage);

  static const _idKey = 'tenant_id';
  static const _slugKey = 'tenant_slug';

  Future<void> saveTenant({required String id, required String slug}) async {
    await _storage.write(key: _idKey, value: id);
    await _storage.write(key: _slugKey, value: slug);
  }

  Future<String?> readTenantId() => _storage.read(key: _idKey);
  Future<String?> readTenantSlug() => _storage.read(key: _slugKey);

  Future<void> clear() async {
    await _storage.delete(key: _idKey);
    await _storage.delete(key: _slugKey);
  }
}

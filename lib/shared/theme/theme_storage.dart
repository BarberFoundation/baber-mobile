import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeStorage {
  final FlutterSecureStorage _storage;
  const ThemeStorage(this._storage);

  static const _modeKey = 'theme_mode';

  Future<void> saveMode(String mode) => _storage.write(key: _modeKey, value: mode);
  Future<String?> readMode() => _storage.read(key: _modeKey);
}

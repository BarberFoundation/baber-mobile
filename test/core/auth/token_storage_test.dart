import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage storage;
  late TokenStorage tokenStorage;

  setUp(() {
    storage = MockSecureStorage();
    tokenStorage = TokenStorage(storage);
  });

  test('saveTokens writes access and refresh token', () async {
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await tokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r');

    verify(() => storage.write(key: 'access_token', value: 'a')).called(1);
    verify(() => storage.write(key: 'refresh_token', value: 'r')).called(1);
  });

  test('readAccessToken returns stored value', () async {
    when(() => storage.read(key: 'access_token')).thenAnswer((_) async => 'a');

    expect(await tokenStorage.readAccessToken(), 'a');
  });

  test('clear deletes both tokens', () async {
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await tokenStorage.clear();

    verify(() => storage.delete(key: 'access_token')).called(1);
    verify(() => storage.delete(key: 'refresh_token')).called(1);
  });
}

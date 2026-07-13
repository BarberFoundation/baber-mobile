import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/config/base_url_guard.dart';

void main() {
  test('lança StateError para http em release', () {
    expect(
      () => assertSecureBaseUrl('http://localhost:3000', isRelease: true),
      throwsStateError,
    );
  });

  test('aceita https em release', () {
    expect(
      () => assertSecureBaseUrl('https://baber-api.fly.dev', isRelease: true),
      returnsNormally,
    );
  });

  test('aceita http em debug', () {
    expect(
      () => assertSecureBaseUrl('http://localhost:3000', isRelease: false),
      returnsNormally,
    );
  });
}

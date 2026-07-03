import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/error/failure.dart';

void main() {
  group('Failure', () {
    test('two NetworkFailure with same message are equal', () {
      expect(NetworkFailure('timeout'), NetworkFailure('timeout'));
    });

    test('ApiFailure carries status code and message', () {
      final failure = ApiFailure(statusCode: 429, message: 'rate limited');
      expect(failure.statusCode, 429);
      expect(failure.message, 'rate limited');
    });

    test('different failure types are not equal even with same message', () {
      expect(NetworkFailure('x') == ApiFailure(statusCode: 0, message: 'x'), isFalse);
    });
  });
}

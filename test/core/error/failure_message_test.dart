import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/core/error/failure_message.dart';

void main() {
  group('failureMessage', () {
    test('returns the message for NetworkFailure', () {
      const failure = NetworkFailure('Sem conexão com a internet.');

      expect(failureMessage(failure), 'Sem conexão com a internet.');
    });

    test('returns the message for ApiFailure', () {
      const failure = ApiFailure(statusCode: 500, message: 'Erro no servidor.');

      expect(failureMessage(failure), 'Erro no servidor.');
    });

    test('returns a fixed message for UnauthorizedFailure', () {
      const failure = UnauthorizedFailure();

      expect(failureMessage(failure), 'Sessão expirada.');
    });
  });
}

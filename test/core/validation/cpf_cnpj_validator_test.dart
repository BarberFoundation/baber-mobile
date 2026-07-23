import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/validation/cpf_cnpj_validator.dart';

void main() {
  group('isValidCpf', () {
    test('accepts a checksum-valid CPF', () {
      expect(isValidCpf('111.444.777-35'), isTrue);
    });

    test('rejects a CPF with a bad check digit', () {
      expect(isValidCpf('111.444.777-36'), isFalse);
    });

    test('rejects all-same-digit CPFs (e.g. 111.111.111-11)', () {
      expect(isValidCpf('111.111.111-11'), isFalse);
    });

    test('rejects wrong length', () {
      expect(isValidCpf('123'), isFalse);
    });
  });

  group('isValidCnpj', () {
    test('accepts a checksum-valid CNPJ', () {
      expect(isValidCnpj('11.222.333/0001-81'), isTrue);
    });

    test('rejects a CNPJ with a bad check digit', () {
      expect(isValidCnpj('11.222.333/0001-82'), isFalse);
    });

    test('rejects all-same-digit CNPJs', () {
      expect(isValidCnpj('11.111.111/1111-11'), isFalse);
    });
  });

  group('isValidCpfCnpj', () {
    test('validates as CPF when 11 digits', () {
      expect(isValidCpfCnpj('111.444.777-35'), isTrue);
    });

    test('validates as CNPJ when 14 digits', () {
      expect(isValidCpfCnpj('11.222.333/0001-81'), isTrue);
    });

    test('rejects any other digit count', () {
      expect(isValidCpfCnpj('12345'), isFalse);
    });
  });
}

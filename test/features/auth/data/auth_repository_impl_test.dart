import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/core/firebase/firebase_auth_gateway.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';

class MockFirebaseAuthGateway extends Mock implements FirebaseAuthGateway {}
class MockDio extends Mock implements Dio {}
class MockTenantStorage extends Mock implements TenantStorage {}

void main() {
  late MockFirebaseAuthGateway gateway;
  late MockDio dio;
  late MockTenantStorage tenantStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    gateway = MockFirebaseAuthGateway();
    dio = MockDio();
    tenantStorage = MockTenantStorage();
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => 't1');
    repository = AuthRepositoryImpl(gateway, dio, tenantStorage);
  });

  group('requestPhoneCode', () {
    test('forwards the phone number to gateway.verifyPhoneNumber', () async {
      when(() => gateway.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            onCodeSent: any(named: 'onCodeSent'),
            onAutoVerified: any(named: 'onAutoVerified'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
          )).thenAnswer((_) async {});

      await repository.requestPhoneCode(
        phone: '+5511999999999',
        onCodeSent: (_) {},
        onAutoVerified: (_) {},
        onVerificationFailed: (_) {},
      );

      verify(() => gateway.verifyPhoneNumber(
            phoneNumber: '+5511999999999',
            onCodeSent: any(named: 'onCodeSent'),
            onAutoVerified: any(named: 'onAutoVerified'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
          )).called(1);
    });

    test('invokes onCodeSent with the verificationId reported by the gateway', () async {
      String? captured;
      when(() => gateway.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            onCodeSent: any(named: 'onCodeSent'),
            onAutoVerified: any(named: 'onAutoVerified'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
          )).thenAnswer((invocation) async {
        final onCodeSent = invocation.namedArguments[#onCodeSent] as void Function(String);
        onCodeSent('ver-123');
      });

      await repository.requestPhoneCode(
        phone: '+5511999999999',
        onCodeSent: (id) => captured = id,
        onAutoVerified: (_) {},
        onVerificationFailed: (_) {},
      );

      expect(captured, 'ver-123');
    });

    test('on auto-verification, exchanges the idToken and reports Right(AuthResult)', () async {
      final completer = Completer<Either<Failure, AuthResult>>();
      when(() => gateway.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            onCodeSent: any(named: 'onCodeSent'),
            onAutoVerified: any(named: 'onAutoVerified'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
          )).thenAnswer((invocation) async {
        final onAutoVerified = invocation.namedArguments[#onAutoVerified] as void Function(String);
        onAutoVerified('id-token-abc');
      });
      when(() => dio.post('/auth/client/exchange', data: {'idToken': 'id-token-abc', 'tenantId': 't1'}))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/auth/client/exchange'),
                statusCode: 200,
                data: {
                  'accessToken': 'a',
                  'refreshToken': 'r',
                  'user': {'id': 'u1', 'name': null, 'phone': '+5511999999999'},
                },
              ));

      await repository.requestPhoneCode(
        phone: '+5511999999999',
        onCodeSent: (_) {},
        onAutoVerified: completer.complete,
        onVerificationFailed: (_) {},
      );
      final captured = await completer.future;

      captured.fold((_) => fail('expected right'), (authResult) {
        expect(authResult.accessToken, 'a');
      });
    });

    test('maps a gateway verification failure to a FirebaseAuthFailure with a pt-BR message', () async {
      Failure? captured;
      when(() => gateway.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            onCodeSent: any(named: 'onCodeSent'),
            onAutoVerified: any(named: 'onAutoVerified'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
          )).thenAnswer((invocation) async {
        final onVerificationFailed =
            invocation.namedArguments[#onVerificationFailed] as void Function(String, String);
        onVerificationFailed('invalid-phone-number', 'raw firebase message');
      });

      await repository.requestPhoneCode(
        phone: '+5511999999999',
        onCodeSent: (_) {},
        onAutoVerified: (_) {},
        onVerificationFailed: (failure) => captured = failure,
      );

      expect(captured, isA<FirebaseAuthFailure>());
      expect((captured as FirebaseAuthFailure).message, 'Número de telefone inválido.');
    });
  });

  group('confirmPhoneCode', () {
    test('exchanges the confirmed idToken and returns Right(AuthResult)', () async {
      when(() => gateway.confirmCode(verificationId: 'ver-123', smsCode: '123456'))
          .thenAnswer((_) async => 'id-token-xyz');
      when(() => dio.post('/auth/client/exchange', data: {'idToken': 'id-token-xyz', 'tenantId': 't1'}))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/auth/client/exchange'),
                statusCode: 200,
                data: {
                  'accessToken': 'a',
                  'refreshToken': 'r',
                  'user': {'id': 'u1', 'name': null, 'phone': '+5511999999999'},
                },
              ));

      final result = await repository.confirmPhoneCode(verificationId: 'ver-123', smsCode: '123456');

      result.fold((_) => fail('expected right'), (authResult) {
        expect(authResult.accessToken, 'a');
        expect(authResult.user.needsName, isTrue);
      });
    });

    test('maps a 401 on exchange to UnauthorizedFailure', () async {
      when(() => gateway.confirmCode(verificationId: 'ver-123', smsCode: '000000'))
          .thenAnswer((_) async => 'id-token-xyz');
      when(() => dio.post('/auth/client/exchange', data: {'idToken': 'id-token-xyz', 'tenantId': 't1'}))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/client/exchange'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/client/exchange'),
          statusCode: 401,
          data: {'message': 'invalid token'},
        ),
      ));

      final result = await repository.confirmPhoneCode(verificationId: 'ver-123', smsCode: '000000');

      result.fold((failure) {
        expect(failure, const UnauthorizedFailure());
      }, (_) => fail('expected left'));
    });

    test('maps a FirebaseAuthException from gateway.confirmCode to FirebaseAuthFailure', () async {
      when(() => gateway.confirmCode(verificationId: 'ver-123', smsCode: 'wrong')).thenThrow(
        // ignore: invalid_use_of_protected_member
        FirebaseAuthException(code: 'invalid-verification-code'),
      );

      final result = await repository.confirmPhoneCode(verificationId: 'ver-123', smsCode: 'wrong');

      result.fold((failure) {
        expect(failure, isA<FirebaseAuthFailure>());
        expect((failure as FirebaseAuthFailure).message, 'Código de verificação inválido.');
      }, (_) => fail('expected left'));
    });
  });

  test('updateName patches /me and returns AuthUser', () async {
    when(() => dio.patch('/me', data: {'name': 'Gabryel'})).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 200,
          data: {'id': 'u1', 'name': 'Gabryel', 'phone': '+5511999999999'},
        ));

    final result = await repository.updateName('Gabryel');

    result.fold((_) => fail('expected right'), (user) {
      expect(user.name, 'Gabryel');
    });
  });
}

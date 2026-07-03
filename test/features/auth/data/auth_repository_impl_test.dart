import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/auth/data/auth_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AuthRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = AuthRepositoryImpl(dio);
  });

  test('requestOtp posts phone and returns Right on 200/204', () async {
    when(() => dio.post('/auth/otp/request', data: {'phone': '+5511999999999'}))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/auth/otp/request'),
              statusCode: 204,
            ));

    final result = await repository.requestOtp('+5511999999999');

    expect(result.isRight(), isTrue);
  });

  test('requestOtp maps 429 to ApiFailure', () async {
    when(() => dio.post('/auth/otp/request', data: {'phone': '+5511999999999'}))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: '/auth/otp/request'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/otp/request'),
        statusCode: 429,
        data: {'message': 'rate limited'},
      ),
    ));

    final result = await repository.requestOtp('+5511999999999');

    result.fold(
      (failure) {
        expect(failure, isA<ApiFailure>());
        expect((failure as ApiFailure).statusCode, 429);
      },
      (_) => fail('expected left'),
    );
  });

  test('verifyOtp returns AuthUser with tokens on success', () async {
    when(() => dio.post('/auth/otp/verify', data: {'phone': '+5511999999999', 'code': '123456'}))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/auth/otp/verify'),
              statusCode: 200,
              data: {
                'accessToken': 'a',
                'refreshToken': 'r',
                'user': {'id': 'u1', 'name': null, 'phone': '+5511999999999'},
              },
            ));

    final result = await repository.verifyOtp(phone: '+5511999999999', code: '123456');

    result.fold((_) => fail('expected right'), (authResult) {
      expect(authResult.accessToken, 'a');
      expect(authResult.refreshToken, 'r');
      expect(authResult.user.name, isNull);
      expect(authResult.user.needsName, isTrue);
    });
  });
}

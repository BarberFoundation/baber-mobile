import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/profile/data/profile_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProfileRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = ProfileRepositoryImpl(dio);
  });

  test('getMe retorna AuthUser no sucesso', () async {
    when(() => dio.get('/me')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 200,
          data: {'id': 'u1', 'name': 'Gab', 'phone': '+5511999999999'},
        ));

    final result = await repository.getMe();

    expect(result, const Right(AuthUser(id: 'u1', name: 'Gab', phone: '+5511999999999')));
  });

  test('getMe retorna UnauthorizedFailure em 401', () async {
    when(() => dio.get('/me')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/me'),
      response: Response(requestOptions: RequestOptions(path: '/me'), statusCode: 401),
    ));

    final result = await repository.getMe();

    expect(result, const Left(UnauthorizedFailure()));
  });

  test('getMe retorna NetworkFailure sem resposta', () async {
    when(() => dio.get('/me')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/me'),
      message: 'timeout',
    ));

    final result = await repository.getMe();

    expect(result, const Left(NetworkFailure('timeout')));
  });
}

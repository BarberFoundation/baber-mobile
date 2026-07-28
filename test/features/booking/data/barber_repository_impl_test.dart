import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/booking/data/barber_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late BarberRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = BarberRepositoryImpl(dio);
  });

  test('listBarbers returns Right with parsed barbers on 200', () async {
    when(() => dio.get('/barbers')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/barbers'),
          statusCode: 200,
          data: [
            {'id': 'b1', 'name': 'João'},
            {'id': 'b2', 'name': 'Marcos'},
          ],
        ));

    final result = await repository.listBarbers();

    result.fold((_) => fail('expected right'), (barbers) {
      expect(barbers, hasLength(2));
      expect(barbers[0].name, 'João');
    });
  });

  test('listBarbers maps DioException to ApiFailure', () async {
    when(() => dio.get('/barbers')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/barbers'),
      response: Response(
        requestOptions: RequestOptions(path: '/barbers'),
        statusCode: 500,
        data: {'message': 'erro interno'},
      ),
    ));

    final result = await repository.listBarbers();

    result.fold((failure) {
      expect(failure, isA<ApiFailure>());
      expect((failure as ApiFailure).statusCode, 500);
    }, (_) => fail('expected left'));
  });
}

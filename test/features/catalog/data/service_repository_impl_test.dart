import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/catalog/data/service_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ServiceRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = ServiceRepositoryImpl(dio);
  });

  test('listServices returns Right with parsed services on 200', () async {
    when(() => dio.get('/services')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/services'),
          statusCode: 200,
          data: [
            {'id': 's1', 'name': 'Corte', 'description': null, 'priceInCents': 4000, 'durationMinutes': 30},
          ],
        ));

    final result = await repository.listServices();

    result.fold((_) => fail('expected right'), (services) {
      expect(services, hasLength(1));
      expect(services[0].name, 'Corte');
      expect(services[0].formattedPrice, 'R\$ 40,00');
    });
  });

  test('listServices maps DioException to ApiFailure', () async {
    when(() => dio.get('/services')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/services'),
      response: Response(
        requestOptions: RequestOptions(path: '/services'),
        statusCode: 500,
        data: {'message': 'erro interno'},
      ),
    ));

    final result = await repository.listServices();

    result.fold((failure) {
      expect(failure, isA<ApiFailure>());
      expect((failure as ApiFailure).statusCode, 500);
    }, (_) => fail('expected left'));
  });
}

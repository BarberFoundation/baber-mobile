import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/notifications/data/notifications_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = NotificationsRepositoryImpl(dio);
  });

  test('listMine returns Right with parsed notifications on 200', () async {
    when(() => dio.get('/notifications/my')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/notifications/my'),
          statusCode: 200,
          data: [
            {
              'appointmentId': 'appt-1', 'type': 'CONFIRMATION', 'message': 'Confirmado!',
              'status': 'SENT', 'sentAt': '2026-01-01T10:00:00.000Z', 'createdAt': '2026-01-01T10:00:00.000Z',
            },
          ],
        ));

    final result = await repository.listMine();

    result.fold((_) => fail('expected right'), (items) {
      expect(items, hasLength(1));
      expect(items[0].message, 'Confirmado!');
    });
  });

  test('listMine maps DioException to ApiFailure', () async {
    when(() => dio.get('/notifications/my')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/notifications/my'),
      response: Response(
        requestOptions: RequestOptions(path: '/notifications/my'),
        statusCode: 500,
        data: {'message': 'erro interno'},
      ),
    ));

    final result = await repository.listMine();

    result.fold((failure) {
      expect(failure, isA<ApiFailure>());
    }, (_) => fail('expected left'));
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/appointments/data/appointment_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AppointmentRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = AppointmentRepositoryImpl(dio);
  });

  test('listMine returns Right with parsed appointments on 200', () async {
    when(() => dio.get('/appointments/my')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/appointments/my'),
          statusCode: 200,
          data: [
            {
              'id': 'appt-1', 'serviceId': 's1', 'date': '2026-08-01',
              'startTime': '09:00', 'endTime': '09:30', 'status': 'PENDING',
            },
          ],
        ));

    final result = await repository.listMine();

    result.fold((_) => fail('expected right'), (appointments) {
      expect(appointments, hasLength(1));
      expect(appointments[0].id, 'appt-1');
    });
  });

  test('cancel returns Right(null) on 204', () async {
    when(() => dio.patch('/appointments/appt-1/cancel')).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/appointments/appt-1/cancel'),
          statusCode: 204,
        ));

    final result = await repository.cancel('appt-1');

    expect(result.isRight(), isTrue);
  });

  test('cancel maps 403 to ApiFailure', () async {
    when(() => dio.patch('/appointments/appt-1/cancel')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/appointments/appt-1/cancel'),
      response: Response(
        requestOptions: RequestOptions(path: '/appointments/appt-1/cancel'),
        statusCode: 403,
        data: {'message': 'Você não pode cancelar este agendamento.'},
      ),
    ));

    final result = await repository.cancel('appt-1');

    result.fold((failure) {
      expect(failure, isA<ApiFailure>());
      expect((failure as ApiFailure).statusCode, 403);
    }, (_) => fail('expected left'));
  });
}

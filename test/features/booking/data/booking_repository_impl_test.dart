import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/booking/data/booking_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late BookingRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = BookingRepositoryImpl(dio);
  });

  test('getAvailableSlots returns Right with parsed slots on 200', () async {
    when(() => dio.get('/appointments/available-slots', queryParameters: {
          'serviceId': 's1',
          'date': '2026-08-01',
        })).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/appointments/available-slots'),
          statusCode: 200,
          data: [
            {'startTime': '09:00', 'endTime': '09:30'},
          ],
        ));

    final result = await repository.getAvailableSlots(serviceId: 's1', date: '2026-08-01');

    result.fold((_) => fail('expected right'), (slots) {
      expect(slots, hasLength(1));
      expect(slots[0].startTime, '09:00');
    });
  });

  test('getAvailableSlots includes barberId in query when given', () async {
    when(() => dio.get('/appointments/available-slots', queryParameters: {
          'serviceId': 's1',
          'date': '2026-08-01',
          'barberId': 'b1',
        })).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/appointments/available-slots'),
          statusCode: 200,
          data: const [],
        ));

    final result = await repository.getAvailableSlots(serviceId: 's1', date: '2026-08-01', barberId: 'b1');

    expect(result.isRight(), isTrue);
  });

  test('bookAppointment includes barberId in the body when given', () async {
    when(() => dio.post('/appointments', data: {
          'serviceId': 's1',
          'clientName': 'João',
          'clientPhone': '+5511999999999',
          'date': '2026-08-01',
          'startTime': '09:00',
          'barberId': 'b1',
        })).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/appointments'),
          statusCode: 201,
          data: {'id': 'appt-1'},
        ));

    final result = await repository.bookAppointment(
      serviceId: 's1',
      clientName: 'João',
      clientPhone: '+5511999999999',
      date: '2026-08-01',
      startTime: '09:00',
      barberId: 'b1',
    );

    expect(result.isRight(), isTrue);
  });

  test('bookAppointment posts without barberId and returns Right on 201', () async {
    when(() => dio.post('/appointments', data: {
          'serviceId': 's1',
          'clientName': 'João',
          'clientPhone': '+5511999999999',
          'date': '2026-08-01',
          'startTime': '09:00',
        })).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/appointments'),
          statusCode: 201,
          data: {'id': 'appt-1'},
        ));

    final result = await repository.bookAppointment(
      serviceId: 's1',
      clientName: 'João',
      clientPhone: '+5511999999999',
      date: '2026-08-01',
      startTime: '09:00',
    );

    expect(result.isRight(), isTrue);
  });

  test('bookAppointment maps 409 (no barber available) to ApiFailure', () async {
    when(() => dio.post('/appointments', data: any(named: 'data'))).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/appointments'),
      response: Response(
        requestOptions: RequestOptions(path: '/appointments'),
        statusCode: 409,
        data: {'message': 'Nenhum barbeiro disponível neste horário.'},
      ),
    ));

    final result = await repository.bookAppointment(
      serviceId: 's1',
      clientName: 'João',
      clientPhone: '+5511999999999',
      date: '2026-08-01',
      startTime: '09:00',
    );

    result.fold((failure) {
      expect(failure, isA<ApiFailure>());
      expect((failure as ApiFailure).statusCode, 409);
    }, (_) => fail('expected left'));
  });
}

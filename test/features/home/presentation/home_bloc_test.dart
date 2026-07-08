import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/appointments/domain/appointment.dart';
import 'package:baber_mobile/features/appointments/domain/appointment_repository.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/catalog/domain/service_repository.dart';
import 'package:baber_mobile/features/home/presentation/home_bloc.dart';
import 'package:baber_mobile/features/home/presentation/home_event.dart';
import 'package:baber_mobile/features/home/presentation/home_state.dart';

class MockDio extends Mock implements Dio {}
class MockAppointmentRepository extends Mock implements AppointmentRepository {}
class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late MockDio dio;
  late MockAppointmentRepository appointmentRepository;
  late MockServiceRepository serviceRepository;

  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);
  final future = Appointment(
    id: 'appt-1', serviceId: 's1', date: '2999-01-01',
    startTime: '09:00', endTime: '09:30', status: AppointmentStatus.confirmed,
  );
  final past = Appointment(
    id: 'appt-2', serviceId: 's1', date: '2000-01-01',
    startTime: '09:00', endTime: '09:30', status: AppointmentStatus.completed,
  );

  setUp(() {
    dio = MockDio();
    appointmentRepository = MockAppointmentRepository();
    serviceRepository = MockServiceRepository();
  });

  blocTest<HomeBloc, HomeState>(
    'loads profile name and the earliest upcoming appointment',
    build: () {
      when(() => dio.get('/me')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/me'),
            statusCode: 200,
            data: {'name': 'João', 'phone': '+55'},
          ));
      when(() => appointmentRepository.listMine()).thenAnswer((_) async => Right([past, future]));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      return HomeBloc(dio: dio, appointmentRepository: appointmentRepository, serviceRepository: serviceRepository);
    },
    act: (bloc) => bloc.add(LoadHome()),
    expect: () => [
      const HomeState(isLoading: true),
      HomeState(userName: 'João', nextAppointment: future, nextAppointmentServiceName: 'Corte'),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'nextAppointment is null when there are no upcoming appointments',
    build: () {
      when(() => dio.get('/me')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/me'),
            statusCode: 200,
            data: {'name': 'João', 'phone': '+55'},
          ));
      when(() => appointmentRepository.listMine()).thenAnswer((_) async => Right([past]));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      return HomeBloc(dio: dio, appointmentRepository: appointmentRepository, serviceRepository: serviceRepository);
    },
    act: (bloc) => bloc.add(LoadHome()),
    expect: () => [
      const HomeState(isLoading: true),
      const HomeState(userName: 'João'),
    ],
  );
}

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/appointments/domain/appointment.dart';
import 'package:baber_mobile/features/appointments/domain/appointment_repository.dart';
import 'package:baber_mobile/features/appointments/presentation/my_appointments_bloc.dart';
import 'package:baber_mobile/features/appointments/presentation/my_appointments_event.dart';
import 'package:baber_mobile/features/appointments/presentation/my_appointments_state.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/catalog/domain/service_repository.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}
class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late MockAppointmentRepository appointmentRepository;
  late MockServiceRepository serviceRepository;

  const appointment = Appointment(
    id: 'appt-1', serviceId: 's1', date: '2026-08-01',
    startTime: '09:00', endTime: '09:30', status: AppointmentStatus.pending,
  );
  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);

  setUp(() {
    appointmentRepository = MockAppointmentRepository();
    serviceRepository = MockServiceRepository();
  });

  blocTest<MyAppointmentsBloc, MyAppointmentsState>(
    'emits [loading, loaded] with a serviceId->name map on LoadMyAppointments',
    build: () {
      when(() => appointmentRepository.listMine()).thenAnswer((_) async => const Right([appointment]));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      return MyAppointmentsBloc(
        appointmentRepository: appointmentRepository,
        serviceRepository: serviceRepository,
      );
    },
    act: (bloc) => bloc.add(LoadMyAppointments()),
    expect: () => [
      const MyAppointmentsState.loading(),
      const MyAppointmentsState.loaded(
        appointments: [appointment],
        serviceNames: {'s1': 'Corte'},
      ),
    ],
  );

  blocTest<MyAppointmentsBloc, MyAppointmentsState>(
    'emits error when appointments fail to load',
    build: () {
      when(() => appointmentRepository.listMine())
          .thenAnswer((_) async => const Left(ApiFailure(statusCode: 500, message: 'erro interno')));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      return MyAppointmentsBloc(
        appointmentRepository: appointmentRepository,
        serviceRepository: serviceRepository,
      );
    },
    act: (bloc) => bloc.add(LoadMyAppointments()),
    expect: () => [
      const MyAppointmentsState.loading(),
      const MyAppointmentsState.error('erro interno'),
    ],
  );

  blocTest<MyAppointmentsBloc, MyAppointmentsState>(
    'emite sessionExpired quando listMine retorna UnauthorizedFailure',
    build: () {
      when(() => appointmentRepository.listMine())
          .thenAnswer((_) async => const Left(UnauthorizedFailure()));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([]));
      return MyAppointmentsBloc(
        appointmentRepository: appointmentRepository,
        serviceRepository: serviceRepository,
      );
    },
    act: (bloc) => bloc.add(LoadMyAppointments()),
    expect: () => [
      const MyAppointmentsState.loading(),
      const MyAppointmentsState(sessionExpired: true),
    ],
  );

  blocTest<MyAppointmentsBloc, MyAppointmentsState>(
    'falha no cancelamento preserva a lista carregada',
    build: () {
      when(() => appointmentRepository.cancel('appt-1'))
          .thenAnswer((_) async => const Left(ApiFailure(statusCode: 422, message: 'muito tarde para cancelar')));
      return MyAppointmentsBloc(
        appointmentRepository: appointmentRepository,
        serviceRepository: serviceRepository,
      );
    },
    seed: () => const MyAppointmentsState(
      appointments: [appointment],
      serviceNames: {'s1': 'Corte'},
    ),
    act: (bloc) => bloc.add(const CancelAppointmentRequested('appt-1')),
    expect: () => [
      const MyAppointmentsState(
        appointments: [appointment],
        serviceNames: {'s1': 'Corte'},
        isLoading: true,
      ),
      const MyAppointmentsState(
        appointments: [appointment],
        serviceNames: {'s1': 'Corte'},
        errorMessage: 'muito tarde para cancelar',
      ),
    ],
  );

  blocTest<MyAppointmentsBloc, MyAppointmentsState>(
    'CancelAppointmentRequested cancels then reloads the list',
    build: () {
      when(() => appointmentRepository.cancel('appt-1')).thenAnswer((_) async => const Right(null));
      when(() => appointmentRepository.listMine()).thenAnswer((_) async => const Right([]));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      return MyAppointmentsBloc(
        appointmentRepository: appointmentRepository,
        serviceRepository: serviceRepository,
      );
    },
    seed: () => const MyAppointmentsState.loaded(appointments: [appointment], serviceNames: {'s1': 'Corte'}),
    act: (bloc) => bloc.add(const CancelAppointmentRequested('appt-1')),
    expect: () => [
      // cancelamento mantém a lista visível enquanto carrega
      const MyAppointmentsState(appointments: [appointment], serviceNames: {'s1': 'Corte'}, isLoading: true),
      const MyAppointmentsState.loading(),
      const MyAppointmentsState.loaded(appointments: [], serviceNames: {'s1': 'Corte'}),
    ],
    verify: (_) {
      verify(() => appointmentRepository.cancel('appt-1')).called(1);
    },
  );
}

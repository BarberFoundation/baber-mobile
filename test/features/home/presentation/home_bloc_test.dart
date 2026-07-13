import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/appointments/domain/appointment.dart';
import 'package:baber_mobile/features/appointments/domain/appointment_repository.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/catalog/domain/service_repository.dart';
import 'package:baber_mobile/features/home/presentation/home_bloc.dart';
import 'package:baber_mobile/features/home/presentation/home_event.dart';
import 'package:baber_mobile/features/home/presentation/home_state.dart';
import 'package:baber_mobile/features/profile/domain/profile_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAppointmentRepository extends Mock implements AppointmentRepository {}
class MockServiceRepository extends Mock implements ServiceRepository {}

void main() {
  late MockProfileRepository profileRepository;
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

  HomeBloc buildBloc() => HomeBloc(
        profileRepository: profileRepository,
        appointmentRepository: appointmentRepository,
        serviceRepository: serviceRepository,
      );

  setUp(() {
    profileRepository = MockProfileRepository();
    appointmentRepository = MockAppointmentRepository();
    serviceRepository = MockServiceRepository();
  });

  blocTest<HomeBloc, HomeState>(
    'loads profile name and the earliest upcoming appointment',
    build: () {
      when(() => profileRepository.getMe())
          .thenAnswer((_) async => const Right(AuthUser(id: 'u1', name: 'João', phone: '+55')));
      when(() => appointmentRepository.listMine()).thenAnswer((_) async => Right([past, future]));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      return buildBloc();
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
      when(() => profileRepository.getMe())
          .thenAnswer((_) async => const Right(AuthUser(id: 'u1', name: 'João', phone: '+55')));
      when(() => appointmentRepository.listMine()).thenAnswer((_) async => Right([past]));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadHome()),
    expect: () => [
      const HomeState(isLoading: true),
      const HomeState(userName: 'João'),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'emits sessionExpired when the profile fetch is unauthorized',
    build: () {
      when(() => profileRepository.getMe()).thenAnswer((_) async => const Left(UnauthorizedFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadHome()),
    expect: () => [
      const HomeState(isLoading: true),
      const HomeState(sessionExpired: true),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'keeps loading the dashboard without a name on a non-auth profile failure',
    build: () {
      when(() => profileRepository.getMe()).thenAnswer((_) async => const Left(NetworkFailure('timeout')));
      when(() => appointmentRepository.listMine()).thenAnswer((_) async => Right([past]));
      when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right([service]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadHome()),
    expect: () => [
      const HomeState(isLoading: true),
      const HomeState(userName: null),
    ],
  );
}

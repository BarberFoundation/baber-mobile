import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/error/failure.dart';
import 'package:baber_mobile/features/booking/domain/booking_repository.dart';
import 'package:baber_mobile/features/booking/domain/time_slot.dart';
import 'package:baber_mobile/features/booking/presentation/booking_bloc.dart';
import 'package:baber_mobile/features/booking/presentation/booking_event.dart';
import 'package:baber_mobile/features/booking/presentation/booking_state.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  late MockBookingRepository repository;
  const service = Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30);

  setUp(() {
    repository = MockBookingRepository();
  });

  blocTest<BookingBloc, BookingState>(
    'DateSelected loads and emits available slots',
    build: () {
      when(() => repository.getAvailableSlots(serviceId: 's1', date: '2026-08-01'))
          .thenAnswer((_) async => const Right([TimeSlot(startTime: '09:00', endTime: '09:30')]));
      return BookingBloc(repository: repository, service: service);
    },
    act: (bloc) => bloc.add(const DateSelected('2026-08-01')),
    expect: () => [
      const BookingState(service: service, selectedDate: '2026-08-01', isLoading: true),
      const BookingState(
        service: service,
        selectedDate: '2026-08-01',
        slots: [TimeSlot(startTime: '09:00', endTime: '09:30')],
      ),
    ],
  );

  blocTest<BookingBloc, BookingState>(
    'troca de data limpa slots antigos e falha expõe errorMessage sem slots velhos',
    build: () {
      when(() => repository.getAvailableSlots(serviceId: 's1', date: '2026-07-21'))
          .thenAnswer((_) async => const Left(NetworkFailure('sem rede')));
      return BookingBloc(repository: repository, service: service);
    },
    seed: () => const BookingState(
      service: service,
      selectedDate: '2026-07-20',
      slots: [TimeSlot(startTime: '09:00', endTime: '09:30')],
    ),
    act: (bloc) => bloc.add(const DateSelected('2026-07-21')),
    expect: () => [
      const BookingState(service: service, selectedDate: '2026-07-21', isLoading: true),
      const BookingState(service: service, selectedDate: '2026-07-21', errorMessage: 'sem rede'),
    ],
  );

  blocTest<BookingBloc, BookingState>(
    'SlotSelected updates selectedSlot',
    build: () => BookingBloc(repository: repository, service: service),
    act: (bloc) => bloc.add(const SlotSelected(TimeSlot(startTime: '09:00', endTime: '09:30'))),
    expect: () => [
      const BookingState(service: service, selectedSlot: TimeSlot(startTime: '09:00', endTime: '09:30')),
    ],
  );

  blocTest<BookingBloc, BookingState>(
    'BookingConfirmed books the appointment and emits success',
    build: () {
      when(() => repository.bookAppointment(
            serviceId: 's1',
            clientName: 'João',
            clientPhone: '+5511999999999',
            date: '2026-08-01',
            startTime: '09:00',
          )).thenAnswer((_) async => const Right(null));
      return BookingBloc(repository: repository, service: service)
        ..emit(const BookingState(
          service: service,
          selectedDate: '2026-08-01',
          selectedSlot: TimeSlot(startTime: '09:00', endTime: '09:30'),
        ));
    },
    act: (bloc) => bloc.add(const BookingConfirmed(clientName: 'João', clientPhone: '+5511999999999')),
    expect: () => [
      const BookingState(
        service: service,
        selectedDate: '2026-08-01',
        selectedSlot: TimeSlot(startTime: '09:00', endTime: '09:30'),
        isLoading: true,
      ),
      const BookingState(
        service: service,
        selectedDate: '2026-08-01',
        selectedSlot: TimeSlot(startTime: '09:00', endTime: '09:30'),
        bookingSucceeded: true,
      ),
    ],
  );

  blocTest<BookingBloc, BookingState>(
    'BookingConfirmed emits error message on failure (e.g. no barber available)',
    build: () {
      when(() => repository.bookAppointment(
            serviceId: 's1',
            clientName: 'João',
            clientPhone: '+5511999999999',
            date: '2026-08-01',
            startTime: '09:00',
          )).thenAnswer((_) async => const Left(ApiFailure(statusCode: 409, message: 'Nenhum barbeiro disponível.')));
      return BookingBloc(repository: repository, service: service)
        ..emit(const BookingState(
          service: service,
          selectedDate: '2026-08-01',
          selectedSlot: TimeSlot(startTime: '09:00', endTime: '09:30'),
        ));
    },
    act: (bloc) => bloc.add(const BookingConfirmed(clientName: 'João', clientPhone: '+5511999999999')),
    expect: () => [
      const BookingState(
        service: service,
        selectedDate: '2026-08-01',
        selectedSlot: TimeSlot(startTime: '09:00', endTime: '09:30'),
        isLoading: true,
      ),
      const BookingState(
        service: service,
        selectedDate: '2026-08-01',
        selectedSlot: TimeSlot(startTime: '09:00', endTime: '09:30'),
        errorMessage: 'Nenhum barbeiro disponível.',
      ),
    ],
  );
}

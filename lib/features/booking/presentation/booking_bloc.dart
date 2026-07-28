import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure_message.dart';
import '../../catalog/domain/service.dart';
import '../domain/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository repository;

  BookingBloc({required this.repository, required Service service})
      : super(BookingState(service: service)) {
    on<BarberSelected>(_onBarberSelected);
    on<DateSelected>(_onDateSelected);
    on<SlotSelected>(_onSlotSelected);
    on<BookingConfirmed>(_onBookingConfirmed);
  }

  void _onBarberSelected(BarberSelected event, Emitter<BookingState> emit) {
    emit(BookingState(
      service: state.service,
      selectedBarber: event.barber,
      selectedDate: state.selectedDate,
      slots: state.slots,
      selectedSlot: state.selectedSlot,
    ));
  }

  Future<void> _onDateSelected(DateSelected event, Emitter<BookingState> emit) async {
    // Estado fresco: trocar de data invalida slots e seleção anteriores —
    // manter slots velhos sob data nova induz agendamento errado (C5).
    emit(BookingState(
      service: state.service,
      selectedBarber: state.selectedBarber,
      selectedDate: event.date,
      isLoading: true,
    ));
    final result = await repository.getAvailableSlots(
      serviceId: state.service.id,
      date: event.date,
      barberId: state.selectedBarber?.id,
    );
    result.fold(
      (failure) => emit(BookingState(
        service: state.service,
        selectedBarber: state.selectedBarber,
        selectedDate: event.date,
        errorMessage: failureMessage(failure),
      )),
      (slots) => emit(BookingState(
        service: state.service,
        selectedBarber: state.selectedBarber,
        selectedDate: event.date,
        slots: slots,
      )),
    );
  }

  void _onSlotSelected(SlotSelected event, Emitter<BookingState> emit) {
    emit(state.copyWith(selectedSlot: event.slot));
  }

  Future<void> _onBookingConfirmed(BookingConfirmed event, Emitter<BookingState> emit) async {
    final slot = state.selectedSlot;
    final date = state.selectedDate;
    if (slot == null || date == null) return;

    emit(state.copyWith(isLoading: true));
    final result = await repository.bookAppointment(
      serviceId: state.service.id,
      clientName: event.clientName,
      clientPhone: event.clientPhone,
      date: date,
      startTime: slot.startTime,
      barberId: state.selectedBarber?.id,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failureMessage(failure))),
      (_) => emit(state.copyWith(bookingSucceeded: true)),
    );
  }
}

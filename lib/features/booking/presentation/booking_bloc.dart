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
    on<DateSelected>(_onDateSelected);
    on<SlotSelected>(_onSlotSelected);
    on<BookingConfirmed>(_onBookingConfirmed);
  }

  Future<void> _onDateSelected(DateSelected event, Emitter<BookingState> emit) async {
    emit(state.copyWith(selectedDate: event.date, isLoading: true));
    final result = await repository.getAvailableSlots(serviceId: state.service.id, date: event.date);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failureMessage(failure))),
      (slots) => emit(state.copyWith(slots: slots)),
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
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failureMessage(failure))),
      (_) => emit(state.copyWith(bookingSucceeded: true)),
    );
  }
}

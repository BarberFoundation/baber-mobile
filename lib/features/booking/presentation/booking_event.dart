import 'package:equatable/equatable.dart';
import '../domain/time_slot.dart';

sealed class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class DateSelected extends BookingEvent {
  final String date;
  const DateSelected(this.date);
  @override
  List<Object?> get props => [date];
}

class SlotSelected extends BookingEvent {
  final TimeSlot slot;
  const SlotSelected(this.slot);
  @override
  List<Object?> get props => [slot];
}

class BookingConfirmed extends BookingEvent {
  final String clientName;
  final String clientPhone;
  const BookingConfirmed({required this.clientName, required this.clientPhone});
  @override
  List<Object?> get props => [clientName, clientPhone];
}

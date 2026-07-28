import 'package:equatable/equatable.dart';
import '../../catalog/domain/service.dart';
import '../domain/barber.dart';
import '../domain/time_slot.dart';

class BookingState extends Equatable {
  final Service service;
  final Barber? selectedBarber;
  final String? selectedDate;
  final List<TimeSlot>? slots;
  final TimeSlot? selectedSlot;
  final bool isLoading;
  final bool bookingSucceeded;
  final String? errorMessage;

  const BookingState({
    required this.service,
    this.selectedBarber,
    this.selectedDate,
    this.slots,
    this.selectedSlot,
    this.isLoading = false,
    this.bookingSucceeded = false,
    this.errorMessage,
  });

  BookingState copyWith({
    String? selectedDate,
    List<TimeSlot>? slots,
    TimeSlot? selectedSlot,
    bool? isLoading,
    bool? bookingSucceeded,
    String? errorMessage,
  }) {
    return BookingState(
      service: service,
      selectedBarber: selectedBarber,
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      isLoading: isLoading ?? false,
      bookingSucceeded: bookingSucceeded ?? false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        service,
        selectedBarber,
        selectedDate,
        slots,
        selectedSlot,
        isLoading,
        bookingSucceeded,
        errorMessage,
      ];
}

import 'package:equatable/equatable.dart';

sealed class MyAppointmentsEvent extends Equatable {
  const MyAppointmentsEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyAppointments extends MyAppointmentsEvent {}

class CancelAppointmentRequested extends MyAppointmentsEvent {
  final String appointmentId;
  const CancelAppointmentRequested(this.appointmentId);
  @override
  List<Object?> get props => [appointmentId];
}

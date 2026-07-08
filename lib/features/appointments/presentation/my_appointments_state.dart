import 'package:equatable/equatable.dart';
import '../domain/appointment.dart';

class MyAppointmentsState extends Equatable {
  final List<Appointment>? appointments;
  final Map<String, String> serviceNames;
  final String? errorMessage;
  final bool isLoading;

  const MyAppointmentsState({
    this.appointments,
    this.serviceNames = const {},
    this.errorMessage,
    this.isLoading = false,
  });

  const MyAppointmentsState.initial() : this();
  const MyAppointmentsState.loading() : this(isLoading: true);
  const MyAppointmentsState.loaded({required List<Appointment> appointments, required Map<String, String> serviceNames})
      : this(appointments: appointments, serviceNames: serviceNames);
  const MyAppointmentsState.error(String message) : this(errorMessage: message);

  @override
  List<Object?> get props => [appointments, serviceNames, errorMessage, isLoading];
}

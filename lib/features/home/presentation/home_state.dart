import 'package:equatable/equatable.dart';
import '../../appointments/domain/appointment.dart';

class HomeState extends Equatable {
  final String? userName;
  final Appointment? nextAppointment;
  final String? nextAppointmentServiceName;
  final bool isLoading;

  const HomeState({
    this.userName,
    this.nextAppointment,
    this.nextAppointmentServiceName,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [userName, nextAppointment, nextAppointmentServiceName, isLoading];
}

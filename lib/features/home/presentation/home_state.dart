import 'package:equatable/equatable.dart';
import '../../appointments/domain/appointment.dart';

class HomeState extends Equatable {
  final String? userName;
  final Appointment? nextAppointment;
  final String? nextAppointmentServiceName;
  final String? nextAppointmentBarberName;
  final bool isLoading;
  final bool sessionExpired;
  final bool hasActiveSubscription;
  final String? cheapestSubscriptionPriceLabel;

  const HomeState({
    this.userName,
    this.nextAppointment,
    this.nextAppointmentServiceName,
    this.nextAppointmentBarberName,
    this.isLoading = false,
    this.sessionExpired = false,
    this.hasActiveSubscription = false,
    this.cheapestSubscriptionPriceLabel,
  });

  @override
  List<Object?> get props => [
        userName,
        nextAppointment,
        nextAppointmentServiceName,
        nextAppointmentBarberName,
        isLoading,
        sessionExpired,
        hasActiveSubscription,
        cheapestSubscriptionPriceLabel,
      ];
}

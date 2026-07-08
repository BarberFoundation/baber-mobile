import 'package:equatable/equatable.dart';

enum AppointmentStatus { pending, confirmed, completed, cancelled }

AppointmentStatus appointmentStatusFromString(String value) {
  switch (value) {
    case 'PENDING':
      return AppointmentStatus.pending;
    case 'CONFIRMED':
      return AppointmentStatus.confirmed;
    case 'COMPLETED':
      return AppointmentStatus.completed;
    case 'CANCELLED':
      return AppointmentStatus.cancelled;
    default:
      throw ArgumentError('Unknown appointment status: $value');
  }
}

class Appointment extends Equatable {
  final String id;
  final String serviceId;
  final String date;
  final String startTime;
  final String endTime;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.serviceId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        serviceId: json['serviceId'] as String,
        date: json['date'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        status: appointmentStatusFromString(json['status'] as String),
      );

  bool get isCancellable {
    if (status != AppointmentStatus.pending && status != AppointmentStatus.confirmed) return false;
    final startsAt = DateTime.parse('${date}T$startTime:00');
    return startsAt.isAfter(DateTime.now());
  }

  @override
  List<Object?> get props => [id, serviceId, date, startTime, endTime, status];
}

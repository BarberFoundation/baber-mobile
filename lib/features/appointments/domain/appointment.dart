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

  /// Null quando date/startTime vierem malformados do backend — chamadores
  /// tratam como "não futuro" em vez de FormatException no build (C7).
  DateTime? get startDateTime => DateTime.tryParse('${date}T$startTime:00');

  bool get isUpcoming =>
      status != AppointmentStatus.cancelled &&
      status != AppointmentStatus.completed &&
      (startDateTime?.isAfter(DateTime.now()) ?? false);

  bool get isCancellable {
    if (status != AppointmentStatus.pending && status != AppointmentStatus.confirmed) return false;
    return startDateTime?.isAfter(DateTime.now()) ?? false;
  }

  @override
  List<Object?> get props => [id, serviceId, date, startTime, endTime, status];
}

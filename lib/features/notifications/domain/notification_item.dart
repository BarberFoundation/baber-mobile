import 'package:equatable/equatable.dart';

enum NotificationItemType { confirmation, cancellation, reminder }

NotificationItemType _typeFromString(String value) {
  switch (value) {
    case 'CONFIRMATION':
      return NotificationItemType.confirmation;
    case 'CANCELLATION':
      return NotificationItemType.cancellation;
    case 'REMINDER':
      return NotificationItemType.reminder;
    default:
      throw ArgumentError('Unknown notification type: $value');
  }
}

class NotificationItem extends Equatable {
  final String appointmentId;
  final NotificationItemType type;
  final String message;
  final String status;
  final DateTime? sentAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.appointmentId,
    required this.type,
    required this.message,
    required this.status,
    required this.sentAt,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        appointmentId: json['appointmentId'] as String,
        type: _typeFromString(json['type'] as String),
        message: json['message'] as String,
        status: json['status'] as String,
        sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [appointmentId, type, message, status, sentAt, createdAt];
}

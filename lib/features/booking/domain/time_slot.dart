import 'package:equatable/equatable.dart';

class TimeSlot extends Equatable {
  final String startTime;
  final String endTime;
  const TimeSlot({required this.startTime, required this.endTime});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
      );

  @override
  List<Object?> get props => [startTime, endTime];
}

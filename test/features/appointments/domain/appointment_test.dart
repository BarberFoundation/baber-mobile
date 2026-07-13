import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/features/appointments/domain/appointment.dart';

Appointment _appointment({
  String date = '2999-01-01',
  String startTime = '09:00',
  AppointmentStatus status = AppointmentStatus.confirmed,
}) {
  return Appointment(
    id: 'appt-1',
    serviceId: 's1',
    date: date,
    startTime: startTime,
    endTime: '09:30',
    status: status,
  );
}

void main() {
  group('startDateTime', () {
    test('parses date and startTime', () {
      expect(_appointment().startDateTime, DateTime(2999, 1, 1, 9));
    });

    test('returns null for malformed date instead of throwing', () {
      expect(_appointment(date: 'not-a-date').startDateTime, isNull);
      expect(_appointment(startTime: '9h').startDateTime, isNull);
    });
  });

  group('isUpcoming', () {
    test('true for active appointment in the future', () {
      expect(_appointment(status: AppointmentStatus.pending).isUpcoming, isTrue);
      expect(_appointment(status: AppointmentStatus.confirmed).isUpcoming, isTrue);
    });

    test('false for cancelled, completed or past appointments', () {
      expect(_appointment(status: AppointmentStatus.cancelled).isUpcoming, isFalse);
      expect(_appointment(status: AppointmentStatus.completed).isUpcoming, isFalse);
      expect(_appointment(date: '2000-01-01').isUpcoming, isFalse);
    });

    test('false (not a crash) when the date is malformed', () {
      expect(_appointment(date: 'not-a-date').isUpcoming, isFalse);
    });
  });

  group('isCancellable', () {
    test('true for pending/confirmed in the future', () {
      expect(_appointment(status: AppointmentStatus.pending).isCancellable, isTrue);
    });

    test('false when malformed date', () {
      expect(_appointment(date: 'not-a-date').isCancellable, isFalse);
    });
  });
}

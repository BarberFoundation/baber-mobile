import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/utils/appointment_date.dart';

void main() {
  test('formats an ISO date as "weekday, day month" in Portuguese', () {
    // 2026-07-31 is a Friday.
    expect(formatAppointmentDate('2026-07-31'), 'Sex, 31 jul');
  });

  test('formats a different month/weekday correctly', () {
    // 2026-01-01 is a Thursday.
    expect(formatAppointmentDate('2026-01-01'), 'Qui, 01 jan');
  });

  test('returns the raw string when the date cannot be parsed', () {
    expect(formatAppointmentDate('not-a-date'), 'not-a-date');
  });

  test('formats the full weekday name in Portuguese', () {
    // 2026-07-31 is a Friday.
    expect(formatWeekdayFull('2026-07-31'), 'Sexta');
    // 2026-01-01 is a Thursday.
    expect(formatWeekdayFull('2026-01-01'), 'Quinta');
  });

  test('formats the ticket-chip month abbreviation and day', () {
    expect(formatChipMonth('2026-07-31'), 'JUL');
    expect(formatChipDay('2026-07-31'), '31');
  });
}

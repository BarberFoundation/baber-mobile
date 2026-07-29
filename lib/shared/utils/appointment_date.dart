const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const _months = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

/// Formats a 'yyyy-MM-dd' appointment date as "Sex, 31 jul" (Portuguese,
/// matching the redesign spec). Falls back to the raw string if it can't
/// be parsed rather than throwing on malformed backend data.
String formatAppointmentDate(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return isoDate;

  final weekday = _weekdays[date.weekday - 1];
  final day = date.day.toString().padLeft(2, '0');
  final month = _months[date.month - 1];
  return '$weekday, $day $month';
}

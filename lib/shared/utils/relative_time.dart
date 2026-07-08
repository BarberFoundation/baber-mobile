String relativeTime(DateTime dateTime, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(dateTime);

  if (diff.inMinutes < 1) return 'agora';
  if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours}h';
  if (diff.inDays < 30) return 'há ${diff.inDays} dias';

  final d = dateTime.day.toString().padLeft(2, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  return '$d/$m/${dateTime.year}';
}

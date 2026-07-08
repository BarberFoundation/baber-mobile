import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/utils/relative_time.dart';

void main() {
  test('formats seconds/minutes as "agora"', () {
    final now = DateTime(2026, 1, 1, 12, 0, 0);
    expect(relativeTime(now.subtract(const Duration(seconds: 30)), now: now), 'agora');
  });

  test('formats hours as "há Xh"', () {
    final now = DateTime(2026, 1, 1, 12, 0, 0);
    expect(relativeTime(now.subtract(const Duration(hours: 2)), now: now), 'há 2h');
  });

  test('formats days as "há X dias"', () {
    final now = DateTime(2026, 1, 5, 12, 0, 0);
    expect(relativeTime(now.subtract(const Duration(days: 3)), now: now), 'há 3 dias');
  });

  test('formats more than 30 days as a date', () {
    final now = DateTime(2026, 2, 1, 12, 0, 0);
    final past = DateTime(2026, 1, 1, 12, 0, 0);
    expect(relativeTime(past, now: now), '01/01/2026');
  });
}

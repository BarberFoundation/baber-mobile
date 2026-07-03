import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/theme/app_theme.dart';

void main() {
  test('appTheme uses Material 3 with a dark amber-seeded color scheme', () {
    expect(appTheme.useMaterial3, isTrue);
    expect(appTheme.brightness, Brightness.dark);
    expect(appTheme.colorScheme.brightness, Brightness.dark);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/theme/app_colors.dart';
import 'package:baber_mobile/shared/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('appTheme uses Material 3 with a dark brass-accented barbershop color scheme', () {
    expect(appTheme.useMaterial3, isTrue);
    expect(appTheme.brightness, Brightness.dark);
    expect(appTheme.colorScheme.brightness, Brightness.dark);
    expect(appTheme.colorScheme.primary, AppColors.brass);
    expect(appTheme.scaffoldBackgroundColor, AppColors.ink);
  });
}

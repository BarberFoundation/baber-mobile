import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/theme/app_palette.dart';
import 'package:baber_mobile/shared/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppTheme.dark uses Material 3 with a dark brass-accented barbershop color scheme', () {
    expect(AppTheme.dark.useMaterial3, isTrue);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    expect(AppTheme.dark.colorScheme.primary, AppPalette.dark.brass);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppPalette.dark.background);
    expect(AppTheme.dark.extension<AppPalette>(), AppPalette.dark);
  });
}

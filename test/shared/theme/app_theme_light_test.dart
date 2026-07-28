import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/theme/app_palette.dart';
import 'package:baber_mobile/shared/theme/app_theme.dart';

// Split from app_theme_test.dart: building both AppTheme.dark and
// AppTheme.light in the same test file triggers two concurrent GoogleFonts
// resolutions, which is flaky under this repo's `allowRuntimeFetching =
// false` test config (see test/flutter_test_config.dart) — one theme build
// per file keeps it stable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppTheme.light uses Material 3 with a light brass-accented barbershop color scheme', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.light.colorScheme.brightness, Brightness.light);
    expect(AppTheme.light.colorScheme.primary, AppPalette.light.brass);
    expect(AppTheme.light.scaffoldBackgroundColor, AppPalette.light.background);
    expect(AppTheme.light.extension<AppPalette>(), AppPalette.light);
  });
}

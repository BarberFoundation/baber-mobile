import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';

/// Display face: condensed shopfront-lettering feel, used only for
/// headlines, prices and section titles — never body copy.
TextStyle _display({double size = 28, FontWeight weight = FontWeight.w400, required Color color, double? letterSpacing}) {
  return GoogleFonts.bebasNeue(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing ?? 0.5,
  );
}

TextTheme _textTheme(AppPalette palette, Color onBrass) {
  final body = GoogleFonts.karlaTextTheme();
  return body.copyWith(
    displayLarge: _display(size: 48, color: palette.textPrimary),
    displayMedium: _display(size: 36, color: palette.textPrimary),
    displaySmall: _display(size: 30, color: palette.textPrimary),
    headlineLarge: _display(size: 28, color: palette.textPrimary),
    headlineMedium: _display(size: 24, color: palette.textPrimary),
    headlineSmall: _display(size: 20, color: palette.textPrimary),
    titleLarge: GoogleFonts.karla(fontSize: 18, fontWeight: FontWeight.w700, color: palette.textPrimary),
    titleMedium: GoogleFonts.karla(fontSize: 16, fontWeight: FontWeight.w600, color: palette.textPrimary),
    titleSmall: GoogleFonts.karla(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
    bodyLarge: GoogleFonts.karla(fontSize: 16, color: palette.textPrimary),
    bodyMedium: GoogleFonts.karla(fontSize: 14, color: palette.textPrimary),
    bodySmall: GoogleFonts.karla(fontSize: 12, color: palette.textSecondary),
    labelLarge: GoogleFonts.karla(fontSize: 14, fontWeight: FontWeight.w600, color: onBrass),
    labelMedium: GoogleFonts.karla(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textSecondary),
    labelSmall: GoogleFonts.karla(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textSecondary),
  );
}

ThemeData _buildTheme(AppPalette palette, Brightness brightness) {
  final onBrass = brightness == Brightness.dark ? palette.background : Colors.white;
  final baseScheme = brightness == Brightness.dark
      ? ColorScheme.dark(
          surface: palette.background,
          primary: palette.brass,
          onPrimary: onBrass,
          secondary: palette.barberRed,
          onSecondary: palette.textPrimary,
          error: palette.barberRed,
          onSurface: palette.textPrimary,
          surfaceContainerHighest: palette.surfaceHigh,
        )
      : ColorScheme.light(
          surface: palette.background,
          primary: palette.brass,
          onPrimary: onBrass,
          secondary: palette.barberRed,
          onSecondary: Colors.white,
          error: palette.barberRed,
          onSurface: palette.textPrimary,
          surfaceContainerHighest: palette.surfaceHigh,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    colorScheme: baseScheme,
    extensions: [palette],
    textTheme: _textTheme(palette, onBrass),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: _display(size: 24, color: palette.textPrimary),
      iconTheme: IconThemeData(color: palette.brass),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.divider),
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.divider, thickness: 1, space: 32),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.brass,
        foregroundColor: onBrass,
        disabledBackgroundColor: palette.brassDim,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.karla(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.textPrimary,
        side: BorderSide(color: palette.divider),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: GoogleFonts.karla(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.brass,
        textStyle: GoogleFonts.karla(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      labelStyle: GoogleFonts.karla(color: palette.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: palette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: palette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: palette.brass, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.brass.withValues(alpha: 0.18),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.karla(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? palette.brass : palette.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? palette.brass : palette.textSecondary);
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.brass),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceHigh,
      contentTextStyle: GoogleFonts.karla(color: palette.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surfaceHigh,
      titleTextStyle: _display(size: 22, color: palette.textPrimary),
      contentTextStyle: GoogleFonts.karla(color: palette.textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

abstract final class AppTheme {
  static final dark = _buildTheme(AppPalette.dark, Brightness.dark);
  static final light = _buildTheme(AppPalette.light, Brightness.light);
}

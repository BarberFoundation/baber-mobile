import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Display face: condensed shopfront-lettering feel, used only for
/// headlines, prices and section titles — never body copy.
TextStyle _display({double size = 28, FontWeight weight = FontWeight.w400, Color? color, double? letterSpacing}) {
  return GoogleFonts.bebasNeue(
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.cream,
    letterSpacing: letterSpacing ?? 0.5,
  );
}

TextTheme _textTheme() {
  final body = GoogleFonts.karlaTextTheme();
  return body.copyWith(
    displayLarge: _display(size: 48),
    displayMedium: _display(size: 36),
    displaySmall: _display(size: 30),
    headlineLarge: _display(size: 28),
    headlineMedium: _display(size: 24),
    headlineSmall: _display(size: 20),
    titleLarge: GoogleFonts.karla(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.cream),
    titleMedium: GoogleFonts.karla(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.cream),
    titleSmall: GoogleFonts.karla(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.cream),
    bodyLarge: GoogleFonts.karla(fontSize: 16, color: AppColors.cream),
    bodyMedium: GoogleFonts.karla(fontSize: 14, color: AppColors.cream),
    bodySmall: GoogleFonts.karla(fontSize: 12, color: AppColors.steel),
    labelLarge: GoogleFonts.karla(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
    labelMedium: GoogleFonts.karla(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.steel),
    labelSmall: GoogleFonts.karla(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.steel),
  );
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.ink,
  colorScheme: const ColorScheme.dark(
    surface: AppColors.ink,
    primary: AppColors.brass,
    onPrimary: AppColors.ink,
    secondary: AppColors.barberRed,
    onSecondary: AppColors.cream,
    error: AppColors.barberRed,
    onSurface: AppColors.cream,
    surfaceContainerHighest: AppColors.surfaceHigh,
  ),
  textTheme: _textTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: _display(size: 24),
    iconTheme: const IconThemeData(color: AppColors.brass),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.divider),
    ),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 32),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.brass,
      foregroundColor: AppColors.ink,
      disabledBackgroundColor: AppColors.brassDim,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: GoogleFonts.karla(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.cream,
      side: const BorderSide(color: AppColors.divider),
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: GoogleFonts.karla(fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.brass,
      textStyle: GoogleFonts.karla(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    labelStyle: GoogleFonts.karla(color: AppColors.steel),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.brass, width: 1.5),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.brass.withValues(alpha: 0.18),
    elevation: 0,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return GoogleFonts.karla(
        fontSize: 11,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.brass : AppColors.steel,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(color: selected ? AppColors.brass : AppColors.steel);
    }),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.brass),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.surfaceHigh,
    contentTextStyle: GoogleFonts.karla(color: AppColors.cream),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surfaceHigh,
    titleTextStyle: _display(size: 22),
    contentTextStyle: GoogleFonts.karla(color: AppColors.cream, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
);

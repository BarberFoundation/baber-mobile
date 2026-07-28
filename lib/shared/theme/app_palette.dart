import 'package:flutter/material.dart';

/// Theme-extension counterpart to [AppColors] — carries the same barbershop
/// palette but as per-mode instances so screens can read colors that follow
/// dark/light instead of the old hardcoded statics. Migrate call sites over
/// screen by screen (redesign phases); once every screen reads from here,
/// [AppColors] can be deleted.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.brass,
    required this.brassLight,
    required this.brassDim,
    required this.barberRed,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.stripeMid,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color brass;
  final Color brassLight;
  final Color brassDim;
  final Color barberRed;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color stripeMid;

  static const dark = AppPalette(
    background: Color(0xFF14110D),
    surface: Color(0xFF1F1A13),
    surfaceHigh: Color(0xFF2B2317),
    brass: Color(0xFFC9A24B),
    brassLight: Color(0xFFE7C878),
    brassDim: Color(0xFF8A7238),
    barberRed: Color(0xFF9C3B33),
    textPrimary: Color(0xFFF1E7D6),
    textSecondary: Color(0xFF97897A),
    divider: Color(0xFF362C1E),
    stripeMid: Color(0xFFF1E7D6),
  );

  // No `surfaceHigh` value given by the light spec — defaults to `surface`
  // until a real elevated-card case shows up in a screen redesign phase.
  // `brassDim` repurposes the spec's light "brass dark accent (labels)"
  // value (#9c7530) — different semantic role than dark's disabled-button
  // tone, but closest analog for a secondary/muted brass in this palette.
  static const light = AppPalette(
    background: Color(0xFFF7F1E4),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFFFFFFF),
    brass: Color(0xFFB8863A),
    brassLight: Color(0xFFD4AA57),
    brassDim: Color(0xFF9C7530),
    barberRed: Color(0xFF9C3B33),
    textPrimary: Color(0xFF1F1A13),
    textSecondary: Color(0xFF8A7D68),
    divider: Color(0xFFE4D9C2),
    stripeMid: Color(0xFFFFFFFF),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? brass,
    Color? brassLight,
    Color? brassDim,
    Color? barberRed,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? stripeMid,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      brass: brass ?? this.brass,
      brassLight: brassLight ?? this.brassLight,
      brassDim: brassDim ?? this.brassDim,
      barberRed: barberRed ?? this.barberRed,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      stripeMid: stripeMid ?? this.stripeMid,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      brass: Color.lerp(brass, other.brass, t)!,
      brassLight: Color.lerp(brassLight, other.brassLight, t)!,
      brassDim: Color.lerp(brassDim, other.brassDim, t)!,
      barberRed: Color.lerp(barberRed, other.barberRed, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      stripeMid: Color.lerp(stripeMid, other.stripeMid, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/sr_palettes.dart';

/// The four colour themes a user can pick in Settings.
enum SrThemeId { jamdani, pathao, mustard, tea }

/// The active theme's palette. Every colour in the app comes from here.
@immutable
class SrColors extends ThemeExtension<SrColors> {
  const SrColors({
    required this.theme,
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.accent2,
    required this.tint,
    required this.deep,
    required this.onDeep,
    required this.onDeepMuted,
    required this.onAccent,
    required this.gold,
    required this.goldText,
    required this.goldTint,
    required this.onDeepGold,
    required this.success,
    required this.successTint,
    required this.warning,
    required this.warningTint,
    required this.danger,
    required this.dangerTint,
    required this.info,
    required this.infoTint,
    required this.avatarBg,
    required this.track,
    required this.skeleton,
    required this.skeletonGlow,
    required this.scrim,
    required this.cardShadow,
    required this.floatShadow,
    required this.sheetShadow,
  });

  final SrThemeId theme;
  final Brightness brightness;

  final Color canvas;
  final Color surface;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color lineStrong;

  final Color accent;
  final Color accent2;
  final Color tint;
  final Color deep;
  final Color onDeep;
  final Color onDeepMuted;
  final Color onAccent;

  final Color gold;
  final Color goldText;
  final Color goldTint;
  final Color onDeepGold;

  final Color success;
  final Color successTint;
  final Color warning;
  final Color warningTint;
  final Color danger;
  final Color dangerTint;
  final Color info;
  final Color infoTint;

  final Color avatarBg;
  final Color track;
  final Color skeleton;
  final Color skeletonGlow;
  final Color scrim;

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> floatShadow;
  final List<BoxShadow> sheetShadow;

  bool get isDark => brightness == Brightness.dark;

  static SrColors of(BuildContext context) =>
      Theme.of(context).extension<SrColors>() ??
      resolve(SrThemeId.jamdani, MediaQuery.platformBrightnessOf(context));

  static SrColors resolve(SrThemeId theme, Brightness brightness) {
    final light = brightness == Brightness.light;
    return switch (theme) {
      SrThemeId.jamdani => light ? jamdaniLight : jamdaniDark,
      SrThemeId.pathao => light ? pathaoLight : pathaoDark,
      SrThemeId.mustard => light ? mustardLight : mustardDark,
      SrThemeId.tea => light ? teaLight : teaDark,
    };
  }

  /// This theme's light palette, for documents such as PDFs.
  SrColors get paper => resolve(theme, Brightness.light);

  /// The prototype's `linear-gradient(160deg, accent, accent2)`.
  LinearGradient get primaryGradient => LinearGradient(
    colors: [accent, accent2],
    begin: const Alignment(-0.34, -0.94),
    end: const Alignment(0.34, 0.94),
  );

  @override
  SrColors copyWith() => this;

  @override
  SrColors lerp(ThemeExtension<SrColors>? other, double t) {
    if (other is! SrColors) return this;
    return t < 0.5 ? this : other;
  }
}

/// Corner radii and control heights from the prototype.
abstract final class SrMetrics {
  static const double radiusCard = 14;
  static const double radiusSmall = 10;
  static const double radiusButton = 12;
  static const double radiusSheet = 24;
  static const double radiusNav = 22;

  static const double buttonHeight = 50;
  static const double buttonHeightSmall = 40;
  static const double buttonHeightLarge = 56;
  static const double fieldHeight = 50;
  static const double rowMinHeight = 60;
  static const double iconButton = 40;

  static const double gutter = 20;
}

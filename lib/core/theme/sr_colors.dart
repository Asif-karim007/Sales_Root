import 'package:flutter/material.dart';

/// The Root skin. Every colour in the app comes from here.
@immutable
class SrColors extends ThemeExtension<SrColors> {
  const SrColors({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.accent,
    required this.accent2,
    required this.tint,
    required this.deep,
    required this.onDeep,
    required this.onDeepMuted,
    required this.onAccent,
    required this.gold,
    required this.goldTint,
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

  final Brightness brightness;

  final Color canvas;
  final Color surface;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;

  final Color accent;
  final Color accent2;
  final Color tint;
  final Color deep;
  final Color onDeep;
  final Color onDeepMuted;
  final Color onAccent;

  final Color gold;
  final Color goldTint;

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

  static const SrColors light = SrColors(
    brightness: Brightness.light,
    canvas: Color(0xFFF4F6F4),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF10231B),
    ink2: Color(0xFF5B6B63),
    ink3: Color(0xFF8A968F),
    line: Color(0xFFE2E8E4),
    accent: Color(0xFF0B5C3E),
    accent2: Color(0xFF158A5C),
    tint: Color(0xFFE6F1EB),
    deep: Color(0xFF0A3325),
    onDeep: Color(0xFFFFFFFF),
    onDeepMuted: Color(0xFFB9D4C6),
    onAccent: Color(0xFFFFFFFF),
    gold: Color(0xFFC9931E),
    goldTint: Color(0xFFFBF3E0),
    success: Color(0xFF0B5C3E),
    successTint: Color(0xFFE6F1EB),
    warning: Color(0xFFB7791F),
    warningTint: Color(0xFFFBF3E0),
    danger: Color(0xFFB42318),
    dangerTint: Color(0xFFFCEBE9),
    info: Color(0xFF1F4FBF),
    infoTint: Color(0xFFE8EEFB),
    avatarBg: Color(0xFFEEF2EF),
    track: Color(0xFFE9EEEA),
    skeleton: Color(0xFFE7EBE8),
    skeletonGlow: Color(0xFFF3F6F4),
    scrim: Color(0x8C000000),
    cardShadow: [
      BoxShadow(color: Color(0x0F10231B), blurRadius: 2, offset: Offset(0, 1)),
    ],
    floatShadow: [
      BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6)),
    ],
    sheetShadow: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 30,
        offset: Offset(0, -8),
      ),
    ],
  );

  static const SrColors dark = SrColors(
    brightness: Brightness.dark,
    canvas: Color(0xFF0B1511),
    surface: Color(0xFF13201A),
    ink: Color(0xFFE6EFEA),
    ink2: Color(0xFFA3B3AA),
    ink3: Color(0xFF74857B),
    line: Color(0xFF24332B),
    accent: Color(0xFF3FBF86),
    accent2: Color(0xFF2FA373),
    tint: Color(0xFF173226),
    deep: Color(0xFF06261A),
    onDeep: Color(0xFFFFFFFF),
    onDeepMuted: Color(0xFFA9C7B8),
    onAccent: Color(0xFF04140D),
    gold: Color(0xFFE0B04A),
    goldTint: Color(0xFF2E2614),
    success: Color(0xFF3FBF86),
    successTint: Color(0xFF173226),
    warning: Color(0xFFE3A646),
    warningTint: Color(0xFF33270F),
    danger: Color(0xFFF27A6B),
    dangerTint: Color(0xFF3A1C18),
    info: Color(0xFF7FA3F0),
    infoTint: Color(0xFF1A2440),
    avatarBg: Color(0xFF1B2A23),
    track: Color(0xFF22312A),
    skeleton: Color(0xFF1A2822),
    skeletonGlow: Color(0xFF22332B),
    scrim: Color(0xB3000000),
    cardShadow: [],
    floatShadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 6)),
    ],
    sheetShadow: [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 30,
        offset: Offset(0, -8),
      ),
    ],
  );

  static SrColors of(BuildContext context) =>
      Theme.of(context).extension<SrColors>() ??
      forBrightness(MediaQuery.platformBrightnessOf(context));

  static SrColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

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

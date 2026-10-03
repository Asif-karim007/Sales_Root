import 'package:flutter/material.dart';

/// The prototype's type scale. Anek Bangla covers both scripts, so the same
/// style serves Bangla and English.
abstract final class AppText {
  static const String family = 'AnekBangla';

  static TextStyle style({
    required double size,
    required FontWeight weight,
    Color? color,
    double? letterSpacing,
    double height = 1.3,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  /// Onboarding and success headlines.
  static TextStyle hero(Color color, {double size = 28}) => style(
    size: size,
    weight: FontWeight.w700,
    color: color,
    letterSpacing: -0.4,
    height: 1.15,
  );

  static TextStyle pageTitle(Color color, {double size = 18}) =>
      style(size: size, weight: FontWeight.w700, color: color, height: 1.2);

  static TextStyle sectionTitle(Color color, {double size = 15}) =>
      style(size: size, weight: FontWeight.w600, color: color);

  static TextStyle rowTitle(Color color, {double size = 14.5}) =>
      style(size: size, weight: FontWeight.w600, color: color, height: 1.3);

  static TextStyle body(Color color, {double size = 15}) =>
      style(size: size, weight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle lead(Color color, {double size = 14}) =>
      style(size: size, weight: FontWeight.w400, color: color, height: 1.45);

  static TextStyle meta(Color color, {double size = 12.5}) =>
      style(size: size, weight: FontWeight.w400, color: color, height: 1.35);

  static TextStyle label(Color color, {double size = 12}) => style(
    size: size,
    weight: FontWeight.w500,
    color: color,
    letterSpacing: 0.2,
  );

  static TextStyle fieldLabel(Color color, {double size = 12.5}) =>
      style(size: size, weight: FontWeight.w600, color: color);

  static TextStyle metric(Color color, {double size = 24}) => style(
    size: size,
    weight: FontWeight.w600,
    color: color,
    letterSpacing: -0.3,
    height: 1.1,
    tabular: true,
  );

  static TextStyle button(Color color, {double size = 15}) =>
      style(size: size, weight: FontWeight.w600, color: color, height: 1.2);

  static TextStyle input(Color color, {double size = 15}) =>
      style(size: size, weight: FontWeight.w400, color: color, height: 1.3);

  static TextStyle chip(Color color, {double size = 12}) =>
      style(size: size, weight: FontWeight.w600, color: color, height: 1.2);

  static TextStyle caption(Color color, {double size = 11.5}) =>
      style(size: size, weight: FontWeight.w600, color: color, height: 1.2);

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
    displayLarge: hero(ink, size: 32),
    displayMedium: hero(ink),
    displaySmall: hero(ink, size: 22),
    headlineMedium: pageTitle(ink, size: 20),
    headlineSmall: pageTitle(ink),
    titleLarge: sectionTitle(ink, size: 17),
    titleMedium: rowTitle(ink),
    titleSmall: rowTitle(muted, size: 13),
    bodyLarge: body(ink),
    bodyMedium: body(ink, size: 14),
    bodySmall: meta(muted),
    labelLarge: button(ink),
    labelMedium: label(muted),
    labelSmall: caption(muted),
  );
}

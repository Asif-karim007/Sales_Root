import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(SrColors.light);
  static ThemeData get dark => _build(SrColors.dark);

  static ThemeData _build(SrColors c) {
    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      extensions: <ThemeExtension<dynamic>>[c],
      fontFamily: AppText.family,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      primaryColor: c.accent,
      dividerColor: c.line,
      splashFactory: InkRipple.splashFactory,
      splashColor: c.accent.withValues(alpha: 0.08),
      highlightColor: c.accent.withValues(alpha: 0.05),
      colorScheme: ColorScheme(
        brightness: c.brightness,
        primary: c.accent,
        onPrimary: c.onAccent,
        secondary: c.gold,
        onSecondary: c.ink,
        error: c.danger,
        onError: c.onAccent,
        surface: c.surface,
        onSurface: c.ink,
        surfaceTint: Colors.transparent,
        outline: c.line,
      ),
      textTheme: AppText.textTheme(c.ink, c.ink2),
      iconTheme: IconThemeData(color: c.ink, size: 22),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.pageTitle(c.ink),
        systemOverlayStyle: overlayStyle(c.brightness),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.22),
        selectionHandleColor: c.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.track,
        circularTrackColor: c.track,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SrMetrics.radiusSheet),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final c = SrColors.forBrightness(brightness);
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: c.canvas,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }
}

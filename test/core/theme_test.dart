import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/theme/theme_provider.dart';

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

double _contrast(Color a, Color b) {
  final (light, dark) = a.computeLuminance() > b.computeLuminance()
      ? (a, b)
      : (b, a);
  return (light.computeLuminance() + 0.05) / (dark.computeLuminance() + 0.05);
}

void main() {
  test('the theme defaults to Jamdani Violet', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    expect(container.read(appThemeProvider), SrThemeId.jamdani);
  });

  test('a picked theme survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await _container();
    first.read(appThemeProvider.notifier).set(SrThemeId.mustard);

    final second = await _container();
    expect(second.read(appThemeProvider), SrThemeId.mustard);
  });

  test('an unknown stored theme falls back to the default', () async {
    SharedPreferences.setMockInitialValues({'theme': 'forest'});
    final container = await _container();
    expect(container.read(appThemeProvider), SrThemeId.jamdani);
  });

  for (final theme in SrThemeId.values) {
    for (final brightness in Brightness.values) {
      test('${theme.name} ${brightness.name}: body text is readable', () {
        final c = SrColors.resolve(theme, brightness);
        expect(c.theme, theme);
        expect(c.brightness, brightness);
        for (final ink in [c.ink, c.ink2]) {
          for (final ground in [c.canvas, c.surface]) {
            expect(_contrast(ink, ground), greaterThanOrEqualTo(4.5));
          }
        }
        expect(c.paper.brightness, Brightness.light);
      });
    }
  }
}

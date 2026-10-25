import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/theme/theme_provider.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

extension SrThemeLabels on SrThemeId {
  String label(AppLocalizations l10n) => switch (this) {
    SrThemeId.jamdani => l10n.settingsThemeJamdani,
    SrThemeId.pathao => l10n.settingsThemePathao,
    SrThemeId.mustard => l10n.settingsThemeMustard,
    SrThemeId.tea => l10n.settingsThemeTea,
  };
}

/// A theme's primary colour with a stripe of its accent along the bottom.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch(this.theme, {super.key, this.size = 38});

  final SrThemeId theme;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = SrColors.resolve(theme, SrColors.of(context).brightness);
    return ClipRRect(
      borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      child: SizedBox.square(
        dimension: size,
        child: Column(
          children: [
            Expanded(child: ColoredBox(color: colors.accent)),
            SizedBox(
              height: size / 4,
              width: size,
              child: ColoredBox(color: colors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lists the four themes; picking one applies it at once and closes.
class ThemeSheet extends ConsumerWidget {
  const ThemeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final current = ref.watch(appThemeProvider);
    return SrSheet(
      title: l10n.settingsTheme,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final theme in SrThemeId.values)
            SrListRow(
              title: theme.label(l10n),
              leading: ThemeSwatch(theme),
              trailing: theme == current
                  ? Icon(Icons.check_circle_rounded, color: c.accent)
                  : null,
              divider: theme != SrThemeId.values.last,
              onTap: () {
                ref.read(appThemeProvider.notifier).set(theme);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

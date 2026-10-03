import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/level_labels.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #86: app language, reading aloud and the experience level.
class LanguageLevelScreen extends ConsumerWidget {
  const LanguageLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(appLocaleProvider);
    final readAloud = ref.watch(devicePrefsProvider.select((p) => p.readAloud));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsLanguageLevelTitle,
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          SrRowGroup(
            title: l10n.settingsLanguage,
            rows: [
              _ChoiceRow(
                title: l10n.settingsLanguageBanglaNative,
                subtitle: l10n.settingsLanguageBanglaHint,
                selected: locale == bangla,
                onTap: () => ref.read(appLocaleProvider.notifier).set(bangla),
              ),
              _ChoiceRow(
                title: l10n.settingsLanguageEnglishNative,
                subtitle: l10n.settingsLanguageEnglishHint,
                selected: locale == english,
                onTap: () => ref.read(appLocaleProvider.notifier).set(english),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SrRowGroup(
            rows: [
              ToggleRow(
                title: l10n.settingsReadAloud,
                subtitle: l10n.settingsReadAloudHint,
                value: readAloud,
                onChanged: ref.read(devicePrefsProvider.notifier).setReadAloud,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _LevelGroup(),
        ],
      ),
    );
  }
}

class _LevelGroup extends ConsumerWidget {
  const _LevelGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(experienceLevelProvider);
    final locked = ref.watch(experienceLevelLockedProvider);
    final owner = ref.watch(
      currentWorkspaceProvider.select((w) => w?.ownerName),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrRowGroup(
          title: l10n.settingsLevel,
          rows: [
            for (final level in ExperienceLevel.values)
              _ChoiceRow(
                title: level.label(l10n),
                subtitle: level.description(l10n),
                selected: level == current,
                leading: RowIcon(
                  level.icon,
                  tone: level == current
                      ? SrAvatarTone.accent
                      : SrAvatarTone.neutral,
                ),
                onTap: locked
                    ? null
                    : () =>
                          ref.read(experienceLevelProvider.notifier).set(level),
              ),
          ],
        ),
        if (locked) ...[
          const SizedBox(height: 12),
          SrNote(
            tone: SrNoteTone.gold,
            icon: Icons.lock_outline_rounded,
            message: owner == null
                ? l10n.settingsLevelLocked
                : l10n.settingsLevelLockedBy(owner),
          ),
        ],
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Semantics(
      selected: selected,
      child: SrListRow(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: c.accent, size: 22)
            : null,
        onTap: onTap,
      ),
    );
  }
}

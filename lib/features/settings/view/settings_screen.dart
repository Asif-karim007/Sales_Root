import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/providers/sync_providers.dart';
import 'package:salesroot/features/settings/view/widget/level_labels.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/features/settings/view/widget/sign_out_sheet.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #85: personal, workspace and account settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsTitle,
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: screenPadding,
        children: const [
          _PersonalGroup(),
          SizedBox(height: 18),
          _WorkspaceGroup(),
          SizedBox(height: 18),
          _AccountGroup(),
        ],
      ),
    );
  }
}

class _PersonalGroup extends ConsumerWidget {
  const _PersonalGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isBangla = ref.watch(appLocaleProvider) == bangla;
    final level = ref.watch(experienceLevelProvider);
    final locked = ref.watch(experienceLevelLockedProvider);
    return SrRowGroup(
      title: l10n.settingsPersonal,
      rows: [
        SrListRow(
          title: l10n.settingsLanguage,
          subtitle: isBangla ? l10n.languageBangla : l10n.languageEnglish,
          leading: const RowIcon(Icons.translate_rounded),
          chevron: true,
          onTap: () => context.push(Routes.settingsLanguage),
        ),
        SrListRow(
          title: l10n.settingsLevel,
          subtitle: locked
              ? l10n.settingsLevelLockedShort(level.label(l10n))
              : level.label(l10n),
          leading: const RowIcon(Icons.tune_rounded),
          chevron: true,
          onTap: () => context.push(Routes.settingsLanguage),
        ),
        SrListRow(
          title: l10n.settingsNotifications,
          leading: const RowIcon(Icons.notifications_none_rounded),
          chevron: true,
          onTap: () => context.push(Routes.settingsNotifications),
        ),
        SrListRow(
          title: l10n.settingsSecurity,
          leading: const RowIcon(Icons.shield_outlined),
          chevron: true,
          onTap: () => context.push(Routes.settingsSecurity),
        ),
      ],
    );
  }
}

class _WorkspaceGroup extends ConsumerWidget {
  const _WorkspaceGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final workspace = ref.watch(currentWorkspaceProvider);
    final pipelines = ref.watch(moduleAccessProvider(AppModule.pipelines));
    final fields = ref.watch(moduleAccessProvider(AppModule.formFields));
    final import = ref.watch(moduleAccessProvider(AppModule.dataImport));
    final days = ref.watch(syncPrefsProvider.select((p) => p.historyDays));
    return SrRowGroup(
      title: workspace == null
          ? l10n.settingsWorkspace
          : l10n.settingsWorkspaceNamed(workspace.name),
      rows: [
        if (pipelines.visible)
          SrListRow(
            title: l10n.settingsPipelines,
            subtitle: pipelines.canEdit ? null : l10n.settingsViewOnly,
            leading: const RowIcon(Icons.view_kanban_outlined),
            chevron: true,
            onTap: () => context.push(Routes.settingsPipelines),
          ),
        if (fields.visible)
          SrListRow(
            title: l10n.settingsFormFields,
            subtitle: fields.canEdit ? null : l10n.settingsViewOnly,
            leading: const RowIcon(Icons.dynamic_form_outlined),
            chevron: true,
            onTap: () => context.push(Routes.settingsFormFields),
          ),
        if (import.visible && import.canAdd)
          SrListRow(
            title: l10n.settingsImport,
            leading: const RowIcon(Icons.upload_file_outlined),
            chevron: true,
            onTap: () => context.push(Routes.settingsImport),
          ),
        SrListRow(
          title: l10n.settingsSync,
          subtitle: l10n.settingsSyncDays(context.fmt.number(days)),
          leading: const RowIcon(Icons.sync_rounded),
          chevron: true,
          onTap: () => context.push(Routes.sync),
        ),
      ],
    );
  }
}

class _AccountGroup extends ConsumerWidget {
  const _AccountGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrRowGroup(
      title: l10n.settingsAccount,
      rows: [
        SrListRow(
          title: l10n.settingsSignOut,
          leading: const RowIcon(Icons.logout_rounded),
          onTap: () => showSrSheet<void>(
            context: context,
            builder: (_) => const SignOutSheet(),
          ),
        ),
        SrListRow(
          title: l10n.settingsDeleteAccount,
          subtitle: l10n.settingsDeleteAccountHint,
          leading: const RowIcon(
            Icons.delete_outline_rounded,
            tone: SrAvatarTone.danger,
          ),
          onTap: () => _delete(context, ref),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSrSheet<bool>(
      context: context,
      builder: (sheet) => SrConfirmSheet(
        title: l10n.settingsDeleteTitle,
        message: l10n.settingsDeleteBody,
        icon: Icons.delete_outline_rounded,
        tone: SrTone.err,
        destructive: true,
        bullets: [
          SrSheetBullet(
            icon: Icons.schedule_rounded,
            text: l10n.settingsDeleteGrace,
          ),
          SrSheetBullet(
            icon: Icons.login_rounded,
            text: l10n.settingsDeleteUndo,
          ),
        ],
        primaryLabel: l10n.settingsDeleteConfirm,
        onPrimary: () => Navigator.of(sheet).pop(true),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final session = ref.read(sessionProvider.notifier);
    try {
      await showSrLoader(
        context,
        ref.read(settingsRepositoryProvider).requestAccountDeletion(),
      );
      if (!context.mounted) return;
      showSrSuccess(context, l10n.settingsDeleteDone);
      await session.signOut();
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showSrError(context, failure.message);
    }
  }
}

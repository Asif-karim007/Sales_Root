import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Debug-only switches for every state a screen has to handle.
class DevMenuScreen extends ConsumerWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dev = ref.watch(devSettingsProvider);
    final notifier = ref.read(devSettingsProvider.notifier);
    return SrScaffold(
      appBar: SrAppBar(title: l10n.devTitle, subtitle: l10n.devSubtitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          SrRowGroup(
            title: l10n.devSectionNetwork,
            rows: [
              _toggle(
                l10n.devLatency,
                dev.latency,
                (v) => notifier.update((s) => s.copyWith(latency: v)),
              ),
              _toggle(
                l10n.devOffline,
                dev.offline,
                (v) => notifier.update((s) => s.copyWith(offline: v)),
              ),
              _toggle(
                l10n.devInjectErrors,
                dev.injectErrors,
                (v) => notifier.update((s) => s.copyWith(injectErrors: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AccountGroup(),
          const SizedBox(height: 16),
          SrRowGroup(
            title: l10n.devSectionData,
            rows: [
              _toggle(
                l10n.devEmptyWorkspace,
                dev.emptyWorkspace,
                (v) => notifier.update((s) => s.copyWith(emptyWorkspace: v)),
              ),
              SrListRow(
                title: l10n.devReseed,
                leading: const Icon(Icons.restart_alt_rounded),
                onTap: () {
                  notifier.reseed();
                  showSrSuccess(context, l10n.devReseedDone);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SrRowGroup(
            title: l10n.devSectionTools,
            rows: [
              SrListRow(
                title: l10n.devLanguage,
                trailing: SrLanguageToggle(
                  isBangla: ref.watch(appLocaleProvider) == bangla,
                  onChanged: (isBangla) => ref
                      .read(appLocaleProvider.notifier)
                      .set(isBangla ? bangla : english),
                ),
              ),
              SrListRow(
                title: l10n.devGallery,
                leading: const Icon(Icons.palette_outlined),
                chevron: true,
                onTap: () => context.push(Routes.devGallery),
              ),
              SrListRow(
                title: l10n.devLockPin,
                leading: const Icon(Icons.lock_outline_rounded),
                onTap: () => ref.read(pinLockProvider.notifier).lock(),
              ),
              SrListRow(
                title: l10n.devSignOut,
                leading: const Icon(Icons.logout_rounded),
                onTap: () => ref.read(sessionProvider.notifier).signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) =>
      SrListRow(
        title: title,
        trailing: SrSwitch(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
      );
}

class _AccountGroup extends ConsumerWidget {
  const _AccountGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dev = ref.watch(devSettingsProvider);
    final notifier = ref.read(devSettingsProvider.notifier);
    final workspaces =
        ref.watch(workspacesProvider).value ?? const <Workspace>[];
    final current = ref.watch(currentWorkspaceProvider);
    final level = ref.watch(experienceLevelProvider);
    final roles = <WorkspaceRole?>[null, ...WorkspaceRole.values];
    final addOnChoices = <Set<AddOn>?>[
      null,
      const {},
      const {AddOn.fieldForce},
      const {AddOn.growth},
      const {AddOn.fieldForce, AddOn.growth},
    ];
    return SrRowGroup(
      title: l10n.devSectionAccount,
      rows: [
        if (workspaces.isNotEmpty)
          _Choice(
            title: l10n.devWorkspace,
            labels: [for (final w in workspaces) w.name],
            index: workspaces.indexWhere((w) => w.id == current?.id),
            onChanged: (i) => ref
                .read(currentWorkspaceProvider.notifier)
                .select(workspaces[i]),
          ),
        _Choice(
          title: l10n.devRole,
          labels: [
            l10n.devRoleAuto,
            l10n.devRoleOwner,
            l10n.devRoleTeamLead,
            l10n.devRoleMember,
          ],
          index: roles.indexOf(dev.role),
          onChanged: (i) =>
              notifier.update((s) => s.copyWith(role: () => roles[i])),
        ),
        _Choice(
          title: l10n.devAddOns,
          labels: [
            l10n.devAddOnsAuto,
            l10n.devAddOnsNone,
            l10n.devAddOnFieldForce,
            l10n.devAddOnGrowth,
            l10n.devAddOnsBoth,
          ],
          index: addOnChoices.indexWhere(
            (choice) =>
                choice?.length == dev.addOns?.length &&
                (choice?.containsAll(dev.addOns ?? const {}) ??
                    dev.addOns == null),
          ),
          onChanged: (i) =>
              notifier.update((s) => s.copyWith(addOns: () => addOnChoices[i])),
        ),
        _Choice(
          title: l10n.devLevel,
          labels: [
            l10n.devLevelEasy,
            l10n.devLevelStandard,
            l10n.devLevelAdvanced,
          ],
          index: level.index,
          onChanged: (i) => ref
              .read(experienceLevelProvider.notifier)
              .set(ExperienceLevel.values[i]),
        ),
        SrListRow(
          title: l10n.devLockLevel,
          trailing: SrSwitch(
            value: dev.lockLevel,
            onChanged: (v) => notifier.update((s) => s.copyWith(lockLevel: v)),
          ),
        ),
        SrListRow(
          title: l10n.devQuotaReached,
          trailing: SrSwitch(
            value: dev.quotaReached,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(quotaReached: v)),
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final String title;
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SrListRow(
      title: title,
      subtitle: index >= 0 ? labels[index] : null,
      chevron: true,
      onTap: () async {
        final picked = await showSrSheet<int>(
          context: context,
          builder: (_) => SrOptionSheet<int>(
            title: title,
            options: [for (var i = 0; i < labels.length; i++) i],
            labelOf: (i) => labels[i],
            isSelected: (i) => i == index,
          ),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

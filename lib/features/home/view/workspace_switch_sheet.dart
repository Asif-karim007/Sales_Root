import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The workspace switcher (#18): every workspace the user belongs to, the
/// current one ticked, and a way to start a new team.
Future<void> showWorkspaceSwitcher(BuildContext context) => showSrSheet<void>(
  context: context,
  builder: (_) => const _WorkspaceSwitchSheet(),
);

class _WorkspaceSwitchSheet extends ConsumerWidget {
  const _WorkspaceSwitchSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final workspaces = ref.watch(workspacesProvider);
    final currentId = ref.watch(currentWorkspaceProvider.select((w) => w?.id));
    return SrSheet(
      title: l10n.homeWorkspaces,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrAsyncView<List<Workspace>>(
            value: workspaces,
            onRetry: () => ref.invalidate(workspacesProvider),
            loading: (_) => const SrSkeletonList(count: 3, shrinkWrap: true),
            data: (context, list) => SrRowGroup(
              rows: [
                for (final workspace in list)
                  _WorkspaceRow(
                    workspace: workspace,
                    selected: workspace.id == currentId,
                    onTap: () => _select(context, ref, workspace),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SrButton(
            label: l10n.homeCreateTeam,
            icon: Icons.group_add_outlined,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.push(Routes.createTeam);
            },
          ),
        ],
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, Workspace workspace) {
    if (workspace.id != ref.read(currentWorkspaceProvider)?.id) {
      ref.read(currentWorkspaceProvider.notifier).select(workspace);
      showSrSuccess(
        context,
        context.l10n.homeWorkspaceSwitched(workspace.name),
      );
    }
    Navigator.of(context).pop();
  }
}

class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final Workspace workspace;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final role = switch (workspace.role) {
      WorkspaceRole.owner => l10n.homeRoleOwner,
      WorkspaceRole.teamLead => l10n.homeRoleTeamLead,
      WorkspaceRole.member => l10n.homeRoleMember,
    };
    return SrListRow(
      title: workspace.name,
      subtitle: workspace.isPersonal
          ? l10n.homeWorkspacePersonal(fmt.number(workspace.leadCount))
          : l10n.homeWorkspaceTeam(role, fmt.number(workspace.memberCount)),
      leading: SrAvatar(
        name: workspace.name,
        tone: selected
            ? SrAvatarTone.dark
            : workspace.isPersonal
            ? SrAvatarTone.neutral
            : SrAvatarTone.accent,
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: c.accent, size: 22)
          : null,
      onTap: onTap,
    );
  }
}

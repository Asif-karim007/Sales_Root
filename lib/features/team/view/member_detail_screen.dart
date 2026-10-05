import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/invite_form_screen.dart';
import 'package:salesroot/features/team/view/widget/external_links.dart';
import 'package:salesroot/features/team/view/widget/info_card.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/team_sheets.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #70 `memberdetail`: stats, role, level and manager, with the actions an
/// owner or team lead has on them.
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberProvider(memberId));
    final access = ref.watch(moduleAccessProvider(AppModule.team));
    ref.listen(memberEditorProvider(memberId), (_, next) {
      switch (next) {
        case AsyncData(value: _?):
          showSrSuccess(context, context.l10n.teamSaved);
        case AsyncError(:final error):
          showSrError(context, failureText(context, error));
        default:
      }
    });
    final loaded = member.value;
    final canEdit = access.canEdit && (loaded?.canEdit ?? false);
    final canRemove = access.canDelete && (loaded?.canDelete ?? false);
    return SrScaffold(
      appBar: SrAppBar(
        actions: [
          const TeamLanguageToggle(),
          if (loaded?.phone case final phone?)
            SrIconButton(
              icon: Icons.call_outlined,
              tooltip: context.l10n.commonCall,
              onTap: () => openExternal(context, callUri(phone)),
            ),
          if (loaded != null && canEdit && !loaded.isOwner)
            SrIconButton(
              icon: Icons.more_horiz_rounded,
              tooltip: context.l10n.commonMore,
              onTap: () => _more(context, ref, loaded),
            ),
        ],
        bottom: loaded == null ? null : _Profile(member: loaded),
      ),
      footer: loaded == null || !canRemove
          ? null
          : SrButton(
              label: context.l10n.teamRemoveAndReassign,
              variant: SrButtonVariant.danger,
              expand: true,
              onPressed: () => context.push(Routes.memberRemoveFor(loaded.id)),
            ),
      body: SrAsyncView(
        value: member,
        onRetry: () => ref.invalidate(memberProvider(memberId)),
        loading: (_) => const SrSkeletonList(cards: true, count: 3),
        data: (context, member) => _Body(member: member, canEdit: canEdit),
      ),
    );
  }

  Future<void> _more(BuildContext context, WidgetRef ref, Member member) async {
    final l10n = context.l10n;
    final editor = ref.read(memberEditorProvider(memberId).notifier);
    final action = await showSrSheet<_MoreAction>(
      context: context,
      builder: (context) => SrSheet(
        title: context.name(member.name),
        child: SrRowGroup(
          rows: [
            SrListRow(
              title: l10n.teamChangeManager,
              leading: const SrAvatar(icon: Icons.account_tree_outlined),
              onTap: () => Navigator.of(context).pop(_MoreAction.manager),
            ),
            SrListRow(
              title: member.isActive
                  ? l10n.teamDeactivate
                  : l10n.teamReactivate,
              subtitle: member.isActive ? l10n.teamDeactivateAbout : null,
              leading: SrAvatar(
                icon: member.isActive
                    ? Icons.person_off_outlined
                    : Icons.person_outline_rounded,
                tone: member.isActive
                    ? SrAvatarTone.danger
                    : SrAvatarTone.accent,
              ),
              onTap: () => Navigator.of(context).pop(_MoreAction.active),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _MoreAction.manager:
        await changeManager(context, ref, member);
      case _MoreAction.active when member.isActive:
        final sure = await showSrConfirm(
          context,
          title: l10n.teamDeactivateTitle(context.name(member.name)),
          message: l10n.teamDeactivateAbout,
          confirmLabel: l10n.teamDeactivate,
          icon: Icons.person_off_outlined,
          destructive: true,
        );
        if (sure) {
          await editor.apply(
            const MemberUpdate(status: MembershipStatus.suspended),
          );
        }
      case _MoreAction.active:
        await editor.apply(const MemberUpdate(status: MembershipStatus.active));
      case null:
    }
  }
}

enum _MoreAction { manager, active }

/// Picks who [member] reports to and saves it; null when nothing was
/// picked, else how the save went.
Future<AsyncValue<Member?>?> changeManager(
  BuildContext context,
  WidgetRef ref,
  Member member,
) async {
  final directory = await ref.read(teamDirectoryProvider.future);
  if (!context.mounted) return null;
  final managers = managersOf(
    directory,
  ).where((m) => m.id != member.id).toList();
  final picked = await showSrSheet<Member>(
    context: context,
    builder: (context) => SrOptionSheet<Member>(
      title: context.l10n.teamReportsTo,
      options: managers,
      withAvatar: true,
      labelOf: (m) => context.name(m.name),
      subtitleOf: (m) => context.roleLabel(m.role),
      isSelected: (m) => m.id == member.managerId,
    ),
  );
  if (picked == null || picked.id == member.managerId) return null;
  final editor = memberEditorProvider(member.id);
  final keepAlive = ref.listenManual(editor, (_, _) {});
  try {
    await ref.read(editor.notifier).apply(MemberUpdate(managerId: picked.id));
    return ref.read(editor);
  } finally {
    keepAlive.close();
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final name = context.name(member.name);
    final contact = [
      if (member.phone case final phone?) context.phone(phone),
      ?member.designation,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(
        children: [
          SrAvatar(
            name: context.avatarName(name),
            size: 56,
            imageUrl: member.imageUrl,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.pageTitle(c.ink, size: 20)),
                if (contact.isNotEmpty)
                  Text(contact, style: AppText.meta(c.ink2, size: 13)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    SrTag(context.roleLabel(member.role)),
                    ?context.memberStatusTag(member, always: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.member, required this.canEdit});

  final Member member;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final stats = member.stats;
    final managerName = member.managerName;
    final joined = member.joiningDate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        14,
        SrMetrics.gutter,
        24,
      ),
      children: [
        if (stats != null) ...[
          SrStatGrid(
            tiles: [
              SrKpiTile(
                label: l10n.teamStatLeadsThisMonth,
                value: fmt.number(stats.leadsThisMonth),
              ),
              SrKpiTile(
                label: l10n.teamStatWon,
                value: fmt.moneyCompact(stats.wonValue),
              ),
              SrKpiTile(
                label: l10n.teamStatCollected,
                value: fmt.moneyCompact(stats.collected),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        InfoCard(
          lines: [
            InfoLine(l10n.teamRole, context.roleLabel(member.role)),
            if (managerName != null)
              InfoLine(
                l10n.teamReportsTo,
                context.name(managerName),
                onTap: canEdit
                    ? () => changeManager(context, ref, member)
                    : null,
              ),
            InfoLine(l10n.teamLevel, context.levelLabel(member.level)),
            if (member.area case final area?) InfoLine(l10n.teamArea, area),
            if (joined != null)
              InfoLine(l10n.teamJoined, fmt.monthYear(joined)),
          ],
        ),
        if (canEdit && !member.isOwner) ...[
          const SizedBox(height: 12),
          _EditButtons(member: member),
        ],
        if (stats != null) ...[
          const SizedBox(height: 18),
          SrSectionHeader(title: l10n.teamOpenWork),
          const SizedBox(height: 10),
          SrRowGroup(
            rows: [
              SrListRow(
                leading: const SrAvatar(
                  icon: Icons.work_outline_rounded,
                  tone: SrAvatarTone.accent,
                ),
                title: l10n.teamOpenLeads(
                  stats.openLeads,
                  fmt.number(stats.openLeads),
                ),
                subtitle: l10n.teamOverdueTasks(
                  stats.overdueTasks,
                  fmt.number(stats.overdueTasks),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Change level and change role.
class _EditButtons extends ConsumerWidget {
  const _EditButtons({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final levelLocked = ref.watch(experienceLevelLockedProvider);
    final editor = ref.read(memberEditorProvider(member.id).notifier);
    final busy = ref.watch(memberEditorProvider(member.id)).isLoading;
    return Row(
      children: [
        if (!levelLocked) ...[
          Expanded(
            child: SrButton(
              label: l10n.teamChangeLevel,
              size: SrButtonSize.sm,
              variant: SrButtonVariant.secondary,
              expand: true,
              onPressed: busy
                  ? null
                  : () async {
                      final level = await showLevelSheet(context, member.level);
                      if (level == null || level == member.level) return;
                      await editor.apply(MemberUpdate(level: level));
                    },
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: SrButton(
            label: l10n.teamChangeRole,
            size: SrButtonSize.sm,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: busy
                ? null
                : () async {
                    final role = await showRolePickSheet(
                      context,
                      selected: member.role,
                    );
                    if (role == null || role == member.role) return;
                    await editor.apply(MemberUpdate(role: role));
                  },
          ),
        ),
      ],
    );
  }
}

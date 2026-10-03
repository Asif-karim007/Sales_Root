import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/member_row.dart';
import 'package:salesroot/features/team/view/widget/paged_list.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/team_sheets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #64 `team`: the workspace, its seats and everyone in it.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(memberFilterProvider);
    final header = [
      const _WorkspaceCard(),
      const _Actions(),
      const _FilterChips(),
    ];
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.teamTitle,
        actions: [
          const TeamLanguageToggle(),
          SrIconButton(
            icon: Icons.search_rounded,
            tooltip: l10n.commonSearch,
            onTap: () => context.push(Routes.search),
          ),
        ],
      ),
      body: filter == MemberFilter.pending
          ? _InviteList(header: header)
          : _MemberList(header: header),
    );
  }
}

/// Opens the invite form, or the add-users sheet when every seat is taken.
void startInvite(BuildContext context, WidgetRef ref) {
  final plan = ref.read(planProvider).value;
  if (plan != null && !plan.hasFreeSeat) {
    showNoSeatSheet(context);
    return;
  }
  context.push(Routes.teamInvite);
}

class _WorkspaceCard extends ConsumerWidget {
  const _WorkspaceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final workspace = ref.watch(currentWorkspaceProvider);
    final role = ref.watch(currentRoleProvider);
    final plan = ref.watch(planProvider).value;
    final name = workspace?.name ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
      child: SrCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SrAvatar(name: name, size: 48, tone: SrAvatarTone.dark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppText.sectionTitle(c.ink, size: 17)),
                      if (plan != null)
                        Text(
                          _planLine(context, plan),
                          style: AppText.meta(c.ink2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SrTag(context.roleLabel(role), tone: SrTone.ok),
              ],
            ),
            if (plan != null) ...[
              const SizedBox(height: 12),
              SrProgressBar(
                value: plan.users == 0 ? 0 : plan.usersUsed / plan.users,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _planLine(BuildContext context, Plan plan) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return [
      l10n.teamPlanName(plan.name),
      l10n.teamSeatsUsed(fmt.number(plan.usersUsed), fmt.number(plan.users)),
      if (plan.has(AddOn.fieldForce)) l10n.teamFieldForceOn,
    ].join(' · ');
  }
}

class _Actions extends ConsumerWidget {
  const _Actions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(moduleAccessProvider(AppModule.team));
    final buttons = [
      if (access.canAdd)
        SrButton(
          label: l10n.teamInvite,
          icon: Icons.person_add_alt_rounded,
          size: SrButtonSize.sm,
          expand: true,
          onPressed: () => startInvite(context, ref),
        ),
      SrButton(
        label: l10n.teamOrganogram,
        icon: Icons.account_tree_outlined,
        size: SrButtonSize.sm,
        variant: SrButtonVariant.secondary,
        expand: true,
        onPressed: () => context.push(Routes.organogram),
      ),
      SrButton(
        label: l10n.teamRoles,
        icon: Icons.badge_outlined,
        size: SrButtonSize.sm,
        variant: SrButtonVariant.secondary,
        expand: true,
        onPressed: () => showRolePickSheet(context, readOnly: true),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
      child: Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: buttons[i]),
          ],
        ],
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canInvite = ref.watch(
      moduleAccessProvider(AppModule.team).select((a) => a.canAdd),
    );
    final filter = ref.watch(memberFilterProvider);
    final counts = ref.watch(
      memberListProvider.select(
        (list) =>
            list.value?.facets[MemberListNotifier.countsKey] ??
            const <String, int>{},
      ),
    );
    final filters = [
      MemberFilter.all,
      MemberFilter.activeToday,
      if (canInvite) MemberFilter.pending,
      MemberFilter.teamLeads,
    ];
    String label(MemberFilter f) => switch (f) {
      MemberFilter.all => l10n.commonAll,
      MemberFilter.activeToday => l10n.teamFilterActiveToday,
      MemberFilter.pending => l10n.teamPending,
      MemberFilter.teamLeads => l10n.teamFilterTeamLeads,
    };
    return SrChipRow(
      chips: [
        for (final f in filters)
          SrChipItem(
            label(f),
            count: f == MemberFilter.teamLeads ? null : counts[f.wire],
          ),
      ],
      index: filters.indexOf(filter).clamp(0, filters.length - 1),
      onChanged: (i) => ref.read(memberFilterProvider.notifier).set(filters[i]),
    );
  }
}

class _MemberList extends ConsumerWidget {
  const _MemberList({required this.header});

  final List<Widget> header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(memberListProvider);
    final notifier = ref.read(memberListProvider.notifier);
    return members.when(
      data: (paged) => PagedCardList<Member>(
        paged: paged,
        header: header,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        empty: SrEmptyState(
          icon: Icons.groups_outlined,
          title: context.l10n.teamEmptyTitle,
          message: context.l10n.teamEmptyBody,
        ),
        itemBuilder: (context, member) => MemberRow(member: member),
      ),
      loading: () => _HeaderOver(
        header: header,
        child: const SrSkeletonList(shrinkWrap: true, padding: _listPadding),
      ),
      error: (error, _) => _HeaderOver(
        header: header,
        child: SrErrorState(error: error, onRetry: notifier.refresh),
      ),
    );
  }
}

const _listPadding = EdgeInsets.symmetric(horizontal: SrMetrics.gutter);

/// The list header above a loading or error state.
class _HeaderOver extends StatelessWidget {
  const _HeaderOver({required this.header, required this.child});

  final List<Widget> header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 32),
      children: [
        for (final widget in header) ...[widget, const SizedBox(height: 12)],
        child,
      ],
    );
  }
}

class _InviteList extends ConsumerWidget {
  const _InviteList({required this.header});

  final List<Widget> header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final invites = ref.watch(pendingInvitesProvider);
    return _HeaderOver(
      header: header,
      child: Padding(
        padding: _listPadding,
        child: switch (invites) {
          AsyncValue(:final List<Invite> value) when value.isEmpty =>
            SrEmptyState(
              icon: Icons.mark_email_read_outlined,
              title: l10n.teamInvitesEmptyTitle,
              message: l10n.teamInvitesEmptyBody,
            ),
          AsyncValue(:final List<Invite> value) => SrRowGroup(
            dividerIndent: 66,
            rows: [
              for (final invite in value)
                SrListRow(
                  title: invite.label,
                  subtitle: inviteSubtitle(context, invite),
                  leading: SrAvatar(name: invite.label),
                  trailing: SrTag(l10n.teamPending, tone: SrTone.warn),
                  onTap: () => showInvitePendingSheet(context, invite),
                ),
            ],
          ),
          AsyncError(:final error) => SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(pendingInvitesProvider),
          ),
          _ => const SrSkeletonList(
            count: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
          ),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/team_summary.dart';
import 'package:salesroot/features/home/view/widget/home_scroll_view.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #16: the team lead's home — the team's activity, silent leads, who is
/// working today and what is waiting for approval.
class TeamLeadHomeView extends ConsumerWidget {
  const TeamLeadHomeView({super.key, required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = summary.team ?? const TeamSummary();
    final approvals = ref.watch(
      moduleAccessProvider(AppModule.approvals).select((a) => a.canApprove),
    );
    return HomeScrollView(
      children: [
        _TeamTiles(team: team),
        _MembersToday(members: team.members),
        if (approvals) _PendingApprovals(count: team.approvalsCount),
      ],
    );
  }
}

class _TeamTiles extends ConsumerWidget {
  const _TeamTiles({required this.team});

  final TeamSummary team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final teamAccess = ref.watch(
      moduleAccessProvider(AppModule.team).select((a) => a.canView),
    );
    final leads = ref.watch(
      moduleAccessProvider(AppModule.lead).select((a) => a.canView),
    );
    final reports = ref.watch(
      moduleAccessProvider(AppModule.reports).select((a) => a.visible),
    );
    final target = team.targetPercent;
    final tiles = [
      SrKpiTile(
        label: l10n.homeTeamActivity,
        value: fmt.number(team.activityToday),
        onTap: teamAccess ? () => context.go(Routes.team) : null,
      ),
      SrKpiTile(
        label: l10n.homeNoFollowUp,
        value: fmt.number(team.noFollowUp),
        onTap: leads ? () => context.go(Routes.leads) : null,
      ),
      if (target != null)
        SrKpiTile(
          label: l10n.homeTeamTarget,
          value: fmt.percent(target),
          onTap: reports ? () => context.push(Routes.reportSales) : null,
        ),
    ];
    return SrStatGrid(columns: tiles.length, tiles: tiles);
  }
}

/// Each team member's calls, visits and check-in so far today.
class _MembersToday extends ConsumerWidget {
  const _MembersToday({required this.members});

  final List<MemberToday> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final team = ref.watch(moduleAccessProvider(AppModule.team));
    if (members.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(title: l10n.homeMembersToday),
          const SizedBox(height: 8),
          SrCard(
            child: SrEmptyState(
              icon: Icons.groups_outlined,
              title: l10n.homeNoMembersTitle,
              message: l10n.homeNoMembersBody,
              actionLabel: team.canAdd ? l10n.homeInvite : null,
              onAction: team.canAdd
                  ? () => context.push(Routes.teamInvite)
                  : null,
            ),
          ),
        ],
      );
    }
    return SrRowGroup(
      title: l10n.homeMembersToday,
      seeAllLabel: l10n.commonAll,
      onSeeAll: team.canView ? () => context.go(Routes.team) : null,
      rows: [
        for (final member in members)
          _MemberRow(member: member, canOpen: team.canView),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.canOpen});

  final MemberToday member;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final name = member.name;
    final checkIn = member.checkInAt;
    return SrListRow(
      title: name,
      subtitle: checkIn == null
          ? l10n.homeMemberNotIn
          : l10n.homeMemberStats(
              fmt.number(member.calls),
              fmt.number(member.visits),
              fmt.time(checkIn),
            ),
      leading: SrAvatar(name: name),
      trailing: switch (member.status) {
        MemberDayStatus.active => SrTag(l10n.homeStatusActive, tone: SrTone.ok),
        MemberDayStatus.late => SrTag(l10n.homeStatusLate, tone: SrTone.warn),
        MemberDayStatus.absent => SrTag(
          l10n.homeStatusAbsent,
          tone: SrTone.err,
        ),
      },
      chevron: canOpen,
      onTap: canOpen
          ? () => context.push(Routes.memberFor(member.memberId))
          : null,
    );
  }
}

/// How many leave, expense and other requests wait for the team lead; a tap
/// opens the approvals inbox.
class _PendingApprovals extends StatelessWidget {
  const _PendingApprovals({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (count == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(title: l10n.homePendingApprovals),
          const SizedBox(height: 8),
          SrCard(
            child: SrEmptyState(
              icon: Icons.task_alt_rounded,
              title: l10n.homeNoApprovals,
            ),
          ),
        ],
      );
    }
    return SrRowGroup(
      title: l10n.homePendingApprovals,
      rows: [
        SrListRow(
          title: l10n.homeApprovalsWaiting(context.fmt.number(count)),
          leading: const SrAvatar(
            icon: Icons.verified_outlined,
            tone: SrAvatarTone.gold,
          ),
          chevron: true,
          onTap: () => context.push(Routes.approvals),
        ),
      ],
    );
  }
}

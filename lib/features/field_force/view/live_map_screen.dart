import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/providers/tracking_providers.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/ff_map.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #127 livemap: where the team is today, with last-seen and battery.
class LiveMapScreen extends ConsumerWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final role = ref.watch(currentRoleProvider);
    final workspace = ref.watch(currentWorkspaceProvider);
    final canEdit = ref.watch(
      moduleAccessProvider(AppModule.liveTracking).select((a) => a.canEdit),
    );
    final team = ref.watch(liveTeamProvider);
    final roleLabel = switch (role) {
      WorkspaceRole.owner => l10n.ffRoleOwner,
      WorkspaceRole.teamLead => l10n.ffRoleTeamLead,
      WorkspaceRole.member => l10n.ffRoleMember,
    };

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffLiveTitle,
        subtitle: [roleLabel, ?workspace?.name].join(' · '),
        actions: [
          const FfLanguageToggle(),
          if (canEdit)
            SrIconButton(
              icon: Icons.settings_outlined,
              tooltip: l10n.ffSettingsTitle,
              onTap: () => context.push(Routes.trackingSettings),
            ),
        ],
      ),
      body: FieldForceGate(
        module: AppModule.liveTracking,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(liveTeamProvider.future),
          child: switch (team) {
            AsyncValue(:final value?) when value.isEmpty => ListView(
              children: [
                SrEmptyState(
                  icon: Icons.groups_outlined,
                  title: l10n.ffLiveEmptyTitle,
                  message: l10n.ffLiveEmptyBody,
                ),
              ],
            ),
            AsyncValue(:final value?) => _LiveBody(members: value),
            AsyncError(:final error) => SrErrorState(
              error: error,
              onRetry: () => ref.invalidate(liveTeamProvider),
            ),
            _ => const SrSkeletonList(count: 5),
          },
        ),
      ),
    );
  }
}

class _LiveBody extends ConsumerWidget {
  const _LiveBody({required this.members});

  final List<LiveMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final filter = ref.watch(liveFilterProvider);
    final shown = members.where(filter.matches).toList();
    int count(LiveFilter f) => members.where(f.matches).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: SrScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        FfMap(
          height: 260,
          pins: [
            for (final m in shown)
              if (m.latitude case final lat?)
                if (m.longitude case final lng?)
                  FfMapPin(
                    id: 'm${m.memberId}',
                    latitude: lat,
                    longitude: lng,
                    title: m.name,
                    subtitle: switch (m.lastSeenAt) {
                      final seen? => l10n.ffLastSeen(fmt.time(seen)),
                      _ => null,
                    },
                    tone: m.status.isLive ? FfPinTone.accent : FfPinTone.muted,
                    onTap: () =>
                        context.push(Routes.trackingMemberFor(m.memberId)),
                  ),
          ],
        ),
        const SizedBox(height: 12),
        SrChipRow(
          padding: EdgeInsets.zero,
          index: filter.index,
          onChanged: (i) =>
              ref.read(liveFilterProvider.notifier).set(LiveFilter.values[i]),
          chips: [
            SrChipItem(l10n.ffLiveAll, count: count(LiveFilter.all)),
            SrChipItem(
              l10n.ffLiveCheckedIn,
              count: count(LiveFilter.checkedIn),
            ),
            SrChipItem(l10n.ffLiveOffDuty, count: count(LiveFilter.offDuty)),
          ],
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          SrCard(child: SrEmptyState(title: l10n.ffLiveFilterEmpty))
        else
          SrRowGroup(
            rows: [
              for (final member in shown)
                _MemberRow(
                  member: member,
                  onTap: () =>
                      context.push(Routes.trackingMemberFor(member.memberId)),
                ),
            ],
          ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final LiveMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final seenAt = member.lastSeenAt;
    final subtitle = [
      switch (member.status) {
        LiveStatus.live when seenAt != null => l10n.ffLastSeen(
          fmt.time(seenAt),
        ),
        LiveStatus.live => l10n.ffLiveCheckedIn,
        LiveStatus.checkedOut => l10n.ffLiveCheckedOut,
        LiveStatus.offDuty => l10n.ffNotCheckedIn,
      },
      if (member.visits > 0) l10n.ffVisitCount(fmt.number(member.visits)),
      if (member.mockDetected) l10n.ffMockFlag,
    ].join(' · ');
    final (tag, tone, avatarTone) = member.status.isLive
        ? (l10n.ffLiveLive, SrTone.ok, SrAvatarTone.accent)
        : (l10n.ffLiveOffDuty, SrTone.neutral, SrAvatarTone.neutral);
    final battery = member.battery;

    return SrListRow(
      leading: SrAvatar(name: member.name, tone: avatarTone),
      title: member.name,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SrTag(tag, tone: tone),
          if (battery != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  battery < 20
                      ? Icons.battery_alert_rounded
                      : Icons.battery_std_rounded,
                  size: 14,
                  color: battery < 20 ? c.danger : c.ink3,
                ),
                Text(
                  fmt.percent(battery),
                  style: AppText.meta(c.ink2, size: 11.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

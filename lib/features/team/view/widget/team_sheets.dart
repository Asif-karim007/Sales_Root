import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #66 `rolepick`: the roles and what each may do. Pops with the chosen
/// role; with [readOnly] it only explains every role.
Future<WorkspaceRole?> showRolePickSheet(
  BuildContext context, {
  WorkspaceRole? selected,
  bool readOnly = false,
}) => showSrSheet<WorkspaceRole>(
  context: context,
  builder: (_) => _RoleSheet(selected: selected, readOnly: readOnly),
);

class _RoleSheet extends StatelessWidget {
  const _RoleSheet({required this.selected, required this.readOnly});

  final WorkspaceRole? selected;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final roles = readOnly
        ? WorkspaceRole.values
        : const [WorkspaceRole.member, WorkspaceRole.teamLead];
    return SrSheet(
      title: readOnly ? context.l10n.teamRolesTitle : context.l10n.teamRole,
      child: SingleChildScrollView(
        child: SrRowGroup(
          dividerIndent: 66,
          rows: [
            for (final role in roles)
              SrListRow(
                title: context.roleLabel(role),
                subtitle: context.roleDescription(role),
                leading: SrAvatar(
                  icon: _iconOf(role),
                  tone: role == selected
                      ? SrAvatarTone.accent
                      : SrAvatarTone.neutral,
                ),
                trailing: role == selected
                    ? Icon(Icons.check_rounded, color: c.accent)
                    : null,
                onTap: readOnly ? null : () => Navigator.of(context).pop(role),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconOf(WorkspaceRole role) => switch (role) {
    WorkspaceRole.owner => Icons.workspace_premium_outlined,
    WorkspaceRole.teamLead => Icons.supervisor_account_outlined,
    WorkspaceRole.member => Icons.person_outline_rounded,
  };
}

/// #68 `invitepending`: resend or revoke one invitation.
Future<void> showInvitePendingSheet(BuildContext context, Invite invite) =>
    showSrSheet<void>(
      context: context,
      builder: (_) => _InvitePendingSheet(invite: invite),
    );

class _InvitePendingSheet extends ConsumerWidget {
  const _InvitePendingSheet({required this.invite});

  final Invite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = inviteActionsProvider(invite.id);
    final state = ref.watch(actions);
    ref.listen(actions, (_, next) {
      switch (next) {
        case AsyncData(value: final outcome?):
          Navigator.of(context).pop();
          showSrSuccess(
            context,
            outcome == InviteOutcome.resent
                ? l10n.teamInviteResent
                : l10n.teamInviteRevoked,
          );
        case AsyncError(:final error):
          showSrError(context, failureText(context, error));
        default:
      }
    });
    final busy = state.isLoading;
    return SrSheet(
      title: l10n.teamInvitePendingTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrRowGroup(
            rows: [
              SrListRow(
                title: invite.label,
                subtitle: inviteSubtitle(context, invite),
                leading: SrAvatar(name: invite.label),
                trailing: SrTag(l10n.teamPending, tone: SrTone.warn),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SrButton(
            label: l10n.teamInviteResend,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: busy ? null : () => ref.read(actions.notifier).resend(),
          ),
          const SizedBox(height: 10),
          SrButton(
            label: l10n.teamInviteRevoke,
            variant: SrButtonVariant.danger,
            expand: true,
            loading: busy,
            onPressed: busy ? null : () => ref.read(actions.notifier).revoke(),
          ),
        ],
      ),
    );
  }
}

/// "+880 1912 345 678 · 2 days ago · Member".
String inviteSubtitle(BuildContext context, Invite invite) {
  final l10n = context.l10n;
  final address = invite.phone ?? invite.email ?? '';
  final when = invite.sentDaysAgo == 0
      ? l10n.commonToday
      : l10n.relativeDays(context.fmt.number(invite.sentDaysAgo));
  return [
    if (invite.label != address) context.phone(address),
    when,
    context.roleLabel(invite.role),
  ].join(' · ');
}

/// #69 `noseat`: every user seat is taken; pick a pack and go to the plan.
Future<void> showNoSeatSheet(BuildContext context) =>
    showSrSheet<void>(context: context, builder: (_) => const _NoSeatSheet());

class _NoSeatSheet extends ConsumerStatefulWidget {
  const _NoSeatSheet();

  @override
  ConsumerState<_NoSeatSheet> createState() => _NoSeatSheetState();
}

class _NoSeatSheetState extends ConsumerState<_NoSeatSheet> {
  int _picked = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final plan = ref.watch(planProvider).value;
    final packs = ref.watch(seatPacksProvider);
    return SrSheet(
      title: l10n.teamNoSeatTitle,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teamNoSeatBody(fmt.number(plan?.users ?? 0)),
              style: AppText.lead(SrColors.of(context).ink2),
            ),
            const SizedBox(height: 14),
            SrAsyncView(
              value: packs,
              onRetry: () => ref.invalidate(seatPacksProvider),
              loading: (_) => const SrSkeletonBox(height: 120, radius: 14),
              data: (_, packs) => _packs(context, packs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _packs(BuildContext context, List<SeatPack> packs) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    if (packs.isEmpty) return const SrEmptyState();
    final picked = packs[_picked.clamp(0, packs.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < packs.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _PackCard(
                  pack: packs[i],
                  selected: packs[i] == picked,
                  onTap: () => setState(() => _picked = i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        SrNote(
          message: l10n.teamNoSeatProrated(fmt.money(picked.proratedToday)),
        ),
        const SizedBox(height: 16),
        SrButton(
          label: l10n.teamNoSeatAction(
            picked.seats,
            fmt.number(picked.seats),
            fmt.money(picked.proratedToday),
          ),
          expand: true,
          onPressed: () {
            Navigator.of(context).pop();
            context.push('${Routes.planChoose}?reason=quota&kind=users');
          },
        ),
      ],
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.selected,
    required this.onTap,
  });

  final SeatPack pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    return Material(
      color: selected ? c.tint : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        side: BorderSide(color: selected ? c.accent : c.line, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Text(
                '+${fmt.number(pack.seats)}',
                style: AppText.sectionTitle(c.ink, size: 17),
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  fmt.money(pack.pricePerMonth),
                  style: AppText.rowTitle(c.accent, size: 15),
                ),
              ),
              Text(
                context.l10n.teamPerMonth,
                style: AppText.meta(c.ink3, size: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

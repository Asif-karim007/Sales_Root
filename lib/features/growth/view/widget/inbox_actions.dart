import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Picks a team member; null when the sheet is dismissed or the list fails.
Future<GrowthMember?> pickGrowthMember(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  int? selected,
}) async {
  final members = await runGrowthAction(
    context,
    ref.read(growthMembersProvider.future),
  );
  if (members == null || !context.mounted) return null;
  final l10n = context.l10n;
  final fmt = context.fmt;
  return showSrSheet<GrowthMember>(
    context: context,
    builder: (_) => SrOptionSheet<GrowthMember>(
      title: title,
      options: members,
      withAvatar: true,
      labelOf: (m) => m.nameOf(fmt.isBangla),
      subtitleOf: (m) => m.onLeave
          ? l10n.growthMemberOnLeave
          : l10n.growthMemberLoad(fmt.number(m.openLeads)),
      isSelected: (m) => m.id == selected,
    ),
  );
}

Future<void> assignInboxLead(
  BuildContext context,
  WidgetRef ref,
  InboxLead lead,
) async {
  final l10n = context.l10n;
  final member = await pickGrowthMember(
    context,
    ref,
    title: l10n.growthInboxAssignTo,
    selected: lead.assignedToId,
  );
  if (member == null || !context.mounted) return;
  final done = await runGrowthAction(
    context,
    ref.read(inboxActionsProvider.notifier).assign(lead.id, member.id),
  );
  if (done == null || !context.mounted) return;
  showSrSuccess(
    context,
    l10n.growthInboxAssigned(member.nameOf(context.fmt.isBangla)),
  );
}

/// Asks for a reason and rejects; true when it went through.
Future<bool> rejectInboxLead(
  BuildContext context,
  WidgetRef ref,
  InboxLead lead,
) async {
  final l10n = context.l10n;
  final reason = await showSrSheet<RejectReason>(
    context: context,
    builder: (_) => SrOptionSheet<RejectReason>(
      title: l10n.growthInboxRejectWhy,
      options: [
        ...RejectReason.values.where((r) => r != RejectReason.duplicate),
        if (lead.duplicate != null) RejectReason.duplicate,
      ],
      labelOf: (r) => r.label(l10n),
      isSelected: (_) => false,
    ),
  );
  if (reason == null || !context.mounted) return false;
  final done = await runGrowthAction(
    context,
    ref.read(inboxActionsProvider.notifier).reject(lead.id, reason),
  );
  if (done == null || !context.mounted) return false;
  showSrInfo(context, l10n.growthInboxRejected(lead.name));
  return true;
}

enum InboxQuickAction { accept, assign, reject }

/// Long-press actions on an inbox row; pops with the one picked.
class InboxQuickSheet extends StatelessWidget {
  const InboxQuickSheet({super.key, required this.lead});

  final InboxLead lead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    return SrSheet(
      title: lead.name,
      subtitle: lead.source.label(l10n),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SrListRow(
            leading: const Icon(Icons.check_circle_outline_rounded),
            title: l10n.growthInboxAccept,
            onTap: () => navigator.pop(InboxQuickAction.accept),
          ),
          SrListRow(
            leading: const Icon(Icons.person_add_alt_rounded),
            title: l10n.growthInboxAssign,
            onTap: () => navigator.pop(InboxQuickAction.assign),
          ),
          SrListRow(
            leading: const Icon(Icons.block_rounded),
            title: l10n.growthInboxReject,
            onTap: () => navigator.pop(InboxQuickAction.reject),
          ),
        ],
      ),
    );
  }
}

/// Opens [InboxQuickSheet] and carries out the action picked.
Future<void> showInboxQuickActions(
  BuildContext context,
  WidgetRef ref,
  InboxLead lead,
) async {
  final action = await showSrSheet<InboxQuickAction>(
    context: context,
    builder: (_) => InboxQuickSheet(lead: lead),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case InboxQuickAction.accept:
      context.push(Routes.newLeadAcceptFor(lead.id));
    case InboxQuickAction.assign:
      await assignInboxLead(context, ref, lead);
    case InboxQuickAction.reject:
      await rejectInboxLead(context, ref, lead);
  }
}

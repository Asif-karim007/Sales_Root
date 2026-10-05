import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Picks one of [members]; null when the sheet is dismissed or the list
/// fails.
Future<GrowthMember?> pickGrowthMember(
  BuildContext context, {
  required Future<List<GrowthMember>> members,
  required String title,
  String? selected,
}) async {
  final list = await runGrowthAction(context, members);
  if (list == null || !context.mounted) return null;
  final l10n = context.l10n;
  final fmt = context.fmt;
  return showSrSheet<GrowthMember>(
    context: context,
    builder: (_) => SrOptionSheet<GrowthMember>(
      title: title,
      options: list,
      withAvatar: true,
      labelOf: (m) => m.nameOf(fmt.isBangla),
      subtitleOf: (m) => switch (m.openLeads) {
        _ when m.onLeave => l10n.growthMemberOnLeave,
        final open? => l10n.growthMemberLoad(fmt.number(open)),
        null => null,
      },
      isSelected: (m) => m.id == selected,
    ),
  );
}

Future<void> assignConversation(
  BuildContext context,
  WidgetRef ref,
  Conversation conversation,
) async {
  final l10n = context.l10n;
  final member = await pickGrowthMember(
    context,
    members: ref.read(inboxMembersProvider.future),
    title: l10n.growthInboxAssignTo,
    selected: conversation.assignedToId,
  );
  if (member == null || !context.mounted) return;
  final done = await runGrowthAction(
    context,
    ref.read(inboxActionsProvider.notifier).assign(conversation.id, member.id),
  );
  if (done == null || !context.mounted) return;
  showSrSuccess(
    context,
    l10n.growthInboxAssigned(member.nameOf(context.fmt.isBangla)),
  );
}

/// Asks first, then closes the conversation; true when it went through.
Future<bool> rejectConversation(
  BuildContext context,
  WidgetRef ref,
  Conversation conversation,
) async {
  final l10n = context.l10n;
  final confirmed = await showSrConfirm(
    context,
    title: l10n.growthInboxRejectTitle,
    message: l10n.growthInboxRejectBody,
    confirmLabel: l10n.growthInboxReject,
    icon: Icons.block_rounded,
    destructive: true,
  );
  if (!confirmed || !context.mounted) return false;
  final done = await runGrowthAction(
    context,
    ref.read(inboxActionsProvider.notifier).close(conversation.id),
  );
  if (done == null || !context.mounted) return false;
  showSrInfo(context, l10n.growthInboxRejected(conversation.name));
  return true;
}

enum InboxQuickAction { accept, assign, reject }

/// Long-press actions on an inbox row; pops with the one picked.
class InboxQuickSheet extends StatelessWidget {
  const InboxQuickSheet({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    return SrSheet(
      title: conversation.name,
      subtitle: conversation.channel.label(l10n),
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
  Conversation conversation,
) async {
  final action = await showSrSheet<InboxQuickAction>(
    context: context,
    builder: (_) => InboxQuickSheet(conversation: conversation),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case InboxQuickAction.accept:
      context.push(Routes.newLeadAcceptFor(conversation.id));
    case InboxQuickAction.assign:
      await assignConversation(context, ref, conversation);
    case InboxQuickAction.reject:
      await rejectConversation(context, ref, conversation);
  }
}

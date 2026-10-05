import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/view/widget/conversation_box_chips.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #141 WhatsApp and Messenger conversations in one list.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(threadListProvider);
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthMessagesTitle,
        subtitle: ref.watch(messagingAccountProvider),
        actions: const [GrowthLanguageAction()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ConversationBoxChips(
              box: ref.watch(threadBoxProvider),
              onChanged: ref.read(threadBoxProvider.notifier).set,
            ),
          ),
          Expanded(
            child: SrAsyncView(
              value: list,
              onRetry: () => ref.invalidate(threadListProvider),
              onUpgrade: () => context.push(Routes.planUsage),
              data: (context, paged) => GrowthPagedList<Conversation>(
                paged: paged,
                onLoadMore: () =>
                    ref.read(threadListProvider.notifier).loadMore(),
                onRefresh: () =>
                    ref.read(threadListProvider.notifier).refresh(),
                empty: SrEmptyState(
                  icon: Icons.forum_outlined,
                  title: l10n.growthMessagesEmpty,
                  message: l10n.growthMessagesEmptyBody,
                ),
                row: (thread) => _ThreadRow(thread: thread),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadRow extends ConsumerWidget {
  const _ThreadRow({required this.thread});

  final Conversation thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final last = thread.lastMessage ?? '';
    final preview = thread.lastMine ? l10n.growthMessagesYou(last) : last;
    final at = thread.lastAt;
    final unknown = thread.leadId == null && thread.companyId == null;
    return SrListRow(
      leading: SrAvatar(
        name: thread.name,
        tone: thread.unread > 0 ? SrAvatarTone.accent : SrAvatarTone.neutral,
      ),
      title: thread.name,
      subtitle: [
        thread.channel.label(l10n),
        if (unknown) l10n.growthMessagesUnknown,
        if (preview.isNotEmpty) preview,
      ].join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (at != null)
            Text(
              context.fmt.relative(at),
              style: AppText.meta(c.ink2, size: 12),
            ),
          const SizedBox(height: 4),
          ?_tag(context, ref, unknown: unknown),
        ],
      ),
      onTap: () => context.push(Routes.messageThreadFor(thread.id)),
    );
  }

  Widget? _tag(BuildContext context, WidgetRef ref, {required bool unknown}) {
    final l10n = context.l10n;
    if (thread.unread > 0) {
      return SrTag(context.fmt.number(thread.unread), tone: SrTone.accent);
    }
    if (unknown && thread.open) {
      return SrTag(l10n.growthMessagesNewLead, tone: SrTone.warn);
    }
    final assignee = thread.assignedTo;
    if (thread.isUnassigned || assignee == null) {
      return SrTag(l10n.growthInboxUnassigned, tone: SrTone.err);
    }
    if (thread.isMine(ref.watch(myMembershipIdProvider))) return null;
    return SrTag(assignee.split(' ').first);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/conversation_box_chips.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/features/growth/view/widget/inbox_actions.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #136 New enquiries from every channel, waiting to be taken.
class NewLeadsScreen extends ConsumerWidget {
  const NewLeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(inboxListProvider);
    final rules = ref.watch(moduleAccessProvider(AppModule.distribution));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthInboxTitle,
        actions: [
          const GrowthLanguageAction(),
          if (rules.visible)
            SrIconButton(
              icon: Icons.tune_rounded,
              tooltip: l10n.growthRulesTitle,
              onTap: () => context.push(Routes.distribution),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.only(top: 12), child: _BoxChips()),
          Expanded(
            child: SrAsyncView(
              value: list,
              onRetry: () => ref.invalidate(inboxListProvider),
              onUpgrade: () => context.push(Routes.planUsage),
              data: (context, paged) => GrowthPagedList<Conversation>(
                paged: paged,
                onLoadMore: () =>
                    ref.read(inboxListProvider.notifier).loadMore(),
                onRefresh: () => ref.read(inboxListProvider.notifier).refresh(),
                empty: const _Empty(),
                row: (conversation) => _InboxRow(conversation: conversation),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxChips extends ConsumerWidget {
  const _BoxChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ref.watch(inboxBoxProvider);
    return ConversationBoxChips(
      box: box,
      onChanged: ref.read(inboxBoxProvider.notifier).set,
    );
  }
}

class _InboxRow extends ConsumerWidget {
  const _InboxRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final at = conversation.lastAt;
    final canEdit = ref.watch(moduleAccessProvider(AppModule.inbox)).canEdit;
    return SrListRow(
      leading: SrAvatar(
        name: conversation.name,
        tone: conversation.isUnassigned
            ? SrAvatarTone.accent
            : SrAvatarTone.neutral,
      ),
      title: conversation.name,
      subtitle: [
        conversation.channel.label(l10n),
        ?conversation.lastMessage,
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
          InboxStatusTag(conversation: conversation),
        ],
      ),
      onTap: () => context.push(Routes.newLeadFor(conversation.id)),
      onLongPress: canEdit && conversation.open
          ? () => showInboxQuickActions(context, ref, conversation)
          : null,
    );
  }
}

/// New, who it is assigned to, or closed.
class InboxStatusTag extends StatelessWidget {
  const InboxStatusTag({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final assignee = conversation.assignedTo;
    if (!conversation.open) return SrTag(l10n.growthInboxClosedTag);
    if (conversation.isUnassigned) {
      return SrTag(l10n.growthInboxNewTag, tone: SrTone.ok);
    }
    return SrTag(l10n.growthInboxAssignedTag(assignee?.split(' ').first ?? ''));
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sources = ref.watch(moduleAccessProvider(AppModule.leadSources));
    return SrEmptyState(
      icon: Icons.move_to_inbox_outlined,
      title: l10n.growthInboxEmpty,
      message: l10n.growthInboxEmptyBody,
      actionLabel: sources.visible ? l10n.growthInboxConnectChannels : null,
      onAction: sources.visible
          ? () => context.push(Routes.growthChannels)
          : null,
    );
  }
}

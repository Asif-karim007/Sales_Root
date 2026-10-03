import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #141 WhatsApp, Messenger and SMS conversations in one list.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final account = ref.watch(messagingAccountProvider).value;
    final list = ref.watch(threadListProvider);
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthMessagesTitle,
        subtitle: account == null
            ? null
            : '${account.pageName} · ${growthPhone(context, account.number)}',
        actions: const [GrowthLanguageAction()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: _FilterChips(),
          ),
          Expanded(
            child: SrAsyncView(
              value: list,
              onRetry: () => ref.invalidate(threadListProvider),
              onUpgrade: () => context.push(Routes.planUsage),
              data: (context, paged) => GrowthClock(
                builder: (context) => GrowthPagedList<MessageThread>(
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
          ),
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
    final filter = ref.watch(threadFilterProvider);
    final counts = ref.watch(
      threadListProvider.select((list) => list.value?.facets['Counts']),
    );
    final filters = ThreadFilter.values;
    return SrChipRow(
      index: filters.indexOf(filter),
      onChanged: (i) => ref.read(threadFilterProvider.notifier).set(filters[i]),
      chips: [
        for (final f in filters)
          SrChipItem(
            switch (f) {
              ThreadFilter.all => l10n.commonAll,
              ThreadFilter.mine => l10n.growthInboxMine,
              ThreadFilter.unassigned => l10n.growthInboxUnassigned,
              ThreadFilter.whatsapp => l10n.growthSourceWhatsapp,
              ThreadFilter.messenger => l10n.growthSourceMessenger,
              ThreadFilter.sms => l10n.growthSourceSms,
            },
            count: counts?[f.wire],
            tone: f == ThreadFilter.unassigned ? SrTone.err : SrTone.neutral,
          ),
      ],
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread});

  final MessageThread thread;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final unknown = thread.kind == ThreadPartyKind.unknown;
    final last = thread.lastMessage ?? '';
    final preview = thread.lastMine ? l10n.growthMessagesYou(last) : last;
    return SrListRow(
      leading: unknown
          ? const SrAvatar(
              icon: Icons.question_mark_rounded,
              tone: SrAvatarTone.gold,
            )
          : SrAvatar(
              name: thread.name,
              tone: thread.unread > 0
                  ? SrAvatarTone.accent
                  : SrAvatarTone.neutral,
            ),
      title: unknown ? growthPhone(context, thread.name) : thread.name,
      subtitle: [
        thread.channel.label(l10n),
        if (unknown) l10n.growthMessagesUnknown,
        if (preview.isNotEmpty) preview,
      ].join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            growthAgo(context, thread.lastAgo()),
            style: AppText.meta(c.ink2, size: 12),
          ),
          const SizedBox(height: 4),
          ?_tag(context),
        ],
      ),
      onTap: () => context.push(Routes.messageThreadFor(thread.id)),
    );
  }

  Widget? _tag(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    if (thread.kind == ThreadPartyKind.unknown) {
      return SrTag(l10n.growthMessagesNewLead, tone: SrTone.warn);
    }
    if (thread.unread > 0) {
      return SrTag(fmt.number(thread.unread), tone: SrTone.accent);
    }
    final assignee = thread.assignedTo;
    if (assignee == null) {
      return SrTag(l10n.growthInboxUnassigned, tone: SrTone.err);
    }
    if (thread.assignedToMe) return null;
    return SrTag(assignee.of(fmt.isBangla).split(' ').first);
  }
}

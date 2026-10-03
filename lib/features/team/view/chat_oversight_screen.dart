import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/view/chat_list_screen.dart';
import 'package:salesroot/features/team/view/widget/chat_labels.dart';
import 'package:salesroot/features/team/view/widget/paged_list.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #80 `oversight`: every chat in the workspace, read as the owner.
class ChatOversightScreen extends ConsumerWidget {
  const ChatOversightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final threads = ref.watch(oversightListProvider);
    final notifier = ref.read(oversightListProvider.notifier);
    final header = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
        child: SrNote(tone: SrNoteTone.gold, message: l10n.teamOversightNote),
      ),
      const _ScopeChips(),
    ];
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.teamOversightTitle,
        subtitle: l10n.teamOversightSubtitle,
        actions: const [TeamLanguageToggle()],
      ),
      body: threads.when(
        data: (paged) => PagedCardList<ChatThread>(
          paged: paged,
          header: header,
          onLoadMore: notifier.loadMore,
          onRefresh: notifier.refresh,
          empty: SrEmptyState(
            icon: Icons.forum_outlined,
            title: l10n.teamChatEmptyTitle,
          ),
          itemBuilder: (context, thread) => ChatThreadRow(
            thread: thread,
            subtitle: _activity(context, thread),
          ),
        ),
        loading: () => ListView(
          padding: const EdgeInsets.only(top: 14),
          children: [...header, const SrSkeletonList(shrinkWrap: true)],
        ),
        error: (error, _) => ListView(
          padding: const EdgeInsets.only(top: 14),
          children: [
            ...header,
            SrErrorState(error: error, onRetry: notifier.refresh),
          ],
        ),
      ),
    );
  }

  /// "7 people · 42 messages today", "Direct · yesterday".
  String _activity(BuildContext context, ChatThread thread) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final who = switch (thread.kind) {
      ChatKind.group => l10n.teamPeople(
        thread.participants.length,
        fmt.number(thread.participants.length),
      ),
      ChatKind.direct => l10n.teamChatDirect,
      ChatKind.lead => context.peopleLine(thread),
    };
    final when = thread.messagesToday > 0
        ? l10n.teamChatMessagesToday(
            thread.messagesToday,
            fmt.number(thread.messagesToday),
          )
        : context.chatTime(thread.lastActivityAt);
    return [who, if (when.isNotEmpty) when].join(' · ');
  }
}

class _ScopeChips extends ConsumerWidget {
  const _ScopeChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scope = ref.watch(oversightScopeProvider);
    final counts = ref.watch(
      oversightListProvider.select(
        (list) =>
            list.value?.facets[OversightListNotifier.countsKey] ??
            const <String, int>{},
      ),
    );
    String label(ChatScope s) => switch (s) {
      ChatScope.all => l10n.teamOversightAll,
      ChatScope.group => l10n.teamOversightGroups,
      ChatScope.direct => l10n.teamOversightDirect,
      ChatScope.lead => l10n.teamOversightLeads,
    };
    return SrChipRow(
      chips: [
        for (final s in ChatScope.values)
          SrChipItem(label(s), count: counts[s.wire]),
      ],
      index: scope.index,
      onChanged: (i) =>
          ref.read(oversightScopeProvider.notifier).set(ChatScope.values[i]),
    );
  }
}

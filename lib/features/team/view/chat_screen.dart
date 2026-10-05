import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/models/chat_room.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/view/widget/chat_composer.dart';
import 'package:salesroot/features/team/view/widget/chat_labels.dart';
import 'package:salesroot/features/team/view/widget/external_links.dart';
import 'package:salesroot/features/team/view/widget/message_bubble.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #74 `groupchat`, #76 `leadchat` and #77 `dm`: one live thread.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.threadId});

  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thread = ref.watch(chatThreadProvider(threadId));
    final room = ref.watch(chatRoomProvider(threadId));
    final canWrite = ref.watch(
      moduleAccessProvider(AppModule.chat).select((a) => a.canAdd),
    );
    ref.listen(
      chatRoomProvider(threadId).select((room) => room.value?.failure),
      (_, failure) {
        if (failure == null) return;
        _showFailure(context, failure);
      },
    );
    final loaded = thread.value;
    return SrScaffold(
      appBar: _Header(thread: loaded),
      footer: loaded != null && loaded.isParticipant && canWrite
          ? ChatComposer(threadId: threadId)
          : null,
      body: switch (thread) {
        AsyncValue(hasValue: false, :final error?) => Center(
          child: SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(chatThreadProvider(threadId)),
          ),
        ),
        _ => _Messages(threadId: threadId, thread: loaded, room: room),
      },
    );
  }

  void _showFailure(BuildContext context, Object failure) {
    final l10n = context.l10n;
    if (failure is ApiFailure && failure.isQuota) {
      showSrSnack(
        context,
        l10n.teamStorageFull,
        title: l10n.planLockedTitle,
        tone: SrSnackTone.warning,
        action: SrSnackAction(
          label: l10n.planLockedAction,
          onPressed: () =>
              context.push('${Routes.planChoose}?reason=quota&kind=storage'),
        ),
      );
      return;
    }
    showSrError(
      context,
      failureText(context, failure),
      title: l10n.teamChatNotSent,
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.thread});

  final ChatThread? thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final thread = this.thread;
    if (thread == null) {
      return const SrAppBar(actions: [TeamLanguageToggle()]);
    }
    final phone = _phoneOf(context, thread, ref);
    return SrAppBar(
      titleWidget: InkWell(
        onTap: () => context.push(Routes.chatInfoFor(thread.id)),
        child: Row(
          children: [
            context.threadAvatar(thread, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.threadTitle(thread),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.pageTitle(c.ink, size: 16),
                  ),
                  Text(
                    _subtitle(context, thread),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta(c.ink2, size: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        const TeamLanguageToggle(),
        if (phone != null)
          SrIconButton(
            icon: Icons.call_outlined,
            tooltip: context.l10n.commonCall,
            onTap: () => openExternal(context, callUri(phone)),
          )
        else
          SrIconButton(
            icon: Icons.info_outline_rounded,
            tooltip: context.l10n.teamChatInfo,
            onTap: () => context.push(Routes.chatInfoFor(thread.id)),
          ),
      ],
    );
  }

  String? _phoneOf(BuildContext context, ChatThread thread, WidgetRef ref) {
    if (thread.kind == ChatKind.lead) return thread.lead?.contactPhone;
    final peer = context.peerOf(thread);
    if (thread.kind != ChatKind.direct ||
        !thread.isParticipant ||
        peer == null) {
      return null;
    }
    return ref
        .watch(chatPeopleProvider)
        .value
        ?.firstWhereOrNull((m) => m.id == peer.id)
        ?.phone;
  }

  String _subtitle(BuildContext context, ChatThread thread) {
    final l10n = context.l10n;
    return switch (thread.kind) {
      ChatKind.group => [
        l10n.teamPeople(
          thread.participants.length,
          context.fmt.number(thread.participants.length),
        ),
        l10n.teamChatOwnerCanRead,
      ].join(' · '),
      ChatKind.direct when !thread.isParticipant => l10n.teamChatDirect,
      ChatKind.direct => switch (context.peerOf(thread)) {
        final peer? => context.roleLabel(peer.role),
        null => l10n.teamChatDirect,
      },
      ChatKind.lead => context.peopleLine(thread),
    };
  }
}

class _Messages extends ConsumerWidget {
  const _Messages({
    required this.threadId,
    required this.thread,
    required this.room,
  });

  final String threadId;
  final ChatThread? thread;
  final AsyncValue<ChatRoom> room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thread = this.thread;
    final lead = thread?.lead;
    final banners = [
      if (thread != null && !thread.isParticipant)
        SrNote(tone: SrNoteTone.gold, message: context.l10n.teamOversightNote),
      if (lead != null) _LeadCard(lead: lead),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final banner in banners)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              12,
              SrMetrics.gutter,
              0,
            ),
            child: banner,
          ),
        Expanded(
          child: switch (room) {
            AsyncValue(:final ChatRoom value) => _MessageList(
              threadId: threadId,
              room: value,
              showSenders: thread?.kind != ChatKind.direct,
            ),
            AsyncError(:final error) => Center(
              child: SrErrorState(
                error: error,
                onRetry: () => ref.invalidate(chatRoomProvider(threadId)),
              ),
            ),
            _ => const SrSkeletonList(count: 5),
          },
        ),
      ],
    );
  }
}

/// Newest at the bottom; older pages load as the top comes into view.
class _MessageList extends ConsumerWidget {
  const _MessageList({
    required this.threadId,
    required this.room,
    required this.showSenders,
  });

  final String threadId;
  final ChatRoom room;
  final bool showSenders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final messages = room.messages;
    if (messages.isEmpty && room.typing.isEmpty) {
      return Center(
        child: SrEmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: l10n.teamChatStartTitle,
          message: l10n.teamChatStartBody,
        ),
      );
    }
    final entries = <Widget>[
      if (room.typing.isNotEmpty) _Typing(people: room.typing),
      for (var i = 0; i < messages.length; i++) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MessageBubble(message: messages[i], showSender: showSenders),
        ),
        if (_startsDay(messages, i)) _DayLabel(date: messages[i].sentAt),
      ],
      if (room.loadingOlder)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: SrSkeletonBox(height: 36, widthFactor: 0.5, radius: 14),
        ),
    ];
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 300 && room.hasOlder) {
          ref.read(chatRoomProvider(threadId).notifier).loadOlder();
        }
        return false;
      },
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.fromLTRB(
          SrMetrics.gutter,
          12,
          SrMetrics.gutter,
          12,
        ),
        itemCount: entries.length,
        itemBuilder: (context, i) => entries[i],
      ),
    );
  }

  /// Whether message [i] (newest first) is the first of its day.
  static bool _startsDay(List<ChatMessage> messages, int i) {
    final at = messages[i].sentAt;
    if (at == null) return false;
    if (i == messages.length - 1) return true;
    final older = messages[i + 1].sentAt;
    return older == null || !AppDateUtils.isSameDay(at, older);
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final date = this.date;
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final label = AppDateUtils.isSameDay(date, now)
        ? context.l10n.commonToday
        : AppDateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))
        ? context.l10n.commonYesterday
        : context.fmt.weekdayDate(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppText.meta(SrColors.of(context).ink3, size: 11),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing({required this.people});

  final List<ChatPerson> people;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final names = people
        .map((p) => context.name(p.name).split(' ').first)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.more_horiz_rounded, size: 18, color: c.accent),
          const SizedBox(width: 6),
          Text(
            context.l10n.teamChatTyping(names),
            style: AppText.meta(c.ink2, size: 12),
          ),
        ],
      ),
    );
  }
}

/// The lead a discussion is about, with a way to open it.
class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final ChatLead lead;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final stage = lead.stage;
    final owner = lead.ownerName;
    final line = [
      if (stage != null) context.name(stage),
      context.fmt.moneyCompact(lead.value),
      if (owner != null) context.name(owner),
    ].join(' · ');
    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SrAvatar(name: lead.title, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.rowTitle(c.ink),
                ),
                Text(line, style: AppText.meta(c.ink2, size: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SrButton(
            label: context.l10n.teamOpenLead,
            size: SrButtonSize.sm,
            variant: SrButtonVariant.secondary,
            onPressed: () => context.push(Routes.leadFor(lead.id)),
          ),
        ],
      ),
    );
  }
}

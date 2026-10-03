import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The conversation, newest at the bottom: who it is, the messages, a
/// suggested reply and the WhatsApp window.
class ThreadMessages extends ConsumerWidget {
  const ThreadMessages({
    super.key,
    required this.thread,
    required this.canReply,
    required this.onUseSuggestion,
  });

  final MessageThread thread;
  final bool canReply;
  final ValueChanged<String> onUseSuggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(threadMessagesProvider(thread.id));
    final suggestion = thread.suggestedReply;
    final bottom = <Widget>[
      if (thread.windowLeft() != null) _WindowNote(thread: thread),
      if (canReply && suggestion != null)
        _Suggestion(text: suggestion, onUse: () => onUseSuggestion(suggestion)),
    ];
    final body = switch (messages) {
      AsyncData(:final value) => [
        for (final message in value.reversed) _Bubble(message: message),
      ],
      AsyncError(:final error) => [
        SrErrorState(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(threadMessagesProvider(thread.id)),
        ),
      ],
      _ => [const SrSkeletonBox(height: 48), const SrSkeletonBox(height: 64)],
    };
    final children = [...bottom, ...body, ThreadHeader(thread: thread)];
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// Who the conversation is with, and a way into their record.
class ThreadHeader extends StatelessWidget {
  const ThreadHeader({super.key, required this.thread});

  final MessageThread thread;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final due = thread.dueAmount;
    final reference = thread.reference;
    final summary = [
      switch (thread.kind) {
        ThreadPartyKind.customer => l10n.growthMessagesCustomer,
        ThreadPartyKind.lead => l10n.growthMessagesLead,
        ThreadPartyKind.unknown => l10n.growthMessagesUnknown,
      },
      ?reference,
      if (due != null) l10n.growthMessagesDue(fmt.money(due)),
    ].join(' · ');
    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SrAvatar(name: thread.name, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thread.name, style: AppText.rowTitle(c.ink)),
                Text(summary, style: AppText.meta(c.ink2, size: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RecordButton(thread: thread),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.thread});

  final MessageThread thread;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final companyId = thread.companyId;
    final leadId = thread.leadId;
    final phone = thread.phone;
    final (label, route) = companyId != null
        ? (l10n.growthMessagesCustomer, Routes.customerFor(companyId))
        : leadId != null
        ? (l10n.growthMessagesLead, Routes.leadFor(leadId))
        : (
            l10n.growthMessagesCreateLead,
            Uri(
              path: Routes.leadNew,
              queryParameters: {
                if (thread.kind != ThreadPartyKind.unknown) 'name': thread.name,
                'phone': ?phone,
                'source': thread.channel.wire,
              },
            ).toString(),
          );
    return SrButton(
      label: label,
      size: SrButtonSize.sm,
      variant: SrButtonVariant.secondary,
      onPressed: () => context.push(route),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ThreadMessage message;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final at = message.at;
    final attachment = message.attachment;
    return SrChatBubble(
      text: message.text,
      mine: message.mine,
      time: at == null ? null : fmt.time(at),
      trailing: message.mine
          ? Icon(
              message.status == DeliveryStatus.sent
                  ? Icons.done_rounded
                  : Icons.done_all_rounded,
              size: 14,
              color: message.status == DeliveryStatus.read ? c.accent2 : c.ink3,
            )
          : null,
      media: attachment == null
          ? null
          : SrBubbleMedia(
              icon: Icons.picture_as_pdf_outlined,
              height: 56,
              child: Text(
                [
                  attachment.name,
                  if (attachment.amount case final amount?) fmt.money(amount),
                  l10n.growthMessagesPdf,
                ].join(' · '),
                style: AppText.meta(c.ink, size: 12),
              ),
            ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.text, required this.onUse});

  final String text;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return SrCard(
      tone: SrCardTone.gold,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: c.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.growthMessagesSuggested(text),
              style: AppText.meta(c.ink, size: 12),
            ),
          ),
          const SizedBox(width: 8),
          SrButton(
            label: l10n.growthMessagesUse,
            size: SrButtonSize.sm,
            variant: SrButtonVariant.secondary,
            onPressed: onUse,
          ),
        ],
      ),
    );
  }
}

class _WindowNote extends StatelessWidget {
  const _WindowNote({required this.thread});

  final MessageThread thread;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final left = thread.windowLeft() ?? Duration.zero;
    if (left == Duration.zero) {
      return SrNote(
        tone: SrNoteTone.err,
        icon: Icons.lock_clock_outlined,
        message: l10n.growthMessagesWindowClosed,
      );
    }
    final until = DateTime.now().add(left);
    return SrNote(
      tone: SrNoteTone.gold,
      icon: Icons.schedule_rounded,
      message: l10n.growthMessagesWindowOpen(context.fmt.dayTime(until)),
    );
  }
}

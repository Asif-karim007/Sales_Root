import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The conversation, newest at the bottom: who it is, the messages and an
/// AI-suggested reply.
class ThreadMessages extends ConsumerWidget {
  const ThreadMessages({
    super.key,
    required this.thread,
    required this.canReply,
    required this.onUseSuggestion,
  });

  final Conversation thread;
  final bool canReply;
  final ValueChanged<String> onUseSuggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = canReply && thread.open
        ? ref.watch(replyDraftProvider(thread.id)).value
        : null;
    final children = [
      if (suggestion != null)
        _Suggestion(text: suggestion, onUse: () => onUseSuggestion(suggestion)),
      for (final message in thread.messages.reversed) _Bubble(message: message),
      ThreadHeader(thread: thread),
    ];
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

  final Conversation thread;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final kind = thread.companyId != null
        ? l10n.growthMessagesCustomer
        : thread.leadId != null
        ? l10n.growthMessagesLead
        : l10n.growthMessagesUnknown;
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
                Text(kind, style: AppText.meta(c.ink2, size: 12)),
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

  final Conversation thread;

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
                'name': thread.name,
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

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final at = message.at;
    return SrChatBubble(
      text: message.text,
      mine: message.mine,
      time: at == null ? null : context.fmt.time(at),
      trailing: message.mine
          ? Icon(
              switch (message.status) {
                DeliveryStatus.sent => Icons.done_rounded,
                DeliveryStatus.failed => Icons.error_outline_rounded,
                _ => Icons.done_all_rounded,
              },
              size: 14,
              color: switch (message.status) {
                DeliveryStatus.read => c.accent2,
                DeliveryStatus.failed => c.danger,
                _ => c.ink3,
              },
            )
          : null,
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

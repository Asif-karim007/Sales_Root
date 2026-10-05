import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/features/support/providers/ticket_providers.dart';
import 'package:salesroot/features/support/view/widget/attachment_picker.dart';
import 'package:salesroot/features/support/view/widget/support_failure.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/features/support/view/widget/support_rows.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #111 a conversation with support.
class SupportTicketScreen extends ConsumerStatefulWidget {
  const SupportTicketScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<SupportTicketScreen> createState() =>
      _SupportTicketScreenState();
}

class _SupportTicketScreenState extends ConsumerState<SupportTicketScreen> {
  final _reply = TextEditingController();
  final _replyFocus = FocusNode();
  final _scroll = ScrollController();
  SupportAttachment? _attachment;

  @override
  void initState() {
    super.initState();
    _reply.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reply.dispose();
    _replyFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  });

  Future<void> _attach() async {
    try {
      final picked = await pickSupportAttachment(AttachmentKind.image);
      if (!mounted || picked == null) return;
      setState(() => _attachment = picked);
    } on PlatformException {
      if (!mounted) return;
      showSrError(context, context.l10n.supportPickFailed);
    }
  }

  Future<void> _send() async {
    final attachment = _attachment;
    final sent = await ref
        .read(supportTicketProvider(widget.id).notifier)
        .send(_reply.text, attachments: [?attachment]);
    if (!sent || !mounted) return;
    _reply.clear();
    setState(() => _attachment = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = supportTicketProvider(widget.id);
    final thread = ref.watch(provider);
    final canReply = ref.watch(
      moduleAccessProvider(AppModule.support).select((a) => a.canAdd),
    );
    ref.listen(provider, (previous, next) {
      final failure = next.value?.failure;
      if (failure != null) {
        showSrError(context, supportFailureText(context, failure));
      }
      final before = previous?.value?.ticket.messages.length ?? 0;
      final after = next.value?.ticket.messages.length ?? 0;
      if (after != before) _toBottom();
    });
    final loaded = thread.value;
    final agent = loaded?.ticket.agentName;

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.supportTicketTitle,
          subtitle: agent == null
              ? l10n.supportTicketTeam
              : l10n.supportTicketAgent(agent),
          actions: const [SupportLanguagePill()],
        ),
        footer: loaded == null || !canReply
            ? null
            : _Composer(
                controller: _reply,
                focusNode: _replyFocus,
                attachment: _attachment,
                sending: loaded.sending,
                onAttach: _attach,
                onRemoveAttachment: () => setState(() => _attachment = null),
                onSend: _send,
              ),
        body: SrAsyncView(
          value: thread,
          loading: (_) => const SrSkeletonList(cards: true, count: 4),
          onRetry: () => ref.invalidate(provider),
          data: (_, thread) =>
              _Conversation(ticket: thread.ticket, controller: _scroll),
        ),
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation({required this.ticket, required this.controller});

  final SupportTicket ticket;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(SrMetrics.gutter),
      children: [
        _TicketHeader(ticket: ticket),
        const SizedBox(height: 14),
        for (final message in ticket.messages) ...[
          _MessageBubble(message: message),
          const SizedBox(height: 10),
        ],
        if (ticket.isResolved)
          SrNote(
            message: l10n.supportTicketResolvedNote,
            icon: Icons.check_circle_outline_rounded,
          ),
      ],
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final tone = switch (ticket.status) {
      TicketStatus.open => SrTone.warn,
      TicketStatus.replied => SrTone.ok,
      TicketStatus.resolved => SrTone.neutral,
    };
    final status = l10n.ticketStatus(ticket.status);
    final within = ticket.replyWithinHours;

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const SrAvatar(
            icon: Icons.support_agent_rounded,
            tone: SrAvatarTone.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.supportTicketHeading(ticket.number, ticket.subject),
                  style: AppText.rowTitle(c.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    l10n.ticketCategory(ticket.category),
                    status,
                    if (!ticket.isResolved && within != null)
                      l10n.supportTicketReplyWithin(fmt.number(within)),
                  ].join(' · '),
                  style: AppText.meta(c.ink2, size: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SrTag(status, tone: tone),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final sentAt = message.sentAt;
    final attachments = message.attachments;

    return SrChatBubble(
      text: message.body,
      mine: !message.fromAgent,
      sender: message.fromAgent ? message.authorName : null,
      time: sentAt == null ? null : context.fmt.dayTime(sentAt),
      media: attachments.isEmpty
          ? null
          : SrBubbleMedia(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    attachments.first.kind == AttachmentKind.video
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                    size: 18,
                    color: c.ink2,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      attachments.map((a) => a.name).join(', '),
                      style: AppText.meta(c.ink2, size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.attachment,
    required this.sending,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SupportAttachment? attachment;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attachment = this.attachment;
    final canSend =
        !sending && (controller.text.trim().isNotEmpty || attachment != null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attachment != null) ...[
          SupportAttachmentChip(
            name: attachment.name,
            icon: Icons.image_outlined,
            removeLabel: l10n.supportRemoveAttachment,
            onRemove: onRemoveAttachment,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            SrIconButton(
              icon: Icons.attach_file_rounded,
              tooltip: l10n.supportTicketAttach,
              onTap: sending ? null : onAttach,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SrTextField(
                controller: controller,
                focusNode: focusNode,
                hint: l10n.supportTicketReplyHint,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: canSend ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: 6),
            SrIconButton(
              icon: Icons.send_rounded,
              color: SrColors.of(context).accent,
              tooltip: l10n.commonSend,
              onTap: canSend ? onSend : null,
            ),
          ],
        ),
      ],
    );
  }
}

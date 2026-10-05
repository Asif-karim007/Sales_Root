import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Type or pick a template, send. An approved WhatsApp template goes out as
/// one, so it also reaches people outside the 24-hour window.
class ThreadComposer extends ConsumerStatefulWidget {
  const ThreadComposer({
    super.key,
    required this.thread,
    required this.controller,
  });

  final Conversation thread;
  final TextEditingController controller;

  @override
  ConsumerState<ThreadComposer> createState() => _ThreadComposerState();
}

class _ThreadComposerState extends ConsumerState<ThreadComposer> {
  bool _sending = false;

  Conversation get _thread => widget.thread;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: SrTextField(
            controller: widget.controller,
            hint: l10n.growthMessagesReplyOn(_thread.channel.label(l10n)),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendText(),
          ),
        ),
        const SizedBox(width: 4),
        SrIconButton(
          icon: Icons.bolt_rounded,
          tooltip: l10n.growthMessagesTemplates,
          onTap: _sending ? null : _templates,
        ),
        SrIconButton(
          icon: Icons.send_rounded,
          tooltip: l10n.commonSend,
          onTap: _sending ? null : _sendText,
        ),
      ],
    );
  }

  Future<void> _sendText() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    final sent = await _send(ReplyInput(text: text));
    if (sent) widget.controller.clear();
  }

  Future<bool> _send(ReplyInput input) async {
    if (_sending) return false;
    setState(() => _sending = true);
    try {
      await ref.read(inboxActionsProvider.notifier).reply(_thread.id, input);
      return true;
    } catch (error) {
      if (mounted) showSrError(context, growthFailureText(context, error));
      return false;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _templates() async {
    final l10n = context.l10n;
    final templates = await runGrowthAction(
      context,
      ref.read(messageTemplatesProvider(_thread.channel.wire).future),
    );
    if (templates == null || !mounted) return;
    final picked = await showSrSheet<MessageTemplate>(
      context: context,
      builder: (_) => SrOptionSheet<MessageTemplate>(
        title: l10n.growthMessagesTemplates,
        options: templates,
        labelOf: (t) => t.name,
        subtitleOf: (t) =>
            t.approved ? l10n.growthMessagesApproved(_fill(t)) : _fill(t),
        isSelected: (_) => false,
      ),
    );
    if (picked == null || !mounted) return;
    if (picked.approved && _thread.channel == ConversationChannel.whatsapp) {
      await _send(ReplyInput(templateName: picked.name, params: [_firstName]));
      return;
    }
    widget.controller.text = _fill(picked);
  }

  String get _firstName => _thread.name.split(' ').first;

  String _fill(MessageTemplate template) =>
      template.body.replaceAll('{{name}}', _firstName).replaceAll('  ', ' ');
}

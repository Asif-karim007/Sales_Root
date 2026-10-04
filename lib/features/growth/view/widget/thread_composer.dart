import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Attach, type or pick a template, send. Once WhatsApp's 24-hour window
/// closes only approved templates can go out.
class ThreadComposer extends ConsumerStatefulWidget {
  const ThreadComposer({
    super.key,
    required this.thread,
    required this.controller,
  });

  final MessageThread thread;
  final TextEditingController controller;

  @override
  ConsumerState<ThreadComposer> createState() => _ThreadComposerState();
}

enum _Attachment { quotation, priceList }

class _ThreadComposerState extends ConsumerState<ThreadComposer> {
  bool _sending = false;

  MessageThread get _thread => widget.thread;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locked = _thread.needsTemplate;
    return Row(
      children: [
        SrIconButton(
          icon: Icons.attach_file_rounded,
          tooltip: l10n.growthMessagesAttach,
          onTap: _sending ? null : _attach,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SrTextField(
            controller: widget.controller,
            hint: locked
                ? l10n.growthMessagesPickTemplate
                : l10n.growthMessagesReplyOn(_thread.channel.label(l10n)),
            readOnly: locked,
            onTap: locked ? _templates : null,
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
          onTap: _sending || locked ? null : _sendText,
        ),
      ],
    );
  }

  Future<void> _sendText() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    final sent = await _send(SendMessageInput(text: text));
    if (sent) widget.controller.clear();
  }

  Future<bool> _send(SendMessageInput input) async {
    if (_sending) return false;
    setState(() => _sending = true);
    try {
      await ref.read(messageActionsProvider.notifier).send(_thread.id, input);
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
    final bangla = context.fmt.isBangla;
    final locked = _thread.needsTemplate;
    final all = await runGrowthAction(
      context,
      ref.read(messageTemplatesProvider.future),
    );
    if (all == null || !mounted) return;
    final options = locked ? all.where((t) => t.approved).toList() : all;
    final picked = await showSrSheet<MessageTemplate>(
      context: context,
      builder: (_) => SrOptionSheet<MessageTemplate>(
        title: l10n.growthMessagesTemplates,
        options: options,
        labelOf: (t) => t.name.of(bangla),
        subtitleOf: (t) =>
            t.approved ? l10n.growthMessagesApproved(_fill(t)) : _fill(t),
        isSelected: (_) => false,
      ),
    );
    if (picked == null || !mounted) return;
    if (locked) {
      await _send(SendMessageInput(text: _fill(picked), templateId: picked.id));
      return;
    }
    widget.controller.text = _fill(picked);
  }

  String _fill(MessageTemplate template) {
    final first = _thread.kind == ThreadPartyKind.unknown
        ? ''
        : _thread.name.split(' ').first;
    return template.body
        .of(context.fmt.isBangla)
        .replaceAll('{{name}}', first)
        .replaceAll('  ', ' ');
  }

  Future<void> _attach() async {
    final l10n = context.l10n;
    final picked = await showSrSheet<_Attachment>(
      context: context,
      builder: (context) => SrSheet(
        title: l10n.growthMessagesAttach,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SrListRow(
              leading: const Icon(Icons.request_quote_outlined),
              title: l10n.growthMessagesAttachQuotation,
              subtitle: l10n.growthMessagesAttachQuotationHint,
              chevron: true,
              onTap: () => Navigator.of(context).pop(_Attachment.quotation),
            ),
            SrListRow(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: l10n.growthMessagesAttachPriceList,
              subtitle: l10n.growthMessagesAttachPriceListHint,
              onTap: () => Navigator.of(context).pop(_Attachment.priceList),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case _Attachment.quotation:
        context.push(Routes.quotations);
      case _Attachment.priceList:
        await _send(
          const SendMessageInput(
            attachment: MessageAttachment(
              kind: AttachmentKind.priceList,
              name: 'Dealer_price_list_Oct_2026',
            ),
          ),
        );
    }
  }
}

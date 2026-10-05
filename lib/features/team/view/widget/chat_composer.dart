import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/view/widget/attach_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Attach, type and send, under an open thread.
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    _text.clear();
    ref
        .read(chatRoomProvider(widget.threadId).notifier)
        .send(MessageInput(text: text));
  }

  Future<void> _attach() async {
    final attachment = await pickAttachment(context, ref);
    if (attachment == null || !mounted) return;
    final caption = _text.text.trim();
    _text.clear();
    await ref
        .read(chatRoomProvider(widget.threadId).notifier)
        .send(MessageInput(text: caption, attachment: attachment));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        SrIconButton(
          icon: Icons.attach_file_rounded,
          tooltip: l10n.teamAttachTitle,
          onTap: _attach,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SrTextField(
            controller: _text,
            hint: l10n.teamChatWrite,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),
        SrFab(
          icon: Icons.send_rounded,
          size: 46,
          tooltip: l10n.commonSend,
          onTap: _send,
        ),
      ],
    );
  }
}

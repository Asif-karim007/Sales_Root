import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

extension ChatLabels on BuildContext {
  ChatPerson? peerOf(ChatThread thread) =>
      thread.participants.firstWhereOrNull((p) => !p.isMe);

  String _firstName(ChatPerson person) => name(person.name).split(' ').first;

  /// "Dhaka Sales · everyone", "Rumpa Sarker", "Lead: Karim Textiles", or
  /// "Rumpa ↔ Bushra" for someone else's direct chat.
  String threadTitle(ChatThread thread) => switch (thread.kind) {
    ChatKind.group when thread.isEveryone => l10n.teamChatEveryone(
      thread.title,
    ),
    ChatKind.group => thread.title,
    ChatKind.direct when !thread.isParticipant =>
      thread.participants.map(_firstName).join(' ↔ '),
    ChatKind.direct => switch (peerOf(thread)) {
      final peer? => name(peer.name),
      null => l10n.teamChatDirect,
    },
    ChatKind.lead => l10n.teamChatLeadTitle(thread.lead?.title ?? ''),
  };

  /// "You, Rafiqul" for the people in a lead thread.
  String peopleLine(ChatThread thread) => [
    for (final p in thread.participants)
      p.isMe ? l10n.teamChatYou : _firstName(p),
  ].join(', ');

  SrAvatar threadAvatar(ChatThread thread, {double size = 38}) {
    final title = switch (thread.kind) {
      ChatKind.lead => thread.lead?.title ?? '',
      ChatKind.group => thread.title,
      ChatKind.direct when !thread.isParticipant =>
        switch (thread.participants.firstOrNull) {
          final first? => name(first.name),
          null => '',
        },
      _ => threadTitle(thread),
    };
    return SrAvatar(
      name: avatarName(title),
      size: size,
      tone: switch (thread.kind) {
        ChatKind.group when thread.isEveryone => SrAvatarTone.dark,
        ChatKind.group => SrAvatarTone.accent,
        ChatKind.lead => SrAvatarTone.gold,
        ChatKind.direct => SrAvatarTone.neutral,
      },
    );
  }

  String attachmentLabel(AttachmentKind kind) => switch (kind) {
    AttachmentKind.photo => l10n.teamAttachPhoto,
    AttachmentKind.file => l10n.teamAttachFile,
    AttachmentKind.teamFile => l10n.teamAttachTeamFile,
    AttachmentKind.lead => l10n.teamAttachLead,
    AttachmentKind.quotation => l10n.teamAttachQuotation,
    AttachmentKind.location => l10n.teamAttachLocation,
    AttachmentKind.contact => l10n.teamAttachContact,
  };

  IconData attachmentIcon(AttachmentKind kind) => switch (kind) {
    AttachmentKind.photo => Icons.image_outlined,
    AttachmentKind.file => Icons.insert_drive_file_outlined,
    AttachmentKind.teamFile => Icons.folder_shared_outlined,
    AttachmentKind.lead => Icons.work_outline_rounded,
    AttachmentKind.quotation => Icons.request_quote_outlined,
    AttachmentKind.location => Icons.location_on_outlined,
    AttachmentKind.contact => Icons.person_outline_rounded,
  };

  /// "Rafiq: meeting tomorrow", "You: sent quotation v2".
  String previewLine(ChatThread thread) {
    final preview = thread.lastMessage;
    if (preview == null) return l10n.teamChatNoMessages;
    final kind = preview.attachment;
    final text = preview.text.isNotEmpty
        ? preview.text
        : kind == null
        ? ''
        : attachmentLabel(kind);
    if (preview.isMine) return l10n.teamChatYouSaid(text);
    if (thread.kind == ChatKind.direct) return text;
    final sender = name(preview.senderName).split(' ').first;
    return l10n.teamChatSaid(sender, text);
  }

  /// 10:12 today, "Yesterday", else the date.
  String chatTime(DateTime? at) {
    if (at == null) return '';
    final now = DateTime.now();
    if (AppDateUtils.isSameDay(at, now)) return fmt.time(at);
    if (AppDateUtils.isSameDay(at, now.subtract(const Duration(days: 1)))) {
      return l10n.commonYesterday;
    }
    return fmt.dayMonth(at);
  }
}

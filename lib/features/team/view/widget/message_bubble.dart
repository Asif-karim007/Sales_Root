import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/view/widget/chat_labels.dart';
import 'package:salesroot/features/team/view/widget/external_links.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// One message: the bubble, what it carries and, for mine, its delivery
/// state. A failed one offers to try again.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.showSender,
  });

  final ChatMessage message;
  final bool showSender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachment = message.attachment;
    final text = message.text.isNotEmpty || attachment == null
        ? message.text
        : context.attachmentLabel(attachment.kind);
    final sentAt = message.sentAt;
    final bubble = SrChatBubble(
      text: text,
      mine: message.isMine,
      sender: showSender && !message.isMine
          ? context.name(message.senderName)
          : null,
      time: sentAt == null ? null : context.fmt.time(sentAt),
      media: attachment == null
          ? null
          : AttachmentMedia(message: message, attachment: attachment),
      trailing: message.isMine ? _StatusIcon(status: message.status) : null,
      onLongPress: message.text.isEmpty
          ? null
          : () => copyText(context, message.text),
    );
    if (message.status != MessageStatus.failed) return bubble;
    return GestureDetector(onTap: () => _failed(context, ref), child: bubble);
  }

  Future<void> _failed(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final retry = await showSrSheet<bool>(
      context: context,
      builder: (context) => SrSheet(
        title: l10n.teamChatNotSent,
        child: SrRowGroup(
          rows: [
            SrListRow(
              title: l10n.commonRetry,
              leading: const SrAvatar(
                icon: Icons.refresh_rounded,
                tone: SrAvatarTone.accent,
              ),
              onTap: () => Navigator.of(context).pop(true),
            ),
            SrListRow(
              title: l10n.commonDelete,
              leading: const SrAvatar(
                icon: Icons.delete_outline_rounded,
                tone: SrAvatarTone.danger,
              ),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
    if (retry == null) return;
    final room = ref.read(chatRoomProvider(message.threadId).notifier);
    retry ? await room.retry(message) : room.discard(message);
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final (icon, color) = switch (status) {
      MessageStatus.sending => (Icons.schedule_rounded, c.ink3),
      MessageStatus.sent => (Icons.check_rounded, c.ink3),
      MessageStatus.delivered => (Icons.done_all_rounded, c.ink3),
      MessageStatus.read => (Icons.done_all_rounded, c.accent),
      MessageStatus.failed => (Icons.error_outline_rounded, c.danger),
    };
    return Icon(icon, size: 14, color: color);
  }
}

/// What a message carries: a photo, or a card for a file, record or place.
class AttachmentMedia extends ConsumerWidget {
  const AttachmentMedia({
    super.key,
    required this.message,
    required this.attachment,
  });

  final ChatMessage message;
  final Attachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = attachment.localPath;
    if (attachment.kind == AttachmentKind.photo) {
      return SrBubbleMedia(
        height: 140,
        onTap: () => _view(context, ref),
        child: path == null
            ? null
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                width: 220,
                height: 140,
                errorBuilder: (_, _, _) => Icon(
                  Icons.image_outlined,
                  color: SrColors.of(context).ink3,
                ),
              ),
      );
    }
    return SrBubbleMedia(
      height: 60,
      onTap: () => _open(context, ref),
      child: _RefCard(
        icon: context.attachmentIcon(attachment.kind),
        title: attachment.title,
        subtitle: _subtitle(context),
      ),
    );
  }

  String? _subtitle(BuildContext context) {
    final amount = attachment.amount;
    final size = attachment.sizeBytes;
    return switch (attachment.kind) {
      AttachmentKind.quotation when amount != null => context.fmt.money(amount),
      AttachmentKind.file ||
      AttachmentKind.teamFile when size != null => context.fileSize(size),
      AttachmentKind.location => context.l10n.teamOpenMap,
      _ => attachment.subtitle,
    };
  }

  void _open(BuildContext context, WidgetRef ref) {
    final refId = attachment.refId;
    final leadId = attachment.leadId;
    final lat = attachment.lat;
    final lng = attachment.lng;
    switch (attachment.kind) {
      case AttachmentKind.teamFile when refId != null:
        context.push(Routes.fileFor(refId));
      case AttachmentKind.lead || AttachmentKind.quotation when leadId != null:
        context.push(Routes.leadFor(leadId));
      case AttachmentKind.contact when refId != null:
        context.push(Routes.contactFor(refId));
      case AttachmentKind.location when lat != null && lng != null:
        openExternal(context, mapUri(lat, lng));
      case AttachmentKind.file || AttachmentKind.photo:
        _view(context, ref);
      default:
    }
  }

  void _view(BuildContext context, WidgetRef ref) {
    final path = attachment.localPath;
    final repository = ref.read(chatRepositoryProvider);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SrFileViewer(
          name: attachment.title,
          kind: srFileKindOf(attachment.title),
          title: context.attachmentLabel(attachment.kind),
          meta: switch (attachment.sizeBytes) {
            final size? => context.fileSize(size),
            null => '',
          },
          load: () => message.id < 0 && path != null
              ? File(path).readAsBytes()
              : repository.attachmentBytes(message.id),
        ),
      ),
    );
  }
}

class _RefCard extends StatelessWidget {
  const _RefCard({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final subtitle = this.subtitle;
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.rowTitle(c.ink, size: 12.5),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta(c.ink2, size: 11.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/features/support/models/support_ticket.dart';

/// Picks a screenshot or a screen recording from the gallery; null when the
/// user cancels. Throws [PlatformException] when access is denied.
Future<SupportAttachment?> pickSupportAttachment(AttachmentKind kind) async {
  final picker = ImagePicker();
  final file = switch (kind) {
    AttachmentKind.image => await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    ),
    AttachmentKind.video => await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    ),
  };
  if (file == null) return null;
  return SupportAttachment(
    path: file.path,
    name: file.name,
    kind: kind,
    size: await file.length(),
  );
}

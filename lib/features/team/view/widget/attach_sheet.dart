import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/models/team_file.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/providers/files_providers.dart';
import 'package:salesroot/features/team/view/widget/chat_labels.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

enum AttachOption {
  camera,
  gallery,
  file,
  teamFile,
  lead,
  quotation,
  location,
  contact,
}

/// #75 `attachsheet`: asks what to attach, then picks it. Null when the
/// user backs out or the pick fails (they are told why).
Future<Attachment?> pickAttachment(BuildContext context, WidgetRef ref) async {
  final option = await showSrSheet<AttachOption>(
    context: context,
    builder: (_) => const _AttachSheet(),
  );
  if (option == null || !context.mounted) return null;
  try {
    switch (option) {
      case AttachOption.camera:
        return await _photo(ImageSource.camera);
      case AttachOption.gallery:
        return await _photo(ImageSource.gallery);
      case AttachOption.file:
        return await _file();
      case AttachOption.teamFile:
        return await _teamFile(context, ref);
      case AttachOption.lead:
        return await _record(context, ref, AttachmentKind.lead);
      case AttachOption.quotation:
        return await _record(context, ref, AttachmentKind.quotation);
      case AttachOption.contact:
        return await _record(context, ref, AttachmentKind.contact);
      case AttachOption.location:
        return await _location(context);
    }
  } on Exception {
    if (context.mounted) showSrError(context, context.l10n.teamPickFailed);
    return null;
  }
}

/// Picks a photo with the camera or from the gallery.
Future<LocalFile?> pickPhoto(ImageSource source) async {
  final photo = await ImagePicker().pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: 2048,
  );
  if (photo == null) return null;
  return LocalFile(
    path: photo.path,
    name: photo.name,
    sizeBytes: await photo.length(),
  );
}

/// Picks a document from the phone.
Future<LocalFile?> pickDocument() async {
  final picked = await FilePicker.pickFile();
  final path = picked?.path;
  if (picked == null || path == null) return null;
  return LocalFile(
    path: path,
    name: picked.name,
    sizeBytes: await picked.length() ?? 0,
  );
}

Future<Attachment?> _photo(ImageSource source) async {
  final photo = await pickPhoto(source);
  if (photo == null) return null;
  return Attachment(
    kind: AttachmentKind.photo,
    title: photo.name,
    sizeBytes: photo.sizeBytes,
    localPath: photo.path,
  );
}

Future<Attachment?> _file() async {
  final file = await pickDocument();
  if (file == null) return null;
  return Attachment(
    kind: AttachmentKind.file,
    title: file.name,
    sizeBytes: file.sizeBytes,
    localPath: file.path,
  );
}

Future<Attachment?> _teamFile(BuildContext context, WidgetRef ref) async {
  final repository = ref.read(filesRepositoryProvider);
  final file = await showSrSheet<TeamFile>(
    context: context,
    builder: (context) => SrSearchSheet<TeamFile>(
      title: context.l10n.teamAttachTeamFile,
      searchHint: context.l10n.teamFilesSearch,
      search: (term, page) async =>
          (await repository.files(FileQuery(search: term, page: page))).items,
      labelOf: (file) => file.name,
      subtitleOf: (file) => context.fileSize(file.sizeBytes),
      isSelected: (_) => false,
    ),
  );
  if (file == null) return null;
  return Attachment(
    kind: AttachmentKind.teamFile,
    title: file.name,
    refId: file.id,
    sizeBytes: file.sizeBytes,
  );
}

Future<Attachment?> _record(
  BuildContext context,
  WidgetRef ref,
  AttachmentKind kind,
) async {
  final repository = ref.read(chatRepositoryProvider);
  final picked = await showSrSheet<ChatRef>(
    context: context,
    builder: (context) => SrSearchSheet<ChatRef>(
      title: context.attachmentLabel(kind),
      searchHint: context.l10n.commonSearch,
      search: (term, page) async =>
          (await repository.attachables(kind, term, page)).items,
      labelOf: (ref) => ref.title,
      subtitleOf: (ref) => ref.subtitle,
      withAvatar: kind == AttachmentKind.contact,
      isSelected: (_) => false,
    ),
  );
  if (picked == null) return null;
  return Attachment(
    kind: kind,
    title: picked.title,
    subtitle: picked.subtitle,
    refId: picked.id,
    leadId: picked.leadId,
    amount: picked.amount,
  );
}

Future<Attachment?> _location(BuildContext context) async {
  final l10n = context.l10n;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  final allowed =
      permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
  if (!allowed || !await Geolocator.isLocationServiceEnabled()) {
    if (context.mounted) showSrError(context, l10n.teamLocationDenied);
    return null;
  }
  if (!context.mounted) return null;
  final position = await showSrLoader(
    context,
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    ),
  );
  return Attachment(
    kind: AttachmentKind.location,
    title: l10n.teamMyLocation,
    lat: position.latitude,
    lng: position.longitude,
  );
}

class _AttachSheet extends ConsumerWidget {
  const _AttachSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plan = ref.watch(planProvider).value;
    const options = AttachOption.values;
    return SrSheet(
      title: l10n.teamAttachTitle,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < options.length; row += 4) ...[
              if (row > 0) const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = row; i < row + 4; i++) ...[
                    if (i > row) const SizedBox(width: 8),
                    Expanded(child: _Tile(option: options[i])),
                  ],
                ],
              ),
            ],
            if (plan != null) ...[
              const SizedBox(height: 14),
              SrNote(
                message: l10n.teamStorageNote(
                  context.gigabytes(plan.storageUsedGb),
                  context.gigabytes(plan.storageGb),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.option});

  final AttachOption option;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final (icon, label) = switch (option) {
      AttachOption.camera => (
        Icons.photo_camera_outlined,
        l10n.teamAttachCamera,
      ),
      AttachOption.gallery => (
        Icons.photo_library_outlined,
        l10n.teamAttachGallery,
      ),
      AttachOption.file => (
        Icons.insert_drive_file_outlined,
        l10n.teamAttachFile,
      ),
      AttachOption.teamFile => (
        Icons.folder_shared_outlined,
        l10n.teamAttachTeamFile,
      ),
      AttachOption.lead => (Icons.work_outline_rounded, l10n.teamAttachLead),
      AttachOption.quotation => (
        Icons.request_quote_outlined,
        l10n.teamAttachQuotation,
      ),
      AttachOption.location => (
        Icons.location_on_outlined,
        l10n.teamAttachLocation,
      ),
      AttachOption.contact => (
        Icons.person_outline_rounded,
        l10n.teamAttachContact,
      ),
    };
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        onTap: () => Navigator.of(context).pop(option),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, size: 24, color: c.accent),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowTitle(c.ink, size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

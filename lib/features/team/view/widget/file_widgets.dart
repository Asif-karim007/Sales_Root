import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/team/models/team_file.dart';
import 'package:salesroot/features/team/providers/files_providers.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

IconData fileIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
  if (srFileKindOf(lower) == SrFileKind.image) return Icons.image_outlined;
  if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
    return Icons.table_chart_outlined;
  }
  return Icons.description_outlined;
}

SrAvatarTone fileTone(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.docx') || lower.endsWith('.doc')) {
    return SrAvatarTone.gold;
  }
  return lower.endsWith('.pdf') ? SrAvatarTone.accent : SrAvatarTone.neutral;
}

/// A file in a list: type icon, size, uploader and version, with share.
class FileRow extends ConsumerWidget {
  const FileRow({super.key, required this.file});

  final TeamFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploader = file.uploadedBy;
    return SrListRow(
      title: file.name,
      subtitle: [
        context.fileSize(file.sizeBytes),
        if (uploader != null) context.name(uploader).split(' ').first,
        if (file.version > 1) 'v${context.fmt.number(file.version)}',
      ].join(' · '),
      leading: SrAvatar(icon: fileIcon(file.name), tone: fileTone(file.name)),
      trailing: SrIconButton(
        icon: Icons.ios_share_rounded,
        compact: true,
        tooltip: context.l10n.commonShare,
        onTap: () => shareTeamFile(context, ref, file),
      ),
      chevron: true,
      onTap: () => context.push(Routes.fileFor(file.id)),
    );
  }
}

/// Downloads [file] and hands it to the share sheet.
Future<void> shareTeamFile(
  BuildContext context,
  WidgetRef ref,
  TeamFile file,
) async {
  try {
    final bytes = await showSrLoader(
      context,
      ref.read(filesRepositoryProvider).download(file.id),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes)],
        fileNameOverrides: [file.name],
      ),
    );
  } on ApiFailure catch (failure) {
    if (!context.mounted) return;
    showSrError(context, failureText(context, failure));
  }
}

/// Opens [file] full screen.
void viewTeamFile(BuildContext context, WidgetRef ref, TeamFile file) {
  final repository = ref.read(filesRepositoryProvider);
  final folder = file.folderName;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SrFileViewer(
        name: file.name,
        kind: srFileKindOf(file.name),
        title: folder == null ? null : context.name(folder),
        meta: context.fileSize(file.sizeBytes),
        load: () => repository.download(file.id),
      ),
    ),
  );
}

/// Shown when the team's storage is full.
Future<void> showStorageFullSheet(BuildContext context) => showSrSheet<void>(
  context: context,
  builder: (sheet) => SrConfirmSheet(
    title: sheet.l10n.teamStorageFullTitle,
    message: sheet.l10n.teamStorageFull,
    icon: Icons.cloud_off_outlined,
    tone: SrTone.gold,
    primaryLabel: sheet.l10n.planLockedAction,
    cancelLabel: sheet.l10n.commonCancel,
    onPrimary: () {
      Navigator.of(sheet).pop();
      context.push('${Routes.planChoose}?reason=quota&kind=storage');
    },
  ),
);

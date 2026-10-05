import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/models/team_file.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/providers/files_providers.dart';
import 'package:salesroot/features/team/view/widget/attach_sheet.dart';
import 'package:salesroot/features/team/view/widget/file_widgets.dart';
import 'package:salesroot/features/team/view/widget/info_card.dart';
import 'package:salesroot/features/team/view/widget/lookup_field.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #83 `upload`: pick a file or take a photo, say where it goes, upload.
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({
    super.key,
    this.folderId,
    this.replaceFileId,
    this.leadId,
  });

  final String? folderId;

  /// Uploads a new version of this file.
  final String? replaceFileId;

  /// Links the upload to this lead.
  final String? leadId;

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _name = TextEditingController();

  UploadNotifierProvider get _provider => uploadProvider(
    folderId: widget.folderId,
    replaceFileId: widget.replaceFileId,
    leadId: widget.leadId,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final l10n = context.l10n;
    final source = await showSrSheet<int>(
      context: context,
      builder: (context) => SrSheet(
        title: l10n.teamUploadChoose,
        child: SrRowGroup(
          rows: [
            SrListRow(
              title: l10n.teamAttachCamera,
              leading: const SrAvatar(icon: Icons.photo_camera_outlined),
              onTap: () => Navigator.of(context).pop(0),
            ),
            SrListRow(
              title: l10n.teamAttachGallery,
              leading: const SrAvatar(icon: Icons.photo_library_outlined),
              onTap: () => Navigator.of(context).pop(1),
            ),
            SrListRow(
              title: l10n.teamAttachFile,
              leading: const SrAvatar(icon: Icons.insert_drive_file_outlined),
              onTap: () => Navigator.of(context).pop(2),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await switch (source) {
        0 => pickPhoto(ImageSource.camera),
        1 => pickPhoto(ImageSource.gallery),
        _ => pickDocument(),
      };
      if (file == null || !mounted) return;
      if (file.sizeBytes > maxUploadBytes) {
        showSrError(context, l10n.teamUploadTooBig);
        return;
      }
      ref.read(_provider.notifier).pick(file);
      if (_name.text.trim().isEmpty) _name.text = file.name;
    } on Exception {
      if (mounted) showSrError(context, l10n.teamPickFailed);
    }
  }

  Future<void> _toggleLead(bool on) async {
    final notifier = ref.read(_provider.notifier);
    if (!on) {
      notifier.setLead(null, null);
      return;
    }
    final repository = ref.read(chatRepositoryProvider);
    final lead = await showSrSheet<ChatRef>(
      context: context,
      builder: (context) => SrSearchSheet<ChatRef>(
        title: context.l10n.teamUploadLinkLead,
        searchHint: context.l10n.commonSearch,
        search: (term, page) async => (await repository.attachables(
          AttachmentKind.lead,
          term,
          page,
        )).items,
        labelOf: (lead) => lead.title,
        subtitleOf: (lead) => lead.subtitle,
        isSelected: (_) => false,
      ),
    );
    if (lead != null) notifier.setLead(lead.id, lead.title);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final replacing = widget.replaceFileId;
    ref.listen(_provider.select((s) => s.phase), (_, phase) {
      final failure = ref.read(_provider).failure;
      if (phase == UploadPhase.done) {
        showSrSuccess(context, l10n.teamUploaded);
      } else if (phase == UploadPhase.failed && failure != null) {
        failure is ApiFailure && failure.isQuota
            ? showStorageFullSheet(context)
            : showSrError(context, failureText(context, failure));
      }
    });
    final file = state.file;
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: replacing == null
              ? l10n.teamUploadTitle
              : l10n.teamFileNewVersion,
          actions: const [TeamLanguageToggle()],
        ),
        footer: _footer(state, notifier),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            14,
            SrMetrics.gutter,
            24,
          ),
          children: [
            if (replacing != null) ...[
              _Replacing(fileId: replacing),
              const SizedBox(height: 14),
            ],
            _DropZone(
              onTap: state.phase == UploadPhase.uploading ? null : _choose,
            ),
            if (replacing == null) ...[
              const SizedBox(height: 14),
              _FolderField(
                selected: state.folderId,
                onChanged: notifier.setFolder,
              ),
              const SizedBox(height: 14),
              SrTextField(
                controller: _name,
                label: l10n.teamUploadName,
                hint: l10n.teamUploadNameHint,
                onChanged: notifier.setName,
              ),
            ],
            if (file != null) ...[
              const SizedBox(height: 14),
              _Progress(file: file, state: state, onCancel: notifier.cancel),
            ],
            if (!easy && replacing == null) ...[
              const SizedBox(height: 14),
              SwitchCard(
                rows: [
                  SwitchRow(
                    title: l10n.teamUploadVisibleAll,
                    value: state.visibleToAll,
                    onChanged: notifier.setVisibleToAll,
                  ),
                  SwitchRow(
                    title: l10n.teamUploadLinkLead,
                    subtitle:
                        state.leadTitle ??
                        (state.leadId == null ? null : l10n.teamUploadLinked),
                    value: state.leadId != null,
                    onChanged: _toggleLead,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _footer(UploadState state, UploadNotifier notifier) {
    final l10n = context.l10n;
    final missingFolder =
        widget.replaceFileId == null && state.folderId == null;
    return switch (state.phase) {
      UploadPhase.done => SrButton(
        label: l10n.commonDone,
        expand: true,
        onPressed: () => context.pop(),
      ),
      UploadPhase.uploading => SrButton(
        label: l10n.teamUploading,
        expand: true,
        loading: true,
        onPressed: null,
      ),
      _ => SrButton(
        label: l10n.teamUploadAction,
        icon: Icons.cloud_upload_outlined,
        expand: true,
        onPressed: state.file == null || missingFolder ? null : notifier.start,
      ),
    };
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      tone: SrCardTone.dashed,
      onTap: onTap,
      child: SizedBox(
        height: 122,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 32, color: c.accent),
            const SizedBox(height: 8),
            Text(context.l10n.teamUploadChoose, style: AppText.rowTitle(c.ink)),
            const SizedBox(height: 2),
            Text(
              context.l10n.teamUploadTypes,
              textAlign: TextAlign.center,
              style: AppText.meta(c.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderField extends ConsumerWidget {
  const _FolderField({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final folders = ref.watch(fileFoldersProvider);
    return LookupField<FileFolder>(
      title: l10n.teamUploadFolder,
      label: l10n.teamUploadFolder,
      placeholder: folders.hasError
          ? l10n.errorGeneric
          : l10n.teamUploadFolderHint,
      icon: Icons.folder_outlined,
      selected: selected,
      onChanged: (folder) => onChanged(folder.id),
      options: folders.value ?? const [],
      idOf: (folder) => folder.id,
      labelOf: (folder) => context.name(folder.name),
    );
  }
}

class _Replacing extends ConsumerWidget {
  const _Replacing({required this.fileId});

  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(teamFileProvider(fileId)).value;
    if (file == null) return const SizedBox.shrink();
    return SrNote(
      message: context.l10n.teamUploadReplacing(
        file.name,
        'v${context.fmt.number(file.version + 1)}',
      ),
    );
  }
}

/// The picked file with its upload progress and a way to stop it.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.file,
    required this.state,
    required this.onCancel,
  });

  final LocalFile file;
  final UploadState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uploading = state.phase == UploadPhase.uploading;
    final status = switch (state.phase) {
      UploadPhase.uploading => l10n.teamUploadProgress(
        context.fmt.percent(state.progress * 100),
      ),
      UploadPhase.done => l10n.teamUploadDone,
      UploadPhase.failed => l10n.teamUploadFailed,
      UploadPhase.idle => l10n.teamUploadReady,
    };
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrListRow(
            padding: const EdgeInsets.symmetric(vertical: 8),
            title: file.name,
            subtitle: '${context.fileSize(file.sizeBytes)} · $status',
            leading: SrAvatar(
              icon: fileIcon(file.name),
              tone: fileTone(file.name),
            ),
            trailing: uploading
                ? SrIconButton(
                    icon: Icons.close_rounded,
                    compact: true,
                    tooltip: l10n.commonCancel,
                    onTap: onCancel,
                  )
                : state.phase == UploadPhase.done
                ? Icon(
                    Icons.check_circle_rounded,
                    color: SrColors.of(context).accent,
                  )
                : null,
          ),
          if (state.phase != UploadPhase.idle)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SrProgressBar(
                value: state.progress,
                color: state.phase == UploadPhase.failed
                    ? SrColors.of(context).danger
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

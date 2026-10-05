import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/models/team_file.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/providers/files_providers.dart';
import 'package:salesroot/features/team/view/widget/chat_labels.dart';
import 'package:salesroot/features/team/view/widget/file_widgets.dart';
import 'package:salesroot/features/team/view/widget/info_card.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #82 `filedetail`: open, share or post a file, its versions and who can
/// see it.
class FileDetailScreen extends ConsumerWidget {
  const FileDetailScreen({super.key, required this.fileId});

  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final file = ref.watch(teamFileProvider(fileId));
    final access = ref.watch(moduleAccessProvider(AppModule.files));
    ref.listen(fileEditorProvider(fileId), (_, next) {
      switch (next) {
        case AsyncData(value: FileEditOutcome.deleted):
          context.pop();
          showSrSuccess(context, l10n.teamFileDeleted);
        case AsyncData(value: FileEditOutcome.visibilityChanged):
          showSrSuccess(context, l10n.teamSaved);
        case AsyncError(:final error):
          showSrError(context, failureText(context, error));
        default:
      }
    });
    final loaded = file.value;
    final canEdit = access.canEdit && (loaded?.canEdit ?? false);
    final canDelete = access.canDelete && (loaded?.canDelete ?? false);
    final canAdd = access.canAdd && canEdit;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.teamFileTitle,
        actions: [
          const TeamLanguageToggle(),
          if (loaded != null && (canAdd || canDelete))
            SrIconButton(
              icon: Icons.more_horiz_rounded,
              tooltip: l10n.commonMore,
              onTap: () => _more(
                context,
                ref,
                loaded,
                canReplace: canAdd,
                canDelete: canDelete,
              ),
            ),
        ],
      ),
      body: SrAsyncView(
        value: file,
        onRetry: () => ref.invalidate(teamFileProvider(fileId)),
        data: (context, file) => _Detail(file: file, canEdit: canEdit),
      ),
    );
  }

  Future<void> _more(
    BuildContext context,
    WidgetRef ref,
    TeamFile file, {
    required bool canReplace,
    required bool canDelete,
  }) async {
    final l10n = context.l10n;
    final delete = await showSrSheet<bool>(
      context: context,
      builder: (context) => SrSheet(
        title: file.name,
        child: SrRowGroup(
          rows: [
            if (canReplace)
              SrListRow(
                title: l10n.teamFileNewVersion,
                leading: const SrAvatar(icon: Icons.upload_file_outlined),
                onTap: () => Navigator.of(context).pop(false),
              ),
            if (canDelete)
              SrListRow(
                title: l10n.commonDelete,
                leading: const SrAvatar(
                  icon: Icons.delete_outline_rounded,
                  tone: SrAvatarTone.danger,
                ),
                onTap: () => Navigator.of(context).pop(true),
              ),
          ],
        ),
      ),
    );
    if (delete == null || !context.mounted) return;
    if (!delete) {
      context.push('${Routes.fileUpload}?fileId=${file.id}');
      return;
    }
    final sure = await showSrConfirm(
      context,
      title: l10n.teamFileDeleteTitle(file.name),
      message: l10n.teamFileDeleteBody,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (sure) await ref.read(fileEditorProvider(file.id).notifier).delete();
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.file, required this.canEdit});

  final TeamFile file;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final canPost = ref.watch(
      moduleAccessProvider(AppModule.chat).select((a) => a.canAdd),
    );
    final folder = file.folderName;
    final uploaded = file.uploadedAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        Center(
          child: SrAvatar(
            icon: fileIcon(file.name),
            size: 84,
            square: true,
            tone: fileTone(file.name),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          file.name,
          textAlign: TextAlign.center,
          style: AppText.sectionTitle(c.ink, size: 16),
        ),
        Text(
          [
            if (file.extension.isNotEmpty) file.extension,
            context.fileSize(file.sizeBytes),
            if (folder != null) context.name(folder),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: AppText.meta(c.ink2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SrButton(
                label: l10n.teamFileOpen,
                size: SrButtonSize.sm,
                expand: true,
                onPressed: () => viewTeamFile(context, ref, file),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrButton(
                label: l10n.commonShare,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: () => shareTeamFile(context, ref, file),
              ),
            ),
            if (canPost) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SrButton(
                  label: l10n.teamFileToChat,
                  size: SrButtonSize.sm,
                  variant: SrButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _toChat(context, ref),
                ),
              ),
            ],
          ],
        ),
        if (file.versions.isNotEmpty) ...[
          const SizedBox(height: 18),
          SrRowGroup(
            title: l10n.teamFileVersions,
            dividerIndent: 66,
            rows: [
              for (final version in file.versions)
                _VersionRow(
                  version: version,
                  current: version.version == file.version,
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        InfoCard(
          lines: [
            if (uploaded != null)
              InfoLine(l10n.teamFileUploaded, fmt.date(uploaded)),
            InfoLine(
              l10n.teamFileVisibleTo,
              _visibility(context, file.visibility),
              onTap: canEdit ? () => _changeVisibility(context, ref) : null,
            ),
            if (file.linkedLeads.isNotEmpty)
              InfoLine(
                l10n.teamFileLinkedTo,
                l10n.teamFileLeads(
                  file.linkedLeads.length,
                  fmt.number(file.linkedLeads.length),
                ),
                onTap: () => _openLeads(context),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _changeVisibility(BuildContext context, WidgetRef ref) async {
    final picked = await showSrSheet<FileVisibility>(
      context: context,
      builder: (context) => SrOptionSheet<FileVisibility>(
        title: context.l10n.teamFileVisibleTo,
        options: FileVisibility.values,
        labelOf: (v) => _visibility(context, v),
        isSelected: (v) => v == file.visibility,
      ),
    );
    if (picked == null || picked == file.visibility) return;
    await ref.read(fileEditorProvider(file.id).notifier).setVisibility(picked);
  }

  Future<void> _openLeads(BuildContext context) async {
    final leads = file.linkedLeads;
    if (leads.length == 1) {
      context.push(Routes.leadFor(leads.first.id));
      return;
    }
    final lead = await showSrSheet<FileLeadRef>(
      context: context,
      builder: (context) => SrOptionSheet<FileLeadRef>(
        title: context.l10n.teamFileLinkedTo,
        options: leads,
        labelOf: (lead) => lead.title,
        isSelected: (_) => false,
      ),
    );
    if (lead == null || !context.mounted) return;
    context.push(Routes.leadFor(lead.id));
  }

  Future<void> _toChat(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(chatRepositoryProvider);
    final thread = await showSrSheet<ChatThread>(
      context: context,
      builder: (context) => SrSearchSheet<ChatThread>(
        title: context.l10n.teamFileToChat,
        searchHint: context.l10n.teamChatSearch,
        search: (term, page) async => (await repository.threads(
          ChatQuery(search: term, page: page),
        )).items,
        labelOf: (thread) => context.threadTitle(thread),
        isSelected: (_) => false,
      ),
    );
    if (thread == null || !context.mounted) return;
    try {
      await showSrLoader(
        context,
        repository.send(
          thread.id,
          MessageInput(
            attachment: Attachment(
              kind: AttachmentKind.teamFile,
              title: file.name,
              refId: file.id,
              sizeBytes: file.sizeBytes,
            ),
          ),
        ),
      );
      if (!context.mounted) return;
      context.push(Routes.chatFor(thread.id));
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showSrError(context, failureText(context, failure));
    }
  }
}

String _visibility(BuildContext context, FileVisibility visibility) =>
    switch (visibility) {
      FileVisibility.everyone => context.l10n.teamFileVisibleAll,
      FileVisibility.leads => context.l10n.teamFileVisibleLeads,
      FileVisibility.onlyMe => context.l10n.teamFileVisibleMe,
    };

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.version, required this.current});

  final FileVersion version;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final at = version.at;
    final by = version.byName;
    final note = version.note;
    return SrListRow(
      title: [
        'v${context.fmt.number(version.version)}',
        if (at != null) context.fmt.dayTime(at),
      ].join(' · '),
      subtitle: [
        if (by != null) context.name(by),
        if (note != null && note.isNotEmpty) note,
      ].join(' · '),
      leading: const SrAvatar(icon: Icons.history_rounded),
      trailing: current
          ? SrTag(context.l10n.teamFileCurrent, tone: SrTone.ok)
          : null,
    );
  }
}

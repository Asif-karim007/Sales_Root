import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/team_file.dart';
import 'package:salesroot/features/team/providers/files_providers.dart';
import 'package:salesroot/features/team/view/widget/file_widgets.dart';
import 'package:salesroot/features/team/view/widget/paged_list.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #81 `teamfiles`: folders, the files in them and how much space is used.
class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(moduleAccessProvider(AppModule.files));
    final folderId = ref.watch(fileFolderProvider);
    final files = ref.watch(fileListProvider);
    final notifier = ref.read(fileListProvider.notifier);
    final header = [
      const _StorageCard(),
      const _FolderChips(),
      if (folderId == null) const _FolderRows(),
    ];
    final upload = folderId == null
        ? Routes.fileUpload
        : '${Routes.fileUpload}?folderId=$folderId';
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.teamFilesTitle,
        actions: [
          const TeamLanguageToggle(),
          SrIconButton(
            icon: Icons.search_rounded,
            tooltip: l10n.commonSearch,
            onTap: () => _search(context, ref),
          ),
          if (access.canAdd)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.teamUploadTitle,
              onTap: () => context.push(upload),
            ),
        ],
      ),
      body: files.when(
        data: (paged) => PagedCardList<TeamFile>(
          paged: paged,
          header: header,
          onLoadMore: notifier.loadMore,
          onRefresh: notifier.refresh,
          empty: SrEmptyState(
            icon: Icons.folder_open_outlined,
            title: l10n.teamFilesEmptyTitle,
            message: l10n.teamFilesEmptyBody,
            actionLabel: access.canAdd ? l10n.teamUploadTitle : null,
            onAction: access.canAdd ? () => context.push(upload) : null,
          ),
          itemBuilder: (context, file) => FileRow(file: file),
        ),
        loading: () => ListView(
          padding: const EdgeInsets.only(top: 14),
          children: [
            for (final widget in header) ...[
              widget,
              const SizedBox(height: 12),
            ],
            const SrSkeletonList(shrinkWrap: true),
          ],
        ),
        error: (error, _) => ListView(
          padding: const EdgeInsets.only(top: 14),
          children: [
            const _StorageCard(),
            SrErrorState(
              error: error,
              onRetry: notifier.refresh,
              onUpgrade: () => context.push(
                '${Routes.planChoose}?reason=quota&kind=storage',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _search(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(filesRepositoryProvider);
    final file = await showSrSheet<TeamFile>(
      context: context,
      builder: (context) => SrSearchSheet<TeamFile>(
        title: context.l10n.teamFilesTitle,
        searchHint: context.l10n.teamFilesSearch,
        search: (term, page) async =>
            (await repository.files(FileQuery(search: term, page: page))).items,
        labelOf: (file) => file.name,
        subtitleOf: (file) => context.fileSize(file.sizeBytes),
        isSelected: (_) => false,
      ),
    );
    if (file == null || !context.mounted) return;
    context.push(Routes.fileFor(file.id));
  }
}

class _StorageCard extends ConsumerWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final plan = ref.watch(planProvider).value;
    if (plan == null) return const SizedBox.shrink();
    final share = plan.storageGb == 0
        ? 0.0
        : plan.storageUsedGb / plan.storageGb;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
      child: SrCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrSectionHeader(
              title: l10n.teamStorageUsed(
                context.gigabytes(plan.storageUsedGb),
                context.gigabytes(plan.storageGb),
              ),
              actionLabel: l10n.teamStorageAddMore,
              onAction: () => context.push(
                '${Routes.planChoose}?reason=quota&kind=storage',
              ),
            ),
            const SizedBox(height: 8),
            SrProgressBar(
              value: share.clamp(0, 1),
              color: share > 0.9 ? c.danger : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderChips extends ConsumerWidget {
  const _FolderChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(fileFoldersProvider).value ?? const [];
    final selected = ref.watch(fileFolderProvider);
    final index = folders.indexWhere((f) => f.id == selected) + 1;
    return SrChipRow(
      chips: [
        SrChipItem(context.l10n.commonAll),
        for (final folder in folders) SrChipItem(context.name(folder.name)),
      ],
      index: index,
      onChanged: (i) => ref
          .read(fileFolderProvider.notifier)
          .set(i == 0 ? null : folders[i - 1].id),
    );
  }
}

class _FolderRows extends ConsumerWidget {
  const _FolderRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(fileFoldersProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
      child: switch (folders) {
        AsyncValue(:final List<FileFolder> value) when value.isNotEmpty =>
          SrRowGroup(
            dividerIndent: 66,
            rows: [
              for (final folder in value)
                SrListRow(
                  title: context.name(folder.name),
                  subtitle: _folderLine(context, folder),
                  leading: const SrAvatar(
                    icon: Icons.folder_outlined,
                    tone: SrAvatarTone.accent,
                  ),
                  chevron: true,
                  onTap: () =>
                      ref.read(fileFolderProvider.notifier).set(folder.id),
                ),
            ],
          ),
        AsyncError(:final error) => SrErrorState(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(fileFoldersProvider),
        ),
        AsyncValue(isLoading: true) => const SrSkeletonList(
          count: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  String _folderLine(BuildContext context, FileFolder folder) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final updated = folder.updatedAt;
    return [
      folder.isPhotos
          ? l10n.teamFolderPhotos(
              folder.fileCount,
              fmt.number(folder.fileCount),
            )
          : l10n.teamFolderFiles(
              folder.fileCount,
              fmt.number(folder.fileCount),
            ),
      if (folder.isPhotos)
        context.fileSize(folder.sizeBytes)
      else if (updated != null)
        AppDateUtils.isSameDay(updated, DateTime.now())
            ? l10n.teamUpdatedToday
            : l10n.teamUpdatedOn(fmt.dayMonth(updated)),
    ].join(' · ');
  }
}

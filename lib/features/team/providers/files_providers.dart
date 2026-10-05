import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/team/data/fake_files_repository.dart';
import 'package:salesroot/features/team/data/files_repository.dart';
import 'package:salesroot/features/team/models/team_file.dart';

part 'files_providers.g.dart';

@Riverpod(keepAlive: true)
FilesRepository filesRepository(Ref ref) =>
    FakeFilesRepository(ref.watch(fakeBackendProvider));

/// The folder chip; null is "All".
@riverpod
class FileFolderNotifier extends _$FileFolderNotifier {
  @override
  String? build() => null;

  void set(String? folderId) => state = folderId;
}

@riverpod
Future<List<FileFolder>> fileFolders(Ref ref) =>
    ref.watch(filesRepositoryProvider).folders();

@riverpod
class FileListNotifier extends _$FileListNotifier {
  @override
  Future<Paged<TeamFile>> build() async {
    final folderId = ref.watch(fileFolderProvider);
    final page = await ref
        .watch(filesRepositoryProvider)
        .files(FileQuery(folderId: folderId));
    return Paged.first(page);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(filesRepositoryProvider)
          .files(
            FileQuery(
              folderId: ref.read(fileFolderProvider),
              page: current.page + 1,
            ),
          );
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref
      ..invalidate(fileFoldersProvider)
      ..invalidateSelf();
    await future;
  }
}

@riverpod
Future<TeamFile> teamFile(Ref ref, String id) =>
    ref.watch(filesRepositoryProvider).file(id);

enum FileEditOutcome { visibilityChanged, deleted }

@riverpod
class FileEditor extends _$FileEditor {
  @override
  FutureOr<FileEditOutcome?> build(String id) => null;

  Future<void> setVisibility(FileVisibility visibility) => _run(
    FileEditOutcome.visibilityChanged,
    () => ref.read(filesRepositoryProvider).setVisibility(id, visibility),
  );

  Future<void> delete() => _run(
    FileEditOutcome.deleted,
    () => ref.read(filesRepositoryProvider).delete(id),
  );

  Future<void> _run(
    FileEditOutcome outcome,
    Future<void> Function() work,
  ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await work();
      return outcome;
    });
    if (!ref.mounted) return;
    state = result;
    if (!result.hasValue) return;
    ref
      ..invalidate(fileListProvider)
      ..invalidate(fileFoldersProvider);
    if (outcome == FileEditOutcome.deleted) return;
    ref.invalidate(teamFileProvider(id));
  }
}

enum UploadPhase { idle, uploading, done, failed }

class UploadState {
  const UploadState({
    this.file,
    this.name = '',
    this.folderId,
    this.visibleToAll = true,
    this.leadId,
    this.leadTitle,
    this.progress = 0,
    this.phase = UploadPhase.idle,
    this.failure,
    this.result,
  });

  final LocalFile? file;
  final String name;
  final String? folderId;
  final bool visibleToAll;
  final String? leadId;
  final String? leadTitle;
  final double progress;
  final UploadPhase phase;
  final Object? failure;
  final TeamFile? result;

  UploadState copyWith({
    LocalFile? file,
    String? name,
    String? folderId,
    bool? visibleToAll,
    String? Function()? leadId,
    String? Function()? leadTitle,
    double? progress,
    UploadPhase? phase,
    Object? Function()? failure,
    TeamFile? result,
  }) => UploadState(
    file: file ?? this.file,
    name: name ?? this.name,
    folderId: folderId ?? this.folderId,
    visibleToAll: visibleToAll ?? this.visibleToAll,
    leadId: leadId != null ? leadId() : this.leadId,
    leadTitle: leadTitle != null ? leadTitle() : this.leadTitle,
    progress: progress ?? this.progress,
    phase: phase ?? this.phase,
    failure: failure != null ? failure() : this.failure,
    result: result ?? this.result,
  );
}

/// The upload form: the picked file, where it goes, and the running upload.
@riverpod
class UploadNotifier extends _$UploadNotifier {
  UploadCancel? _cancel;

  @override
  UploadState build({
    String? folderId,
    String? replaceFileId,
    String? leadId,
  }) => UploadState(folderId: folderId, leadId: leadId);

  void pick(LocalFile file) => state = state.copyWith(
    file: file,
    name: state.name.isEmpty ? file.name : null,
    phase: UploadPhase.idle,
    progress: 0,
    failure: () => null,
  );

  void setName(String name) => state = state.copyWith(name: name);

  void setFolder(String folderId) => state = state.copyWith(folderId: folderId);

  void setVisibleToAll(bool visible) =>
      state = state.copyWith(visibleToAll: visible);

  void setLead(String? id, String? title) =>
      state = state.copyWith(leadId: () => id, leadTitle: () => title);

  Future<void> start() async {
    final file = state.file;
    if (file == null || state.phase == UploadPhase.uploading) return;
    final cancel = _cancel = UploadCancel();
    state = state.copyWith(
      phase: UploadPhase.uploading,
      progress: 0,
      failure: () => null,
    );
    try {
      final uploaded = await ref
          .read(filesRepositoryProvider)
          .upload(
            UploadInput(
              file: file,
              name: state.name,
              folderId: state.folderId,
              visibleToAll: state.visibleToAll,
              leadId: state.leadId,
              replaceFileId: replaceFileId,
            ),
            onProgress: (progress) {
              if (ref.mounted) state = state.copyWith(progress: progress);
            },
            cancel: cancel,
          );
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: UploadPhase.done,
        progress: 1,
        result: uploaded,
      );
      ref
        ..invalidate(fileListProvider)
        ..invalidate(fileFoldersProvider);
      final replaced = replaceFileId;
      if (replaced != null) ref.invalidate(teamFileProvider(replaced));
    } on UploadCancelled {
      if (!ref.mounted) return;
      state = state.copyWith(phase: UploadPhase.idle, progress: 0);
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(phase: UploadPhase.failed, failure: () => failure);
    }
  }

  void cancel() => _cancel?.cancel();
}

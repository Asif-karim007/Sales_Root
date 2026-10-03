// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'files_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(filesRepository)
final filesRepositoryProvider = FilesRepositoryProvider._();

final class FilesRepositoryProvider
    extends
        $FunctionalProvider<FilesRepository, FilesRepository, FilesRepository>
    with $Provider<FilesRepository> {
  FilesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FilesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FilesRepository create(Ref ref) {
    return filesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilesRepository>(value),
    );
  }
}

String _$filesRepositoryHash() => r'2ef4abacc061cd724aa7f720a5f1a9cfc51fc319';

/// The folder chip; null is "All".

@ProviderFor(FileFolderNotifier)
final fileFolderProvider = FileFolderNotifierProvider._();

/// The folder chip; null is "All".
final class FileFolderNotifierProvider
    extends $NotifierProvider<FileFolderNotifier, int?> {
  /// The folder chip; null is "All".
  FileFolderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileFolderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileFolderNotifierHash();

  @$internal
  @override
  FileFolderNotifier create() => FileFolderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$fileFolderNotifierHash() =>
    r'c6cc2c864bf6edbd6acdad4e9dbdca36a47a269e';

/// The folder chip; null is "All".

abstract class _$FileFolderNotifier extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(fileFolders)
final fileFoldersProvider = FileFoldersProvider._();

final class FileFoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FileFolder>>,
          List<FileFolder>,
          FutureOr<List<FileFolder>>
        >
    with $FutureModifier<List<FileFolder>>, $FutureProvider<List<FileFolder>> {
  FileFoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileFoldersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileFoldersHash();

  @$internal
  @override
  $FutureProviderElement<List<FileFolder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FileFolder>> create(Ref ref) {
    return fileFolders(ref);
  }
}

String _$fileFoldersHash() => r'dcba148c871080437c5cb541b964f7a850cda45d';

@ProviderFor(FileListNotifier)
final fileListProvider = FileListNotifierProvider._();

final class FileListNotifierProvider
    extends $AsyncNotifierProvider<FileListNotifier, Paged<TeamFile>> {
  FileListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileListNotifierHash();

  @$internal
  @override
  FileListNotifier create() => FileListNotifier();
}

String _$fileListNotifierHash() => r'f7f55b1ef398de3ad38d5b3d6405ffbae627ad82';

abstract class _$FileListNotifier extends $AsyncNotifier<Paged<TeamFile>> {
  FutureOr<Paged<TeamFile>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<TeamFile>>, Paged<TeamFile>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<TeamFile>>, Paged<TeamFile>>,
              AsyncValue<Paged<TeamFile>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(teamFile)
final teamFileProvider = TeamFileFamily._();

final class TeamFileProvider
    extends
        $FunctionalProvider<AsyncValue<TeamFile>, TeamFile, FutureOr<TeamFile>>
    with $FutureModifier<TeamFile>, $FutureProvider<TeamFile> {
  TeamFileProvider._({
    required TeamFileFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'teamFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamFileHash();

  @override
  String toString() {
    return r'teamFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TeamFile> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TeamFile> create(Ref ref) {
    final argument = this.argument as int;
    return teamFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamFileHash() => r'92ba512ab731818e03ddc10116c53c1b57cb8250';

final class TeamFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TeamFile>, int> {
  TeamFileFamily._()
    : super(
        retry: null,
        name: r'teamFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamFileProvider call(int id) => TeamFileProvider._(argument: id, from: this);

  @override
  String toString() => r'teamFileProvider';
}

@ProviderFor(FileEditor)
final fileEditorProvider = FileEditorFamily._();

final class FileEditorProvider
    extends $AsyncNotifierProvider<FileEditor, FileEditOutcome?> {
  FileEditorProvider._({
    required FileEditorFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'fileEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fileEditorHash();

  @override
  String toString() {
    return r'fileEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FileEditor create() => FileEditor();

  @override
  bool operator ==(Object other) {
    return other is FileEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fileEditorHash() => r'08406b4f82f5b3bfed1327627af9b094c546a6d2';

final class FileEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          FileEditor,
          AsyncValue<FileEditOutcome?>,
          FileEditOutcome?,
          FutureOr<FileEditOutcome?>,
          int
        > {
  FileEditorFamily._()
    : super(
        retry: null,
        name: r'fileEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FileEditorProvider call(int id) =>
      FileEditorProvider._(argument: id, from: this);

  @override
  String toString() => r'fileEditorProvider';
}

abstract class _$FileEditor extends $AsyncNotifier<FileEditOutcome?> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<FileEditOutcome?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<FileEditOutcome?>, FileEditOutcome?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FileEditOutcome?>, FileEditOutcome?>,
              AsyncValue<FileEditOutcome?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The upload form: the picked file, where it goes, and the running upload.

@ProviderFor(UploadNotifier)
final uploadProvider = UploadNotifierFamily._();

/// The upload form: the picked file, where it goes, and the running upload.
final class UploadNotifierProvider
    extends $NotifierProvider<UploadNotifier, UploadState> {
  /// The upload form: the picked file, where it goes, and the running upload.
  UploadNotifierProvider._({
    required UploadNotifierFamily super.from,
    required ({int? folderId, int? replaceFileId, int? leadId}) super.argument,
  }) : super(
         retry: null,
         name: r'uploadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$uploadNotifierHash();

  @override
  String toString() {
    return r'uploadProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  UploadNotifier create() => UploadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UploadNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$uploadNotifierHash() => r'e59c98ef12ddc7ba5696377d9fcf408dc67d471c';

/// The upload form: the picked file, where it goes, and the running upload.

final class UploadNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          UploadNotifier,
          UploadState,
          UploadState,
          UploadState,
          ({int? folderId, int? replaceFileId, int? leadId})
        > {
  UploadNotifierFamily._()
    : super(
        retry: null,
        name: r'uploadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The upload form: the picked file, where it goes, and the running upload.

  UploadNotifierProvider call({
    int? folderId,
    int? replaceFileId,
    int? leadId,
  }) => UploadNotifierProvider._(
    argument: (
      folderId: folderId,
      replaceFileId: replaceFileId,
      leadId: leadId,
    ),
    from: this,
  );

  @override
  String toString() => r'uploadProvider';
}

/// The upload form: the picked file, where it goes, and the running upload.

abstract class _$UploadNotifier extends $Notifier<UploadState> {
  late final _$args =
      ref.$arg as ({int? folderId, int? replaceFileId, int? leadId});
  int? get folderId => _$args.folderId;
  int? get replaceFileId => _$args.replaceFileId;
  int? get leadId => _$args.leadId;

  UploadState build({int? folderId, int? replaceFileId, int? leadId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UploadState, UploadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UploadState, UploadState>,
              UploadState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        folderId: _$args.folderId,
        replaceFileId: _$args.replaceFileId,
        leadId: _$args.leadId,
      ),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(importRepository)
final importRepositoryProvider = ImportRepositoryProvider._();

final class ImportRepositoryProvider
    extends
        $FunctionalProvider<
          ImportRepository,
          ImportRepository,
          ImportRepository
        >
    with $Provider<ImportRepository> {
  ImportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importRepositoryHash();

  @$internal
  @override
  $ProviderElement<ImportRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportRepository create(Ref ref) {
    return importRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportRepository>(value),
    );
  }
}

String _$importRepositoryHash() => r'36458ecdd5ae335447e589197b5a36961d508ce3';

@ProviderFor(CsvImportNotifier)
final csvImportProvider = CsvImportNotifierProvider._();

final class CsvImportNotifierProvider
    extends $NotifierProvider<CsvImportNotifier, CsvImportState> {
  CsvImportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvImportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$csvImportNotifierHash();

  @$internal
  @override
  CsvImportNotifier create() => CsvImportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CsvImportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CsvImportState>(value),
    );
  }
}

String _$csvImportNotifierHash() => r'5a844ae23c93db04bbc8b77fac8a8bd607326137';

abstract class _$CsvImportNotifier extends $Notifier<CsvImportState> {
  CsvImportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CsvImportState, CsvImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CsvImportState, CsvImportState>,
              CsvImportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

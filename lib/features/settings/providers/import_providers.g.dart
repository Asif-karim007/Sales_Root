// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$csvImportNotifierHash() => r'4da5ee548b6232a2b1e408a2a4b0761d0217e2d2';

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

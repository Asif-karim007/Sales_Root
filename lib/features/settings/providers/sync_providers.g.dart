// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncRepository)
final syncRepositoryProvider = SyncRepositoryProvider._();

final class SyncRepositoryProvider
    extends $FunctionalProvider<SyncRepository, SyncRepository, SyncRepository>
    with $Provider<SyncRepository> {
  SyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRepositoryHash();

  @$internal
  @override
  $ProviderElement<SyncRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncRepository create(Ref ref) {
    return syncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRepository>(value),
    );
  }
}

String _$syncRepositoryHash() => r'1540ef26a38570014b8e237fd922e6df6e63e6dc';

@ProviderFor(SyncNotifier)
final syncProvider = SyncNotifierProvider._();

final class SyncNotifierProvider
    extends $AsyncNotifierProvider<SyncNotifier, SyncSnapshot> {
  SyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncNotifierHash();

  @$internal
  @override
  SyncNotifier create() => SyncNotifier();
}

String _$syncNotifierHash() => r'2f25b338bdc3a8c4b07a1c58aec5231eeac4b605';

abstract class _$SyncNotifier extends $AsyncNotifier<SyncSnapshot> {
  FutureOr<SyncSnapshot> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SyncSnapshot>, SyncSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SyncSnapshot>, SyncSnapshot>,
              AsyncValue<SyncSnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(syncConflict)
final syncConflictProvider = SyncConflictFamily._();

final class SyncConflictProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncConflict>,
          SyncConflict,
          FutureOr<SyncConflict>
        >
    with $FutureModifier<SyncConflict>, $FutureProvider<SyncConflict> {
  SyncConflictProvider._({
    required SyncConflictFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'syncConflictProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$syncConflictHash();

  @override
  String toString() {
    return r'syncConflictProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SyncConflict> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SyncConflict> create(Ref ref) {
    final argument = this.argument as int;
    return syncConflict(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SyncConflictProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$syncConflictHash() => r'4b391342fbabf3eb18a0076ee706d574c7d85adc';

final class SyncConflictFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SyncConflict>, int> {
  SyncConflictFamily._()
    : super(
        retry: null,
        name: r'syncConflictProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SyncConflictProvider call(int id) =>
      SyncConflictProvider._(argument: id, from: this);

  @override
  String toString() => r'syncConflictProvider';
}

/// The side picked for each field of conflict [id], keyed by field.

@ProviderFor(ConflictChoicesNotifier)
final conflictChoicesProvider = ConflictChoicesNotifierFamily._();

/// The side picked for each field of conflict [id], keyed by field.
final class ConflictChoicesNotifierProvider
    extends
        $NotifierProvider<ConflictChoicesNotifier, Map<String, ConflictSide>> {
  /// The side picked for each field of conflict [id], keyed by field.
  ConflictChoicesNotifierProvider._({
    required ConflictChoicesNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'conflictChoicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conflictChoicesNotifierHash();

  @override
  String toString() {
    return r'conflictChoicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ConflictChoicesNotifier create() => ConflictChoicesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ConflictSide> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ConflictSide>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConflictChoicesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conflictChoicesNotifierHash() =>
    r'140ac2b9a9c66cba891fe26d0c8da2e83e6fe255';

/// The side picked for each field of conflict [id], keyed by field.

final class ConflictChoicesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConflictChoicesNotifier,
          Map<String, ConflictSide>,
          Map<String, ConflictSide>,
          Map<String, ConflictSide>,
          int
        > {
  ConflictChoicesNotifierFamily._()
    : super(
        retry: null,
        name: r'conflictChoicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The side picked for each field of conflict [id], keyed by field.

  ConflictChoicesNotifierProvider call(int id) =>
      ConflictChoicesNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'conflictChoicesProvider';
}

/// The side picked for each field of conflict [id], keyed by field.

abstract class _$ConflictChoicesNotifier
    extends $Notifier<Map<String, ConflictSide>> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  Map<String, ConflictSide> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, ConflictSide>, Map<String, ConflictSide>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, ConflictSide>, Map<String, ConflictSide>>,
              Map<String, ConflictSide>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(SyncPrefsNotifier)
final syncPrefsProvider = SyncPrefsNotifierProvider._();

final class SyncPrefsNotifierProvider
    extends $NotifierProvider<SyncPrefsNotifier, SyncPrefs> {
  SyncPrefsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncPrefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncPrefsNotifierHash();

  @$internal
  @override
  SyncPrefsNotifier create() => SyncPrefsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncPrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncPrefs>(value),
    );
  }
}

String _$syncPrefsNotifierHash() => r'62bdd5ae4da50e8408c50897c616804df067cedc';

abstract class _$SyncPrefsNotifier extends $Notifier<SyncPrefs> {
  SyncPrefs build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyncPrefs, SyncPrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncPrefs, SyncPrefs>,
              SyncPrefs,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The phone's network links, now and as they change.

@ProviderFor(connectivity)
final connectivityProvider = ConnectivityProvider._();

/// The phone's network links, now and as they change.

final class ConnectivityProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConnectivityResult>>,
          List<ConnectivityResult>,
          Stream<List<ConnectivityResult>>
        >
    with
        $FutureModifier<List<ConnectivityResult>>,
        $StreamProvider<List<ConnectivityResult>> {
  /// The phone's network links, now and as they change.
  ConnectivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  $StreamProviderElement<List<ConnectivityResult>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ConnectivityResult>> create(Ref ref) {
    return connectivity(ref);
  }
}

String _$connectivityHash() => r'afbc1807856e46f3dae64e34c3769e0b1076f11f';

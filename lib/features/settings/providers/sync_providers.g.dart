// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$syncNotifierHash() => r'61eb1881c0e97d6910ff4cbd8c1044322e53cf56';

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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$syncConflictHash() => r'b11a2b05e266a8e421dbd63a9e9befa758bc5403';

final class SyncConflictFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SyncConflict>, String> {
  SyncConflictFamily._()
    : super(
        retry: null,
        name: r'syncConflictProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SyncConflictProvider call(String id) =>
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
    required String super.argument,
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
    r'a5ca724e3032fffe9d199020e7a98fe947259f38';

/// The side picked for each field of conflict [id], keyed by field.

final class ConflictChoicesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConflictChoicesNotifier,
          Map<String, ConflictSide>,
          Map<String, ConflictSide>,
          Map<String, ConflictSide>,
          String
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

  ConflictChoicesNotifierProvider call(String id) =>
      ConflictChoicesNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'conflictChoicesProvider';
}

/// The side picked for each field of conflict [id], keyed by field.

abstract class _$ConflictChoicesNotifier
    extends $Notifier<Map<String, ConflictSide>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  Map<String, ConflictSide> build(String id);
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

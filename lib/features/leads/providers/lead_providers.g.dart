// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(leadRepository)
final leadRepositoryProvider = LeadRepositoryProvider._();

final class LeadRepositoryProvider
    extends $FunctionalProvider<LeadRepository, LeadRepository, LeadRepository>
    with $Provider<LeadRepository> {
  LeadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadRepositoryHash();

  @$internal
  @override
  $ProviderElement<LeadRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LeadRepository create(Ref ref) {
    return leadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadRepository>(value),
    );
  }
}

String _$leadRepositoryHash() => r'89695ea88edce67c4bb3d7673e146bc4b6b1cced';

@ProviderFor(leadStages)
final leadStagesProvider = LeadStagesProvider._();

final class LeadStagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeadStage>>,
          List<LeadStage>,
          FutureOr<List<LeadStage>>
        >
    with $FutureModifier<List<LeadStage>>, $FutureProvider<List<LeadStage>> {
  LeadStagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadStagesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadStagesHash();

  @$internal
  @override
  $FutureProviderElement<List<LeadStage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LeadStage>> create(Ref ref) {
    return leadStages(ref);
  }
}

String _$leadStagesHash() => r'1c9d473c84a9622816d9de6042478d5b1078c508';

@ProviderFor(leadLookups)
final leadLookupsProvider = LeadLookupsProvider._();

final class LeadLookupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<LeadLookups>,
          LeadLookups,
          FutureOr<LeadLookups>
        >
    with $FutureModifier<LeadLookups>, $FutureProvider<LeadLookups> {
  LeadLookupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadLookupsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadLookupsHash();

  @$internal
  @override
  $FutureProviderElement<LeadLookups> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LeadLookups> create(Ref ref) {
    return leadLookups(ref);
  }
}

String _$leadLookupsHash() => r'60a40893d456c935f5e529db312e719c761ca453';

/// The stages the current experience level shows, Lost excluded.

@ProviderFor(visibleLeadStages)
final visibleLeadStagesProvider = VisibleLeadStagesProvider._();

/// The stages the current experience level shows, Lost excluded.

final class VisibleLeadStagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeadStage>>,
          List<LeadStage>,
          FutureOr<List<LeadStage>>
        >
    with $FutureModifier<List<LeadStage>>, $FutureProvider<List<LeadStage>> {
  /// The stages the current experience level shows, Lost excluded.
  VisibleLeadStagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleLeadStagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleLeadStagesHash();

  @$internal
  @override
  $FutureProviderElement<List<LeadStage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LeadStage>> create(Ref ref) {
    return visibleLeadStages(ref);
  }
}

String _$visibleLeadStagesHash() => r'ab271ee8023a45b97bce6038a19aa2e7b6f0c1d4';

@ProviderFor(LeadFilterNotifier)
final leadFilterProvider = LeadFilterNotifierProvider._();

final class LeadFilterNotifierProvider
    extends $NotifierProvider<LeadFilterNotifier, LeadFilter> {
  LeadFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadFilterNotifierHash();

  @$internal
  @override
  LeadFilterNotifier create() => LeadFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadFilter>(value),
    );
  }
}

String _$leadFilterNotifierHash() =>
    r'6983dd8fae01a85ddff7546a8b8f77be5d58c43a';

abstract class _$LeadFilterNotifier extends $Notifier<LeadFilter> {
  LeadFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LeadFilter, LeadFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadFilter, LeadFilter>,
              LeadFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The lead list, 20 at a time, rebuilt from page 1 when the filter changes.

@ProviderFor(LeadListNotifier)
final leadListProvider = LeadListNotifierProvider._();

/// The lead list, 20 at a time, rebuilt from page 1 when the filter changes.
final class LeadListNotifierProvider
    extends $AsyncNotifierProvider<LeadListNotifier, Paged<Lead>> {
  /// The lead list, 20 at a time, rebuilt from page 1 when the filter changes.
  LeadListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadListNotifierHash();

  @$internal
  @override
  LeadListNotifier create() => LeadListNotifier();
}

String _$leadListNotifierHash() => r'79257e82a28844e7f9e6f255858d66d72bab7146';

/// The lead list, 20 at a time, rebuilt from page 1 when the filter changes.

abstract class _$LeadListNotifier extends $AsyncNotifier<Paged<Lead>> {
  FutureOr<Paged<Lead>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Lead>>, Paged<Lead>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Lead>>, Paged<Lead>>,
              AsyncValue<Paged<Lead>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LeadBoardNotifier)
final leadBoardProvider = LeadBoardNotifierProvider._();

final class LeadBoardNotifierProvider
    extends $AsyncNotifierProvider<LeadBoardNotifier, LeadBoard> {
  LeadBoardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadBoardNotifierHash();

  @$internal
  @override
  LeadBoardNotifier create() => LeadBoardNotifier();
}

String _$leadBoardNotifierHash() => r'73d5a1e9f7eb7a8bc3f7501488135e6a9bc70c96';

abstract class _$LeadBoardNotifier extends $AsyncNotifier<LeadBoard> {
  FutureOr<LeadBoard> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LeadBoard>, LeadBoard>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LeadBoard>, LeadBoard>,
              AsyncValue<LeadBoard>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// One lead with its timeline.

@ProviderFor(lead)
final leadProvider = LeadFamily._();

/// One lead with its timeline.

final class LeadProvider
    extends $FunctionalProvider<AsyncValue<Lead>, Lead, FutureOr<Lead>>
    with $FutureModifier<Lead>, $FutureProvider<Lead> {
  /// One lead with its timeline.
  LeadProvider._({required LeadFamily super.from, required int super.argument})
    : super(
        retry: null,
        name: r'leadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadHash();

  @override
  String toString() {
    return r'leadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Lead> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Lead> create(Ref ref) {
    final argument = this.argument as int;
    return lead(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadHash() => r'8389191fbb279811bef3531afd05e91bba03bd7e';

/// One lead with its timeline.

final class LeadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Lead>, int> {
  LeadFamily._()
    : super(
        retry: null,
        name: r'leadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One lead with its timeline.

  LeadProvider call(int id) => LeadProvider._(argument: id, from: this);

  @override
  String toString() => r'leadProvider';
}

/// How many leads [filter] would show, for the filter sheet's button.

@ProviderFor(leadFilterPreview)
final leadFilterPreviewProvider = LeadFilterPreviewFamily._();

/// How many leads [filter] would show, for the filter sheet's button.

final class LeadFilterPreviewProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// How many leads [filter] would show, for the filter sheet's button.
  LeadFilterPreviewProvider._({
    required LeadFilterPreviewFamily super.from,
    required LeadFilter super.argument,
  }) : super(
         retry: null,
         name: r'leadFilterPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadFilterPreviewHash();

  @override
  String toString() {
    return r'leadFilterPreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as LeadFilter;
    return leadFilterPreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeadFilterPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadFilterPreviewHash() => r'51890a8b08f27d8e0551c686c3bcaf132f2d14a8';

/// How many leads [filter] would show, for the filter sheet's button.

final class LeadFilterPreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, LeadFilter> {
  LeadFilterPreviewFamily._()
    : super(
        retry: null,
        name: r'leadFilterPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How many leads [filter] would show, for the filter sheet's button.

  LeadFilterPreviewProvider call(LeadFilter filter) =>
      LeadFilterPreviewProvider._(argument: filter, from: this);

  @override
  String toString() => r'leadFilterPreviewProvider';
}

/// Stage moves, undo, task done and delete. Every result lands in the list,
/// the board and the detail at once; the screen named by the event's origin
/// shows the snackbar. Kept alive so an undo still lands after the screen
/// that started the move has closed.

@ProviderFor(LeadActionsNotifier)
final leadActionsProvider = LeadActionsNotifierProvider._();

/// Stage moves, undo, task done and delete. Every result lands in the list,
/// the board and the detail at once; the screen named by the event's origin
/// shows the snackbar. Kept alive so an undo still lands after the screen
/// that started the move has closed.
final class LeadActionsNotifierProvider
    extends $NotifierProvider<LeadActionsNotifier, LeadEvent?> {
  /// Stage moves, undo, task done and delete. Every result lands in the list,
  /// the board and the detail at once; the screen named by the event's origin
  /// shows the snackbar. Kept alive so an undo still lands after the screen
  /// that started the move has closed.
  LeadActionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadActionsNotifierHash();

  @$internal
  @override
  LeadActionsNotifier create() => LeadActionsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadEvent? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadEvent?>(value),
    );
  }
}

String _$leadActionsNotifierHash() =>
    r'1dc8bb9f9380d419248f9fec461da72e04e91c94';

/// Stage moves, undo, task done and delete. Every result lands in the list,
/// the board and the detail at once; the screen named by the event's origin
/// shows the snackbar. Kept alive so an undo still lands after the screen
/// that started the move has closed.

abstract class _$LeadActionsNotifier extends $Notifier<LeadEvent?> {
  LeadEvent? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LeadEvent?, LeadEvent?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadEvent?, LeadEvent?>,
              LeadEvent?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Saving the lead forms. [slot] keeps the quick, voice and full forms
/// apart, since one can open over another.

@ProviderFor(LeadSaveNotifier)
final leadSaveProvider = LeadSaveNotifierFamily._();

/// Saving the lead forms. [slot] keeps the quick, voice and full forms
/// apart, since one can open over another.
final class LeadSaveNotifierProvider
    extends $AsyncNotifierProvider<LeadSaveNotifier, Lead?> {
  /// Saving the lead forms. [slot] keeps the quick, voice and full forms
  /// apart, since one can open over another.
  LeadSaveNotifierProvider._({
    required LeadSaveNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leadSaveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadSaveNotifierHash();

  @override
  String toString() {
    return r'leadSaveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LeadSaveNotifier create() => LeadSaveNotifier();

  @override
  bool operator ==(Object other) {
    return other is LeadSaveNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadSaveNotifierHash() => r'40c91b9c4a6f9314d766397e2d7a98599d3fd744';

/// Saving the lead forms. [slot] keeps the quick, voice and full forms
/// apart, since one can open over another.

final class LeadSaveNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          LeadSaveNotifier,
          AsyncValue<Lead?>,
          Lead?,
          FutureOr<Lead?>,
          String
        > {
  LeadSaveNotifierFamily._()
    : super(
        retry: null,
        name: r'leadSaveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saving the lead forms. [slot] keeps the quick, voice and full forms
  /// apart, since one can open over another.

  LeadSaveNotifierProvider call(String slot) =>
      LeadSaveNotifierProvider._(argument: slot, from: this);

  @override
  String toString() => r'leadSaveProvider';
}

/// Saving the lead forms. [slot] keeps the quick, voice and full forms
/// apart, since one can open over another.

abstract class _$LeadSaveNotifier extends $AsyncNotifier<Lead?> {
  late final _$args = ref.$arg as String;
  String get slot => _$args;

  FutureOr<Lead?> build(String slot);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Lead?>, Lead?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Lead?>, Lead?>,
              AsyncValue<Lead?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Logging a call, meeting, visit, note or message on a lead.

@ProviderFor(LeadActivitySaveNotifier)
final leadActivitySaveProvider = LeadActivitySaveNotifierFamily._();

/// Logging a call, meeting, visit, note or message on a lead.
final class LeadActivitySaveNotifierProvider
    extends $AsyncNotifierProvider<LeadActivitySaveNotifier, Lead?> {
  /// Logging a call, meeting, visit, note or message on a lead.
  LeadActivitySaveNotifierProvider._({
    required LeadActivitySaveNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leadActivitySaveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadActivitySaveNotifierHash();

  @override
  String toString() {
    return r'leadActivitySaveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LeadActivitySaveNotifier create() => LeadActivitySaveNotifier();

  @override
  bool operator ==(Object other) {
    return other is LeadActivitySaveNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadActivitySaveNotifierHash() =>
    r'baba02c2005e67606fbc339b52e7edac2ce88e0f';

/// Logging a call, meeting, visit, note or message on a lead.

final class LeadActivitySaveNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          LeadActivitySaveNotifier,
          AsyncValue<Lead?>,
          Lead?,
          FutureOr<Lead?>,
          String
        > {
  LeadActivitySaveNotifierFamily._()
    : super(
        retry: null,
        name: r'leadActivitySaveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Logging a call, meeting, visit, note or message on a lead.

  LeadActivitySaveNotifierProvider call(String slot) =>
      LeadActivitySaveNotifierProvider._(argument: slot, from: this);

  @override
  String toString() => r'leadActivitySaveProvider';
}

/// Logging a call, meeting, visit, note or message on a lead.

abstract class _$LeadActivitySaveNotifier extends $AsyncNotifier<Lead?> {
  late final _$args = ref.$arg as String;
  String get slot => _$args;

  FutureOr<Lead?> build(String slot);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Lead?>, Lead?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Lead?>, Lead?>,
              AsyncValue<Lead?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(PendingCallNotifier)
final pendingCallProvider = PendingCallNotifierProvider._();

final class PendingCallNotifierProvider
    extends $NotifierProvider<PendingCallNotifier, PendingCall?> {
  PendingCallNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingCallProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingCallNotifierHash();

  @$internal
  @override
  PendingCallNotifier create() => PendingCallNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingCall? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingCall?>(value),
    );
  }
}

String _$pendingCallNotifierHash() =>
    r'7d315f480a0a778b6171ad44aa818839625a4954';

abstract class _$PendingCallNotifier extends $Notifier<PendingCall?> {
  PendingCall? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PendingCall?, PendingCall?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PendingCall?, PendingCall?>,
              PendingCall?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(leadInboxRepository)
final leadInboxRepositoryProvider = LeadInboxRepositoryProvider._();

final class LeadInboxRepositoryProvider
    extends
        $FunctionalProvider<
          LeadInboxRepository,
          LeadInboxRepository,
          LeadInboxRepository
        >
    with $Provider<LeadInboxRepository> {
  LeadInboxRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadInboxRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadInboxRepositoryHash();

  @$internal
  @override
  $ProviderElement<LeadInboxRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LeadInboxRepository create(Ref ref) {
    return leadInboxRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadInboxRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadInboxRepository>(value),
    );
  }
}

String _$leadInboxRepositoryHash() =>
    r'73fbdd0ae92a66eee698ebcb9719df46402a7323';

@ProviderFor(InboxFilterNotifier)
final inboxFilterProvider = InboxFilterNotifierProvider._();

final class InboxFilterNotifierProvider
    extends $NotifierProvider<InboxFilterNotifier, InboxFilter> {
  InboxFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxFilterNotifierHash();

  @$internal
  @override
  InboxFilterNotifier create() => InboxFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InboxFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InboxFilter>(value),
    );
  }
}

String _$inboxFilterNotifierHash() =>
    r'e1d894ffda58bd0dddbf0bb26aa072b373d440d1';

abstract class _$InboxFilterNotifier extends $Notifier<InboxFilter> {
  InboxFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InboxFilter, InboxFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InboxFilter, InboxFilter>,
              InboxFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The new-leads inbox (#136), most urgent first.

@ProviderFor(InboxListNotifier)
final inboxListProvider = InboxListNotifierProvider._();

/// The new-leads inbox (#136), most urgent first.
final class InboxListNotifierProvider
    extends $AsyncNotifierProvider<InboxListNotifier, Paged<InboxLead>> {
  /// The new-leads inbox (#136), most urgent first.
  InboxListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxListNotifierHash();

  @$internal
  @override
  InboxListNotifier create() => InboxListNotifier();
}

String _$inboxListNotifierHash() => r'fe6fe5dcff8e22bc0c47721ba44855bcd0b30a83';

/// The new-leads inbox (#136), most urgent first.

abstract class _$InboxListNotifier extends $AsyncNotifier<Paged<InboxLead>> {
  FutureOr<Paged<InboxLead>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<InboxLead>>, Paged<InboxLead>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<InboxLead>>, Paged<InboxLead>>,
              AsyncValue<Paged<InboxLead>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(inboxLead)
final inboxLeadProvider = InboxLeadFamily._();

final class InboxLeadProvider
    extends
        $FunctionalProvider<
          AsyncValue<InboxLead>,
          InboxLead,
          FutureOr<InboxLead>
        >
    with $FutureModifier<InboxLead>, $FutureProvider<InboxLead> {
  InboxLeadProvider._({
    required InboxLeadFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'inboxLeadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inboxLeadHash();

  @override
  String toString() {
    return r'inboxLeadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InboxLead> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<InboxLead> create(Ref ref) {
    final argument = this.argument as int;
    return inboxLead(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InboxLeadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inboxLeadHash() => r'64f8a84cc647c53cfc89176e7ceb6401ddc25090';

final class InboxLeadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InboxLead>, int> {
  InboxLeadFamily._()
    : super(
        retry: null,
        name: r'inboxLeadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InboxLeadProvider call(int id) =>
      InboxLeadProvider._(argument: id, from: this);

  @override
  String toString() => r'inboxLeadProvider';
}

@ProviderFor(inboxSuggestion)
final inboxSuggestionProvider = InboxSuggestionFamily._();

final class InboxSuggestionProvider
    extends
        $FunctionalProvider<
          AsyncValue<AssigneeSuggestion>,
          AssigneeSuggestion,
          FutureOr<AssigneeSuggestion>
        >
    with
        $FutureModifier<AssigneeSuggestion>,
        $FutureProvider<AssigneeSuggestion> {
  InboxSuggestionProvider._({
    required InboxSuggestionFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'inboxSuggestionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inboxSuggestionHash();

  @override
  String toString() {
    return r'inboxSuggestionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AssigneeSuggestion> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AssigneeSuggestion> create(Ref ref) {
    final argument = this.argument as int;
    return inboxSuggestion(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InboxSuggestionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inboxSuggestionHash() => r'ebf04aee6ab669332ac4a4106e1880bff139823d';

final class InboxSuggestionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AssigneeSuggestion>, int> {
  InboxSuggestionFamily._()
    : super(
        retry: null,
        name: r'inboxSuggestionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InboxSuggestionProvider call(int id) =>
      InboxSuggestionProvider._(argument: id, from: this);

  @override
  String toString() => r'inboxSuggestionProvider';
}

@ProviderFor(growthMembers)
final growthMembersProvider = GrowthMembersProvider._();

final class GrowthMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GrowthMember>>,
          List<GrowthMember>,
          FutureOr<List<GrowthMember>>
        >
    with
        $FutureModifier<List<GrowthMember>>,
        $FutureProvider<List<GrowthMember>> {
  GrowthMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'growthMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$growthMembersHash();

  @$internal
  @override
  $FutureProviderElement<List<GrowthMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GrowthMember>> create(Ref ref) {
    return growthMembers(ref);
  }
}

String _$growthMembersHash() => r'1f98ea0fc0596fe63b7e03a34c18c95d1c56cc79';

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
        isAutoDispose: true,
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

String _$leadStagesHash() => r'902b8f9317f85fbaf942ea0634650cd5ea00e967';

/// Assign and reject from the list or the detail; callers show the outcome.

@ProviderFor(InboxActions)
final inboxActionsProvider = InboxActionsProvider._();

/// Assign and reject from the list or the detail; callers show the outcome.
final class InboxActionsProvider extends $NotifierProvider<InboxActions, void> {
  /// Assign and reject from the list or the detail; callers show the outcome.
  InboxActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxActionsHash();

  @$internal
  @override
  InboxActions create() => InboxActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$inboxActionsHash() => r'92a80df0e9858e9bc6a94f788a3f5ff4ba16f5f1';

/// Assign and reject from the list or the detail; callers show the outcome.

abstract class _$InboxActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Accepting an inbox lead into the main list (#138).

@ProviderFor(AcceptLeadSubmit)
final acceptLeadSubmitProvider = AcceptLeadSubmitFamily._();

/// Accepting an inbox lead into the main list (#138).
final class AcceptLeadSubmitProvider
    extends $NotifierProvider<AcceptLeadSubmit, AsyncValue<InboxLead?>> {
  /// Accepting an inbox lead into the main list (#138).
  AcceptLeadSubmitProvider._({
    required AcceptLeadSubmitFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'acceptLeadSubmitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$acceptLeadSubmitHash();

  @override
  String toString() {
    return r'acceptLeadSubmitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AcceptLeadSubmit create() => AcceptLeadSubmit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<InboxLead?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<InboxLead?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AcceptLeadSubmitProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$acceptLeadSubmitHash() => r'bf9e2615382af89177de5510348749b100490cca';

/// Accepting an inbox lead into the main list (#138).

final class AcceptLeadSubmitFamily extends $Family
    with
        $ClassFamilyOverride<
          AcceptLeadSubmit,
          AsyncValue<InboxLead?>,
          AsyncValue<InboxLead?>,
          AsyncValue<InboxLead?>,
          int
        > {
  AcceptLeadSubmitFamily._()
    : super(
        retry: null,
        name: r'acceptLeadSubmitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Accepting an inbox lead into the main list (#138).

  AcceptLeadSubmitProvider call(int id) =>
      AcceptLeadSubmitProvider._(argument: id, from: this);

  @override
  String toString() => r'acceptLeadSubmitProvider';
}

/// Accepting an inbox lead into the main list (#138).

abstract class _$AcceptLeadSubmit extends $Notifier<AsyncValue<InboxLead?>> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  AsyncValue<InboxLead?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<InboxLead?>, AsyncValue<InboxLead?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InboxLead?>, AsyncValue<InboxLead?>>,
              AsyncValue<InboxLead?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

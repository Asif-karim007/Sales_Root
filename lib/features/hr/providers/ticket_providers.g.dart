// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticketRepository)
final ticketRepositoryProvider = TicketRepositoryProvider._();

final class TicketRepositoryProvider
    extends
        $FunctionalProvider<
          TicketRepository,
          TicketRepository,
          TicketRepository
        >
    with $Provider<TicketRepository> {
  TicketRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketRepositoryHash();

  @$internal
  @override
  $ProviderElement<TicketRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TicketRepository create(Ref ref) {
    return ticketRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketRepository>(value),
    );
  }
}

String _$ticketRepositoryHash() => r'0cbfd6818be773ccabf2f0859846af908c6b141b';

@ProviderFor(ticketProducts)
final ticketProductsProvider = TicketProductsProvider._();

final class TicketProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TicketProduct>>,
          List<TicketProduct>,
          FutureOr<List<TicketProduct>>
        >
    with
        $FutureModifier<List<TicketProduct>>,
        $FutureProvider<List<TicketProduct>> {
  TicketProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<TicketProduct>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TicketProduct>> create(Ref ref) {
    return ticketProducts(ref);
  }
}

String _$ticketProductsHash() => r'ee5d53736a9effbd5682adad7f1ff228b787f3af';

@ProviderFor(ticket)
final ticketProvider = TicketFamily._();

final class TicketProvider
    extends $FunctionalProvider<AsyncValue<Ticket>, Ticket, FutureOr<Ticket>>
    with $FutureModifier<Ticket>, $FutureProvider<Ticket> {
  TicketProvider._({
    required TicketFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'ticketProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketHash();

  @override
  String toString() {
    return r'ticketProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Ticket> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Ticket> create(Ref ref) {
    final argument = this.argument as int;
    return ticket(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketHash() => r'9b08649c8fb95d5122fbd749240afa3be2fbfa46';

final class TicketFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Ticket>, int> {
  TicketFamily._()
    : super(
        retry: null,
        name: r'ticketProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TicketProvider call(int id) => TicketProvider._(argument: id, from: this);

  @override
  String toString() => r'ticketProvider';
}

@ProviderFor(TicketFormNotifier)
final ticketFormProvider = TicketFormNotifierProvider._();

final class TicketFormNotifierProvider
    extends $NotifierProvider<TicketFormNotifier, TicketFormState> {
  TicketFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketFormNotifierHash();

  @$internal
  @override
  TicketFormNotifier create() => TicketFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicketFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicketFormState>(value),
    );
  }
}

String _$ticketFormNotifierHash() =>
    r'5cfae8f59f467c0d712f2bfc1ba864e9035197a9';

abstract class _$TicketFormNotifier extends $Notifier<TicketFormState> {
  TicketFormState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TicketFormState, TicketFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TicketFormState, TicketFormState>,
              TicketFormState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Status changes and replies on one ticket; the state names the last one
/// that went through.

@ProviderFor(TicketActionsNotifier)
final ticketActionsProvider = TicketActionsNotifierFamily._();

/// Status changes and replies on one ticket; the state names the last one
/// that went through.
final class TicketActionsNotifierProvider
    extends
        $NotifierProvider<TicketActionsNotifier, AsyncValue<TicketAction?>> {
  /// Status changes and replies on one ticket; the state names the last one
  /// that went through.
  TicketActionsNotifierProvider._({
    required TicketActionsNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'ticketActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketActionsNotifierHash();

  @override
  String toString() {
    return r'ticketActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TicketActionsNotifier create() => TicketActionsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<TicketAction?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<TicketAction?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TicketActionsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketActionsNotifierHash() =>
    r'3cb8f253e35c1b875bdfb9c086dd7ad06c333e46';

/// Status changes and replies on one ticket; the state names the last one
/// that went through.

final class TicketActionsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TicketActionsNotifier,
          AsyncValue<TicketAction?>,
          AsyncValue<TicketAction?>,
          AsyncValue<TicketAction?>,
          int
        > {
  TicketActionsNotifierFamily._()
    : super(
        retry: null,
        name: r'ticketActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Status changes and replies on one ticket; the state names the last one
  /// that went through.

  TicketActionsNotifierProvider call(int id) =>
      TicketActionsNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'ticketActionsProvider';
}

/// Status changes and replies on one ticket; the state names the last one
/// that went through.

abstract class _$TicketActionsNotifier
    extends $Notifier<AsyncValue<TicketAction?>> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  AsyncValue<TicketAction?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TicketAction?>, AsyncValue<TicketAction?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TicketAction?>, AsyncValue<TicketAction?>>,
              AsyncValue<TicketAction?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

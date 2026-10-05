// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ticket)
final ticketProvider = TicketFamily._();

final class TicketProvider
    extends $FunctionalProvider<AsyncValue<Ticket>, Ticket, FutureOr<Ticket>>
    with $FutureModifier<Ticket>, $FutureProvider<Ticket> {
  TicketProvider._({
    required TicketFamily super.from,
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$ticketHash() => r'7a1fe311b9dc2fa08337b259d7816619d810368d';

final class TicketFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Ticket>, String> {
  TicketFamily._()
    : super(
        retry: null,
        name: r'ticketProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TicketProvider call(String id) => TicketProvider._(argument: id, from: this);

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
    required String super.argument,
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
    r'af869e1d6a4de617ef9682781cf785428775bf98';

/// Status changes and replies on one ticket; the state names the last one
/// that went through.

final class TicketActionsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TicketActionsNotifier,
          AsyncValue<TicketAction?>,
          AsyncValue<TicketAction?>,
          AsyncValue<TicketAction?>,
          String
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

  TicketActionsNotifierProvider call(String id) =>
      TicketActionsNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'ticketActionsProvider';
}

/// Status changes and replies on one ticket; the state names the last one
/// that went through.

abstract class _$TicketActionsNotifier
    extends $Notifier<AsyncValue<TicketAction?>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  AsyncValue<TicketAction?> build(String id);
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

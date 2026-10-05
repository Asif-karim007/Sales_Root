// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's support requests.

@ProviderFor(myTickets)
final myTicketsProvider = MyTicketsProvider._();

/// The user's support requests.

final class MyTicketsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SupportTicket>>,
          List<SupportTicket>,
          FutureOr<List<SupportTicket>>
        >
    with
        $FutureModifier<List<SupportTicket>>,
        $FutureProvider<List<SupportTicket>> {
  /// The user's support requests.
  MyTicketsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myTicketsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myTicketsHash();

  @$internal
  @override
  $FutureProviderElement<List<SupportTicket>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SupportTicket>> create(Ref ref) {
    return myTickets(ref);
  }
}

String _$myTicketsHash() => r'4d7537d751141ef436a3655724d2ae083590c32d';

@ProviderFor(SupportTicketNotifier)
final supportTicketProvider = SupportTicketNotifierFamily._();

final class SupportTicketNotifierProvider
    extends $AsyncNotifierProvider<SupportTicketNotifier, TicketThread> {
  SupportTicketNotifierProvider._({
    required SupportTicketNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'supportTicketProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$supportTicketNotifierHash();

  @override
  String toString() {
    return r'supportTicketProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SupportTicketNotifier create() => SupportTicketNotifier();

  @override
  bool operator ==(Object other) {
    return other is SupportTicketNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$supportTicketNotifierHash() =>
    r'29dc41ea0ebc2fbcc0b6048b9d808d0066295b94';

final class SupportTicketNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SupportTicketNotifier,
          AsyncValue<TicketThread>,
          TicketThread,
          FutureOr<TicketThread>,
          String
        > {
  SupportTicketNotifierFamily._()
    : super(
        retry: null,
        name: r'supportTicketProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SupportTicketNotifierProvider call(String id) =>
      SupportTicketNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'supportTicketProvider';
}

abstract class _$SupportTicketNotifier extends $AsyncNotifier<TicketThread> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<TicketThread> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TicketThread>, TicketThread>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TicketThread>, TicketThread>,
              AsyncValue<TicketThread>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Sends a new support request; holds the created ticket once sent.

@ProviderFor(NewTicketNotifier)
final newTicketProvider = NewTicketNotifierProvider._();

/// Sends a new support request; holds the created ticket once sent.
final class NewTicketNotifierProvider
    extends $AsyncNotifierProvider<NewTicketNotifier, SupportTicket?> {
  /// Sends a new support request; holds the created ticket once sent.
  NewTicketNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newTicketProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newTicketNotifierHash();

  @$internal
  @override
  NewTicketNotifier create() => NewTicketNotifier();
}

String _$newTicketNotifierHash() => r'cd2948e0375723f6bf01b49eba7114d2ce553763';

/// Sends a new support request; holds the created ticket once sent.

abstract class _$NewTicketNotifier extends $AsyncNotifier<SupportTicket?> {
  FutureOr<SupportTicket?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SupportTicket?>, SupportTicket?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SupportTicket?>, SupportTicket?>,
              AsyncValue<SupportTicket?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

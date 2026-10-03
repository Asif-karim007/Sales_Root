// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supportRepository)
final supportRepositoryProvider = SupportRepositoryProvider._();

final class SupportRepositoryProvider
    extends
        $FunctionalProvider<
          SupportRepository,
          SupportRepository,
          SupportRepository
        >
    with $Provider<SupportRepository> {
  SupportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupportRepository create(Ref ref) {
    return supportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupportRepository>(value),
    );
  }
}

String _$supportRepositoryHash() => r'5a56c1f6994996d7441253487d4aa10d6064e529';

/// The user's support requests, refreshed when support answers one.

@ProviderFor(MyTicketsNotifier)
final myTicketsProvider = MyTicketsNotifierProvider._();

/// The user's support requests, refreshed when support answers one.
final class MyTicketsNotifierProvider
    extends $AsyncNotifierProvider<MyTicketsNotifier, Paged<SupportTicket>> {
  /// The user's support requests, refreshed when support answers one.
  MyTicketsNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$myTicketsNotifierHash();

  @$internal
  @override
  MyTicketsNotifier create() => MyTicketsNotifier();
}

String _$myTicketsNotifierHash() => r'546a621c5e237cf82a09e136f5297218a0d1a487';

/// The user's support requests, refreshed when support answers one.

abstract class _$MyTicketsNotifier
    extends $AsyncNotifier<Paged<SupportTicket>> {
  FutureOr<Paged<SupportTicket>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Paged<SupportTicket>>, Paged<SupportTicket>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Paged<SupportTicket>>,
                Paged<SupportTicket>
              >,
              AsyncValue<Paged<SupportTicket>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SupportTicketNotifier)
final supportTicketProvider = SupportTicketNotifierFamily._();

final class SupportTicketNotifierProvider
    extends $AsyncNotifierProvider<SupportTicketNotifier, TicketThread> {
  SupportTicketNotifierProvider._({
    required SupportTicketNotifierFamily super.from,
    required int super.argument,
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
    r'e8940c4266a4e77a8697fb006db06261fe378b7b';

final class SupportTicketNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SupportTicketNotifier,
          AsyncValue<TicketThread>,
          TicketThread,
          FutureOr<TicketThread>,
          int
        > {
  SupportTicketNotifierFamily._()
    : super(
        retry: null,
        name: r'supportTicketProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SupportTicketNotifierProvider call(int id) =>
      SupportTicketNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'supportTicketProvider';
}

abstract class _$SupportTicketNotifier extends $AsyncNotifier<TicketThread> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<TicketThread> build(int id);
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

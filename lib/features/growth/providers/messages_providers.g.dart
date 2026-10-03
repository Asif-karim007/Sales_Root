// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messagesRepository)
final messagesRepositoryProvider = MessagesRepositoryProvider._();

final class MessagesRepositoryProvider
    extends
        $FunctionalProvider<
          MessagesRepository,
          MessagesRepository,
          MessagesRepository
        >
    with $Provider<MessagesRepository> {
  MessagesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessagesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessagesRepository create(Ref ref) {
    return messagesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesRepository>(value),
    );
  }
}

String _$messagesRepositoryHash() =>
    r'31f0b7831ac9548039a56cadf3221b76cf5add26';

@ProviderFor(ThreadFilterNotifier)
final threadFilterProvider = ThreadFilterNotifierProvider._();

final class ThreadFilterNotifierProvider
    extends $NotifierProvider<ThreadFilterNotifier, ThreadFilter> {
  ThreadFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'threadFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$threadFilterNotifierHash();

  @$internal
  @override
  ThreadFilterNotifier create() => ThreadFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThreadFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThreadFilter>(value),
    );
  }
}

String _$threadFilterNotifierHash() =>
    r'aa2f276b8d9a26a0722bfbec09fc318ad49168ec';

abstract class _$ThreadFilterNotifier extends $Notifier<ThreadFilter> {
  ThreadFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThreadFilter, ThreadFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThreadFilter, ThreadFilter>,
              ThreadFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The unified inbox (#141), latest conversation first.

@ProviderFor(ThreadListNotifier)
final threadListProvider = ThreadListNotifierProvider._();

/// The unified inbox (#141), latest conversation first.
final class ThreadListNotifierProvider
    extends $AsyncNotifierProvider<ThreadListNotifier, Paged<MessageThread>> {
  /// The unified inbox (#141), latest conversation first.
  ThreadListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'threadListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$threadListNotifierHash();

  @$internal
  @override
  ThreadListNotifier create() => ThreadListNotifier();
}

String _$threadListNotifierHash() =>
    r'403857324df82b617dff0ed2936301877ac12a44';

/// The unified inbox (#141), latest conversation first.

abstract class _$ThreadListNotifier
    extends $AsyncNotifier<Paged<MessageThread>> {
  FutureOr<Paged<MessageThread>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Paged<MessageThread>>, Paged<MessageThread>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Paged<MessageThread>>,
                Paged<MessageThread>
              >,
              AsyncValue<Paged<MessageThread>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(messagingAccount)
final messagingAccountProvider = MessagingAccountProvider._();

final class MessagingAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<MessagingAccount>,
          MessagingAccount,
          FutureOr<MessagingAccount>
        >
    with $FutureModifier<MessagingAccount>, $FutureProvider<MessagingAccount> {
  MessagingAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagingAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagingAccountHash();

  @$internal
  @override
  $FutureProviderElement<MessagingAccount> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MessagingAccount> create(Ref ref) {
    return messagingAccount(ref);
  }
}

String _$messagingAccountHash() => r'b479c567a243ac6e913fd1d75a52185a88465688';

@ProviderFor(messageThread)
final messageThreadProvider = MessageThreadFamily._();

final class MessageThreadProvider
    extends
        $FunctionalProvider<
          AsyncValue<MessageThread>,
          MessageThread,
          FutureOr<MessageThread>
        >
    with $FutureModifier<MessageThread>, $FutureProvider<MessageThread> {
  MessageThreadProvider._({
    required MessageThreadFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'messageThreadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageThreadHash();

  @override
  String toString() {
    return r'messageThreadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MessageThread> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MessageThread> create(Ref ref) {
    final argument = this.argument as int;
    return messageThread(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageThreadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageThreadHash() => r'dbf58c43fb65b743aadebf2eacd2a6f2836b01f3';

final class MessageThreadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MessageThread>, int> {
  MessageThreadFamily._()
    : super(
        retry: null,
        name: r'messageThreadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MessageThreadProvider call(int id) =>
      MessageThreadProvider._(argument: id, from: this);

  @override
  String toString() => r'messageThreadProvider';
}

@ProviderFor(threadMessages)
final threadMessagesProvider = ThreadMessagesFamily._();

final class ThreadMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ThreadMessage>>,
          List<ThreadMessage>,
          Stream<List<ThreadMessage>>
        >
    with
        $FutureModifier<List<ThreadMessage>>,
        $StreamProvider<List<ThreadMessage>> {
  ThreadMessagesProvider._({
    required ThreadMessagesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'threadMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$threadMessagesHash();

  @override
  String toString() {
    return r'threadMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ThreadMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ThreadMessage>> create(Ref ref) {
    final argument = this.argument as int;
    return threadMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ThreadMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$threadMessagesHash() => r'fdeaf1e51c2496a88ac4788702a95ec1d5b58309';

final class ThreadMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ThreadMessage>>, int> {
  ThreadMessagesFamily._()
    : super(
        retry: null,
        name: r'threadMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ThreadMessagesProvider call(int id) =>
      ThreadMessagesProvider._(argument: id, from: this);

  @override
  String toString() => r'threadMessagesProvider';
}

@ProviderFor(messageTemplates)
final messageTemplatesProvider = MessageTemplatesProvider._();

final class MessageTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageTemplate>>,
          List<MessageTemplate>,
          FutureOr<List<MessageTemplate>>
        >
    with
        $FutureModifier<List<MessageTemplate>>,
        $FutureProvider<List<MessageTemplate>> {
  MessageTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageTemplatesHash();

  @$internal
  @override
  $FutureProviderElement<List<MessageTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MessageTemplate>> create(Ref ref) {
    return messageTemplates(ref);
  }
}

String _$messageTemplatesHash() => r'61b5ceb8d01e80947b2ab9c08ba1d7a001b40294';

/// Sending, reading and assigning in a conversation; callers show the
/// outcome.

@ProviderFor(MessageActions)
final messageActionsProvider = MessageActionsProvider._();

/// Sending, reading and assigning in a conversation; callers show the
/// outcome.
final class MessageActionsProvider
    extends $NotifierProvider<MessageActions, void> {
  /// Sending, reading and assigning in a conversation; callers show the
  /// outcome.
  MessageActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageActionsHash();

  @$internal
  @override
  MessageActions create() => MessageActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$messageActionsHash() => r'38b66b1413120f6c19902744c01602fe0d5e44c6';

/// Sending, reading and assigning in a conversation; callers show the
/// outcome.

abstract class _$MessageActions extends $Notifier<void> {
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

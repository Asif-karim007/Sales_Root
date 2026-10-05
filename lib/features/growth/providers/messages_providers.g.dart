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
    r'4f8a2476ba08cfb8d4a33f2a48bb74d23bbad107';

@ProviderFor(ThreadBoxNotifier)
final threadBoxProvider = ThreadBoxNotifierProvider._();

final class ThreadBoxNotifierProvider
    extends $NotifierProvider<ThreadBoxNotifier, ConversationBox> {
  ThreadBoxNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'threadBoxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$threadBoxNotifierHash();

  @$internal
  @override
  ThreadBoxNotifier create() => ThreadBoxNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationBox value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationBox>(value),
    );
  }
}

String _$threadBoxNotifierHash() => r'3850437c6ea35f992eba90fadbc6f5b1057066e7';

abstract class _$ThreadBoxNotifier extends $Notifier<ConversationBox> {
  ConversationBox build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ConversationBox, ConversationBox>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConversationBox, ConversationBox>,
              ConversationBox,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The unified inbox (#141): every conversation, latest first.

@ProviderFor(ThreadListNotifier)
final threadListProvider = ThreadListNotifierProvider._();

/// The unified inbox (#141): every conversation, latest first.
final class ThreadListNotifierProvider
    extends $AsyncNotifierProvider<ThreadListNotifier, Paged<Conversation>> {
  /// The unified inbox (#141): every conversation, latest first.
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
    r'32adfe62f85d25fe3b217e0382f4374bb581bc6b';

/// The unified inbox (#141): every conversation, latest first.

abstract class _$ThreadListNotifier
    extends $AsyncNotifier<Paged<Conversation>> {
  FutureOr<Paged<Conversation>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<Conversation>>, Paged<Conversation>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Conversation>>, Paged<Conversation>>,
              AsyncValue<Paged<Conversation>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The Page and number the inbox is connected to, e.g. "Rahim Traders ·
/// +8801711…"; null when nothing is connected or the list is out of reach.

@ProviderFor(messagingAccount)
final messagingAccountProvider = MessagingAccountProvider._();

/// The Page and number the inbox is connected to, e.g. "Rahim Traders ·
/// +8801711…"; null when nothing is connected or the list is out of reach.

final class MessagingAccountProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The Page and number the inbox is connected to, e.g. "Rahim Traders ·
  /// +8801711…"; null when nothing is connected or the list is out of reach.
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
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return messagingAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$messagingAccountHash() => r'6f72558cfd8734e958f499c16a5faa4132954b33';

/// Templates for one channel, e.g. `whatsapp` or `sms`.

@ProviderFor(messageTemplates)
final messageTemplatesProvider = MessageTemplatesFamily._();

/// Templates for one channel, e.g. `whatsapp` or `sms`.

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
  /// Templates for one channel, e.g. `whatsapp` or `sms`.
  MessageTemplatesProvider._({
    required MessageTemplatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageTemplatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageTemplatesHash();

  @override
  String toString() {
    return r'messageTemplatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MessageTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MessageTemplate>> create(Ref ref) {
    final argument = this.argument as String;
    return messageTemplates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageTemplatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageTemplatesHash() => r'42e459d85d78be30d4b2c58986bfe0a93ed95a5e';

/// Templates for one channel, e.g. `whatsapp` or `sms`.

final class MessageTemplatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MessageTemplate>>, String> {
  MessageTemplatesFamily._()
    : super(
        retry: null,
        name: r'messageTemplatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Templates for one channel, e.g. `whatsapp` or `sms`.

  MessageTemplatesProvider call(String channel) =>
      MessageTemplatesProvider._(argument: channel, from: this);

  @override
  String toString() => r'messageTemplatesProvider';
}

/// An AI reply for a conversation tied to a lead or customer; null when it
/// is with someone the CRM doesn't know yet.

@ProviderFor(replyDraft)
final replyDraftProvider = ReplyDraftFamily._();

/// An AI reply for a conversation tied to a lead or customer; null when it
/// is with someone the CRM doesn't know yet.

final class ReplyDraftProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// An AI reply for a conversation tied to a lead or customer; null when it
  /// is with someone the CRM doesn't know yet.
  ReplyDraftProvider._({
    required ReplyDraftFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'replyDraftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$replyDraftHash();

  @override
  String toString() {
    return r'replyDraftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return replyDraft(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReplyDraftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$replyDraftHash() => r'd4185d24f7e6fd863a3ae22c19b88d3215f05322';

/// An AI reply for a conversation tied to a lead or customer; null when it
/// is with someone the CRM doesn't know yet.

final class ReplyDraftFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  ReplyDraftFamily._()
    : super(
        retry: null,
        name: r'replyDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// An AI reply for a conversation tied to a lead or customer; null when it
  /// is with someone the CRM doesn't know yet.

  ReplyDraftProvider call(String conversationId) =>
      ReplyDraftProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'replyDraftProvider';
}

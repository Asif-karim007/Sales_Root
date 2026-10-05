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
    r'a432caea6e718a55f8fb44bfde2994012af9228b';

/// The signed-in member's membership id, to tell their conversations apart.

@ProviderFor(myMembershipId)
final myMembershipIdProvider = MyMembershipIdProvider._();

/// The signed-in member's membership id, to tell their conversations apart.

final class MyMembershipIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The signed-in member's membership id, to tell their conversations apart.
  MyMembershipIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myMembershipIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myMembershipIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return myMembershipId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$myMembershipIdHash() => r'f68b0edd9b5ebd09e5d1e96190950a34877931be';

@ProviderFor(InboxBoxNotifier)
final inboxBoxProvider = InboxBoxNotifierProvider._();

final class InboxBoxNotifierProvider
    extends $NotifierProvider<InboxBoxNotifier, ConversationBox> {
  InboxBoxNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxBoxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxBoxNotifierHash();

  @$internal
  @override
  InboxBoxNotifier create() => InboxBoxNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationBox value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationBox>(value),
    );
  }
}

String _$inboxBoxNotifierHash() => r'e0a9b247b9cb08a90dd18708fa5aad64fe67b075';

abstract class _$InboxBoxNotifier extends $Notifier<ConversationBox> {
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

/// The new-leads inbox (#136): open conversations, newest first.

@ProviderFor(InboxListNotifier)
final inboxListProvider = InboxListNotifierProvider._();

/// The new-leads inbox (#136): open conversations, newest first.
final class InboxListNotifierProvider
    extends $AsyncNotifierProvider<InboxListNotifier, Paged<Conversation>> {
  /// The new-leads inbox (#136): open conversations, newest first.
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

String _$inboxListNotifierHash() => r'e033d570bc3c1f61b18ba155a77d914ec23c112a';

/// The new-leads inbox (#136): open conversations, newest first.

abstract class _$InboxListNotifier extends $AsyncNotifier<Paged<Conversation>> {
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

/// One conversation with its messages.

@ProviderFor(conversation)
final conversationProvider = ConversationFamily._();

/// One conversation with its messages.

final class ConversationProvider
    extends
        $FunctionalProvider<
          AsyncValue<Conversation>,
          Conversation,
          FutureOr<Conversation>
        >
    with $FutureModifier<Conversation>, $FutureProvider<Conversation> {
  /// One conversation with its messages.
  ConversationProvider._({
    required ConversationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationHash();

  @override
  String toString() {
    return r'conversationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Conversation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Conversation> create(Ref ref) {
    final argument = this.argument as String;
    return conversation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationHash() => r'119c176b67f39b85edc4dfd66ca00854d92c03d1';

/// One conversation with its messages.

final class ConversationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Conversation>, String> {
  ConversationFamily._()
    : super(
        retry: null,
        name: r'conversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One conversation with its messages.

  ConversationProvider call(String id) =>
      ConversationProvider._(argument: id, from: this);

  @override
  String toString() => r'conversationProvider';
}

@ProviderFor(inboxMembers)
final inboxMembersProvider = InboxMembersProvider._();

final class InboxMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GrowthMember>>,
          List<GrowthMember>,
          FutureOr<List<GrowthMember>>
        >
    with
        $FutureModifier<List<GrowthMember>>,
        $FutureProvider<List<GrowthMember>> {
  InboxMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxMembersHash();

  @$internal
  @override
  $FutureProviderElement<List<GrowthMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GrowthMember>> create(Ref ref) {
    return inboxMembers(ref);
  }
}

String _$inboxMembersHash() => r'099a189fc3e81ffbc59ef1b61d7519b7a29ebfb9';

/// Take, assign, close and reply, from the lists or a conversation;
/// callers show the outcome.

@ProviderFor(InboxActions)
final inboxActionsProvider = InboxActionsProvider._();

/// Take, assign, close and reply, from the lists or a conversation;
/// callers show the outcome.
final class InboxActionsProvider extends $NotifierProvider<InboxActions, void> {
  /// Take, assign, close and reply, from the lists or a conversation;
  /// callers show the outcome.
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

String _$inboxActionsHash() => r'4db7859f875cdc63da087d7f214317602cdfca6b';

/// Take, assign, close and reply, from the lists or a conversation;
/// callers show the outcome.

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

/// Accepting an enquiry (#138): the member takes the conversation, then
/// finishes the lead.

@ProviderFor(AcceptLeadSubmit)
final acceptLeadSubmitProvider = AcceptLeadSubmitFamily._();

/// Accepting an enquiry (#138): the member takes the conversation, then
/// finishes the lead.
final class AcceptLeadSubmitProvider
    extends $NotifierProvider<AcceptLeadSubmit, AsyncValue<Conversation?>> {
  /// Accepting an enquiry (#138): the member takes the conversation, then
  /// finishes the lead.
  AcceptLeadSubmitProvider._({
    required AcceptLeadSubmitFamily super.from,
    required String super.argument,
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
  Override overrideWithValue(AsyncValue<Conversation?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Conversation?>>(value),
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

String _$acceptLeadSubmitHash() => r'39a32377b16655e81916225d2d84579fe6034d6a';

/// Accepting an enquiry (#138): the member takes the conversation, then
/// finishes the lead.

final class AcceptLeadSubmitFamily extends $Family
    with
        $ClassFamilyOverride<
          AcceptLeadSubmit,
          AsyncValue<Conversation?>,
          AsyncValue<Conversation?>,
          AsyncValue<Conversation?>,
          String
        > {
  AcceptLeadSubmitFamily._()
    : super(
        retry: null,
        name: r'acceptLeadSubmitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Accepting an enquiry (#138): the member takes the conversation, then
  /// finishes the lead.

  AcceptLeadSubmitProvider call(String id) =>
      AcceptLeadSubmitProvider._(argument: id, from: this);

  @override
  String toString() => r'acceptLeadSubmitProvider';
}

/// Accepting an enquiry (#138): the member takes the conversation, then
/// finishes the lead.

abstract class _$AcceptLeadSubmit extends $Notifier<AsyncValue<Conversation?>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  AsyncValue<Conversation?> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Conversation?>, AsyncValue<Conversation?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Conversation?>, AsyncValue<Conversation?>>,
              AsyncValue<Conversation?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

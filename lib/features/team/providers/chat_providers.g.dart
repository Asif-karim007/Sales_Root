// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'6db79b53bce06d61acf2252f9053730d7721a4d0';

@ProviderFor(ChatSearchNotifier)
final chatSearchProvider = ChatSearchNotifierProvider._();

final class ChatSearchNotifierProvider
    extends $NotifierProvider<ChatSearchNotifier, String> {
  ChatSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatSearchNotifierHash();

  @$internal
  @override
  ChatSearchNotifier create() => ChatSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$chatSearchNotifierHash() =>
    r'db9385c78d22e9fe015f45a82bd940b8d98807e1';

abstract class _$ChatSearchNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The user's threads; reloads by itself when a message comes in.

@ProviderFor(ChatListNotifier)
final chatListProvider = ChatListNotifierProvider._();

/// The user's threads; reloads by itself when a message comes in.
final class ChatListNotifierProvider
    extends $AsyncNotifierProvider<ChatListNotifier, Paged<ChatThread>> {
  /// The user's threads; reloads by itself when a message comes in.
  ChatListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatListNotifierHash();

  @$internal
  @override
  ChatListNotifier create() => ChatListNotifier();
}

String _$chatListNotifierHash() => r'd9810b900c53851e7c6b5eb0b380bac1402109ba';

/// The user's threads; reloads by itself when a message comes in.

abstract class _$ChatListNotifier extends $AsyncNotifier<Paged<ChatThread>> {
  FutureOr<Paged<ChatThread>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<ChatThread>>, Paged<ChatThread>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<ChatThread>>, Paged<ChatThread>>,
              AsyncValue<Paged<ChatThread>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(OversightScopeNotifier)
final oversightScopeProvider = OversightScopeNotifierProvider._();

final class OversightScopeNotifierProvider
    extends $NotifierProvider<OversightScopeNotifier, ChatScope> {
  OversightScopeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oversightScopeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oversightScopeNotifierHash();

  @$internal
  @override
  OversightScopeNotifier create() => OversightScopeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatScope value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatScope>(value),
    );
  }
}

String _$oversightScopeNotifierHash() =>
    r'cf49b3804831261a55e43505fb81ff7ea2d572b6';

abstract class _$OversightScopeNotifier extends $Notifier<ChatScope> {
  ChatScope build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChatScope, ChatScope>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatScope, ChatScope>,
              ChatScope,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Every thread in the workspace, for the owner.

@ProviderFor(OversightListNotifier)
final oversightListProvider = OversightListNotifierProvider._();

/// Every thread in the workspace, for the owner.
final class OversightListNotifierProvider
    extends $AsyncNotifierProvider<OversightListNotifier, Paged<ChatThread>> {
  /// Every thread in the workspace, for the owner.
  OversightListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oversightListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oversightListNotifierHash();

  @$internal
  @override
  OversightListNotifier create() => OversightListNotifier();
}

String _$oversightListNotifierHash() =>
    r'96c5872c841998a4ce8a5aaa6db14665819d7583';

/// Every thread in the workspace, for the owner.

abstract class _$OversightListNotifier
    extends $AsyncNotifier<Paged<ChatThread>> {
  FutureOr<Paged<ChatThread>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<ChatThread>>, Paged<ChatThread>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<ChatThread>>, Paged<ChatThread>>,
              AsyncValue<Paged<ChatThread>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(chatThread)
final chatThreadProvider = ChatThreadFamily._();

final class ChatThreadProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChatThread>,
          ChatThread,
          FutureOr<ChatThread>
        >
    with $FutureModifier<ChatThread>, $FutureProvider<ChatThread> {
  ChatThreadProvider._({
    required ChatThreadFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'chatThreadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatThreadHash();

  @override
  String toString() {
    return r'chatThreadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ChatThread> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ChatThread> create(Ref ref) {
    final argument = this.argument as int;
    return chatThread(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatThreadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatThreadHash() => r'df926a94d3741f65804c2ea4a1d6f514947090e5';

final class ChatThreadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ChatThread>, int> {
  ChatThreadFamily._()
    : super(
        retry: null,
        name: r'chatThreadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatThreadProvider call(int id) =>
      ChatThreadProvider._(argument: id, from: this);

  @override
  String toString() => r'chatThreadProvider';
}

/// One open thread, live: the first page of messages, then every message,
/// typing change and receipt the server pushes.

@ProviderFor(ChatRoomNotifier)
final chatRoomProvider = ChatRoomNotifierFamily._();

/// One open thread, live: the first page of messages, then every message,
/// typing change and receipt the server pushes.
final class ChatRoomNotifierProvider
    extends $StreamNotifierProvider<ChatRoomNotifier, ChatRoom> {
  /// One open thread, live: the first page of messages, then every message,
  /// typing change and receipt the server pushes.
  ChatRoomNotifierProvider._({
    required ChatRoomNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'chatRoomProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatRoomNotifierHash();

  @override
  String toString() {
    return r'chatRoomProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatRoomNotifier create() => ChatRoomNotifier();

  @override
  bool operator ==(Object other) {
    return other is ChatRoomNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatRoomNotifierHash() => r'6f8a243fbafcc487bd04eaa67862e4a6f802d087';

/// One open thread, live: the first page of messages, then every message,
/// typing change and receipt the server pushes.

final class ChatRoomNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatRoomNotifier,
          AsyncValue<ChatRoom>,
          ChatRoom,
          Stream<ChatRoom>,
          int
        > {
  ChatRoomNotifierFamily._()
    : super(
        retry: null,
        name: r'chatRoomProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One open thread, live: the first page of messages, then every message,
  /// typing change and receipt the server pushes.

  ChatRoomNotifierProvider call(int threadId) =>
      ChatRoomNotifierProvider._(argument: threadId, from: this);

  @override
  String toString() => r'chatRoomProvider';
}

/// One open thread, live: the first page of messages, then every message,
/// typing change and receipt the server pushes.

abstract class _$ChatRoomNotifier extends $StreamNotifier<ChatRoom> {
  late final _$args = ref.$arg as int;
  int get threadId => _$args;

  Stream<ChatRoom> build(int threadId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChatRoom>, ChatRoom>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChatRoom>, ChatRoom>,
              AsyncValue<ChatRoom>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Opens a lead discussion or a direct chat, or creates a group; the screen
/// listens for the thread to go to.

@ProviderFor(ChatOpener)
final chatOpenerProvider = ChatOpenerProvider._();

/// Opens a lead discussion or a direct chat, or creates a group; the screen
/// listens for the thread to go to.
final class ChatOpenerProvider
    extends $AsyncNotifierProvider<ChatOpener, ChatThread?> {
  /// Opens a lead discussion or a direct chat, or creates a group; the screen
  /// listens for the thread to go to.
  ChatOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatOpenerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatOpenerHash();

  @$internal
  @override
  ChatOpener create() => ChatOpener();
}

String _$chatOpenerHash() => r'0e91efa0f2db6ca3a1d8fa786b8787321432789d';

/// Opens a lead discussion or a direct chat, or creates a group; the screen
/// listens for the thread to go to.

abstract class _$ChatOpener extends $AsyncNotifier<ChatThread?> {
  FutureOr<ChatThread?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChatThread?>, ChatThread?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChatThread?>, ChatThread?>,
              AsyncValue<ChatThread?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Settings, members and leaving for one thread.

@ProviderFor(ChatThreadEditor)
final chatThreadEditorProvider = ChatThreadEditorFamily._();

/// Settings, members and leaving for one thread.
final class ChatThreadEditorProvider
    extends $AsyncNotifierProvider<ChatThreadEditor, ChatEditOutcome?> {
  /// Settings, members and leaving for one thread.
  ChatThreadEditorProvider._({
    required ChatThreadEditorFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'chatThreadEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatThreadEditorHash();

  @override
  String toString() {
    return r'chatThreadEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatThreadEditor create() => ChatThreadEditor();

  @override
  bool operator ==(Object other) {
    return other is ChatThreadEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatThreadEditorHash() => r'360bba830a4d725d01c8ddec7f8a3328c53f1cb0';

/// Settings, members and leaving for one thread.

final class ChatThreadEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatThreadEditor,
          AsyncValue<ChatEditOutcome?>,
          ChatEditOutcome?,
          FutureOr<ChatEditOutcome?>,
          int
        > {
  ChatThreadEditorFamily._()
    : super(
        retry: null,
        name: r'chatThreadEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Settings, members and leaving for one thread.

  ChatThreadEditorProvider call(int threadId) =>
      ChatThreadEditorProvider._(argument: threadId, from: this);

  @override
  String toString() => r'chatThreadEditorProvider';
}

/// Settings, members and leaving for one thread.

abstract class _$ChatThreadEditor extends $AsyncNotifier<ChatEditOutcome?> {
  late final _$args = ref.$arg as int;
  int get threadId => _$args;

  FutureOr<ChatEditOutcome?> build(int threadId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ChatEditOutcome?>, ChatEditOutcome?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChatEditOutcome?>, ChatEditOutcome?>,
              AsyncValue<ChatEditOutcome?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

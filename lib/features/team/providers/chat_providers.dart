import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/team/data/chat_repository.dart';
import 'package:salesroot/features/team/data/fake_chat_repository.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/models/chat_room.dart';

part 'chat_providers.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  final repository = FakeChatRepository(ref.watch(fakeBackendProvider));
  ref.onDispose(repository.dispose);
  return repository;
}

@riverpod
class ChatSearchNotifier extends _$ChatSearchNotifier {
  @override
  String build() => '';

  void set(String search) => state = search;
}

/// The user's threads; reloads by itself when a message comes in.
@riverpod
class ChatListNotifier extends _$ChatListNotifier {
  @override
  Future<Paged<ChatThread>> build() async {
    final repository = ref.watch(chatRepositoryProvider);
    final search = ref.watch(chatSearchProvider);
    final changes = repository.changes.listen((_) => _reload());
    ref.onDispose(changes.cancel);
    return Paged.first(await repository.threads(ChatQuery(search: search)));
  }

  Future<void> _reload() async {
    final result = await AsyncValue.guard(
      () => ref
          .read(chatRepositoryProvider)
          .threads(ChatQuery(search: ref.read(chatSearchProvider))),
    );
    if (!ref.mounted || !result.hasValue) return;
    state = AsyncData(Paged.first(result.requireValue));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(chatRepositoryProvider)
          .threads(
            ChatQuery(
              search: ref.read(chatSearchProvider),
              page: current.page + 1,
            ),
          );
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
class OversightScopeNotifier extends _$OversightScopeNotifier {
  @override
  ChatScope build() => ChatScope.all;

  void set(ChatScope scope) => state = scope;
}

/// Every thread in the workspace, for the owner.
@riverpod
class OversightListNotifier extends _$OversightListNotifier {
  static const countsKey = 'KindCounts';

  @override
  Future<Paged<ChatThread>> build() async {
    final scope = ref.watch(oversightScopeProvider);
    final page = await ref
        .watch(chatRepositoryProvider)
        .oversight(ChatQuery(scope: scope));
    return Paged.first(page, facetKeys: const [countsKey]);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(chatRepositoryProvider)
          .oversight(
            ChatQuery(
              scope: ref.read(oversightScopeProvider),
              page: current.page + 1,
            ),
          );
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<ChatThread> chatThread(Ref ref, int id) =>
    ref.watch(chatRepositoryProvider).thread(id);

/// One open thread, live: the first page of messages, then every message,
/// typing change and receipt the server pushes.
@riverpod
class ChatRoomNotifier extends _$ChatRoomNotifier {
  StreamController<ChatRoom>? _controller;
  ChatRoom _room = const ChatRoom();
  int _lastTempId = 0;
  final Map<int, MessageInput> _unsent = {};

  @override
  Stream<ChatRoom> build(int threadId) {
    final repository = ref.watch(chatRepositoryProvider);
    final controller = StreamController<ChatRoom>();
    _controller = controller;
    _room = const ChatRoom();
    final early = <ChatEvent>[];
    var loaded = false;
    final events = repository.events(threadId).listen((event) {
      if (!loaded) {
        early.add(event);
        return;
      }
      _emit(_room.apply(event));
      if (event is MessageAdded && !event.message.isMine) {
        repository.markRead(threadId).ignore();
      }
    });
    ref.onDispose(() {
      events.cancel();
      controller.close();
    });
    repository
        .messages(threadId)
        .then(
          (page) {
            loaded = true;
            var room = ChatRoom(
              messages: page.items,
              hasOlder: page.items.length < page.totalCount,
            );
            for (final event in early) {
              room = room.apply(event);
            }
            _emit(room);
            repository.markRead(threadId).ignore();
          },
          onError: (Object error, StackTrace stack) {
            if (!controller.isClosed) controller.addError(error, stack);
          },
        );
    return controller.stream;
  }

  void _emit(ChatRoom room) {
    _room = room;
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.add(room);
  }

  Future<void> loadOlder() async {
    if (_room.loadingOlder || !_room.hasOlder) return;
    final sent = _room.messages.where((m) => m.id > 0);
    if (sent.isEmpty) return;
    _emit(_room.copyWith(loadingOlder: true));
    final result = await AsyncValue.guard(
      () => ref
          .read(chatRepositoryProvider)
          .messages(threadId, beforeId: sent.last.id),
    );
    if (!ref.mounted) return;
    final page = result.value;
    _emit(
      page == null
          ? _room.copyWith(loadingOlder: false)
          : _room.withOlder(
              page.items,
              hasOlder: page.items.length < page.totalCount,
            ),
    );
  }

  /// Shows the message at once, then swaps in the server's copy, or marks
  /// it failed so it can be tried again.
  Future<void> send(MessageInput input) async {
    final temp = ChatMessage(
      id: --_lastTempId,
      threadId: threadId,
      senderId: 0,
      senderName: const LocalizedName('', ''),
      text: input.text.trim(),
      sentAt: DateTime.now(),
      attachment: input.attachment,
      status: MessageStatus.sending,
      isMine: true,
    );
    _unsent[temp.id] = input;
    _emit(_room.upsert(temp).copyWith(failure: () => null));
    final result = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).send(threadId, input),
    );
    if (!ref.mounted) return;
    final sent = result.value;
    if (sent == null) {
      _emit(
        _room
            .upsert(temp.withStatus(MessageStatus.failed))
            .copyWith(failure: () => result.error),
      );
      return;
    }
    _unsent.remove(temp.id);
    _emit(_room.remove(temp.id).upsert(sent));
  }

  Future<void> retry(ChatMessage failed) async {
    final input = _unsent.remove(failed.id);
    _emit(_room.remove(failed.id));
    if (input != null) await send(input);
  }

  void discard(ChatMessage failed) {
    _unsent.remove(failed.id);
    _emit(_room.remove(failed.id));
  }
}

/// Opens a lead discussion or a direct chat, or creates a group; the screen
/// listens for the thread to go to.
@riverpod
class ChatOpener extends _$ChatOpener {
  @override
  FutureOr<ChatThread?> build() => null;

  Future<void> lead(int leadId) =>
      _open(() => ref.read(chatRepositoryProvider).leadThread(leadId));

  Future<void> direct(int memberId) =>
      _open(() => ref.read(chatRepositoryProvider).direct(memberId));

  Future<void> group(String name, List<int> memberIds) => _open(
    () => ref.read(chatRepositoryProvider).createGroup(name, memberIds),
  );

  Future<void> _open(Future<ChatThread> Function() open) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(open);
    if (!ref.mounted) return;
    state = result;
  }
}

enum ChatEditOutcome { saved, membersAdded, left }

/// Settings, members and leaving for one thread.
@riverpod
class ChatThreadEditor extends _$ChatThreadEditor {
  @override
  FutureOr<ChatEditOutcome?> build(int threadId) => null;

  Future<void> settings({bool? notifications, bool? autoDownload}) => _run(
    ChatEditOutcome.saved,
    () => ref
        .read(chatRepositoryProvider)
        .updateSettings(
          threadId,
          notifications: notifications,
          autoDownload: autoDownload,
        ),
  );

  Future<void> addMembers(List<int> memberIds) => _run(
    ChatEditOutcome.membersAdded,
    () => ref.read(chatRepositoryProvider).addMembers(threadId, memberIds),
  );

  Future<void> leave() => _run(
    ChatEditOutcome.left,
    () => ref.read(chatRepositoryProvider).leave(threadId),
  );

  Future<void> _run(
    ChatEditOutcome outcome,
    Future<void> Function() work,
  ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await work();
      return outcome;
    });
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue && outcome != ChatEditOutcome.left) {
      ref.invalidate(chatThreadProvider(threadId));
    }
  }
}

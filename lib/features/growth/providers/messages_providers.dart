import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/data/fake_messages_repository.dart';
import 'package:salesroot/features/growth/data/messages_repository.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';

part 'messages_providers.g.dart';

@Riverpod(keepAlive: true)
MessagesRepository messagesRepository(Ref ref) =>
    FakeMessagesRepository(ref.watch(fakeBackendProvider));

@riverpod
class ThreadFilterNotifier extends _$ThreadFilterNotifier {
  @override
  ThreadFilter build() => ThreadFilter.all;

  void set(ThreadFilter filter) => state = filter;
}

/// The unified inbox (#141), latest conversation first.
@riverpod
class ThreadListNotifier extends _$ThreadListNotifier {
  @override
  Future<Paged<MessageThread>> build() async {
    final filter = ref.watch(threadFilterProvider);
    final page = await ref.watch(messagesRepositoryProvider).threads(filter);
    return Paged.first(page, facetKeys: const ['Counts']);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(messagesRepositoryProvider)
          .threads(ref.read(threadFilterProvider), page: current.page + 1);
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
Future<MessagingAccount> messagingAccount(Ref ref) =>
    ref.watch(messagesRepositoryProvider).account();

@riverpod
Future<MessageThread> messageThread(Ref ref, int id) =>
    ref.watch(messagesRepositoryProvider).thread(id);

@riverpod
Stream<List<ThreadMessage>> threadMessages(Ref ref, int id) =>
    ref.watch(messagesRepositoryProvider).watch(id);

@riverpod
Future<List<MessageTemplate>> messageTemplates(Ref ref) =>
    ref.watch(messagesRepositoryProvider).templates();

/// Sending, reading and assigning in a conversation; callers show the
/// outcome.
@Riverpod(keepAlive: true)
class MessageActions extends _$MessageActions {
  @override
  void build() {}

  Future<void> send(int threadId, SendMessageInput input) async {
    await ref.read(messagesRepositoryProvider).send(threadId, input);
    if (ref.mounted) _refresh(threadId);
  }

  Future<void> markRead(int threadId) async {
    await ref.read(messagesRepositoryProvider).markRead(threadId);
    if (ref.mounted) ref.invalidate(threadListProvider);
  }

  Future<void> assign(int threadId, int memberId) async {
    await ref.read(messagesRepositoryProvider).assign(threadId, memberId);
    if (ref.mounted) _refresh(threadId);
  }

  Future<int> open({required String phone, required String name}) async {
    final id = await ref
        .read(messagesRepositoryProvider)
        .openThread(phone: phone, name: name);
    if (ref.mounted) ref.invalidate(threadListProvider);
    return id;
  }

  void _refresh(int threadId) {
    ref
      ..invalidate(messageThreadProvider(threadId))
      ..invalidate(threadListProvider);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/team/data/fake_chat_repository.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/models/chat_room.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';

import 'team_test_helpers.dart';

/// The fake chat server with teammates who answer within milliseconds.
final _quickReplies = chatRepositoryProvider.overrideWith((ref) {
  final repository = FakeChatRepository(
    ref.watch(fakeBackendProvider),
    deliveredAfter: const Duration(milliseconds: 10),
    typingAfter: const Duration(milliseconds: 20),
    replyAfter: const Duration(milliseconds: 60),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

void main() {
  late ProviderContainer container;

  tearDown(() => container.dispose());

  Future<ChatThread> directWithRumpa() async {
    final page = await container
        .read(chatRepositoryProvider)
        .threads(const ChatQuery(scope: ChatScope.direct));
    return page.items.firstWhere((t) => t.participants.any((p) => p.id == '4'));
  }

  test('the list holds only my threads, with unread counts', () async {
    container = await teamContainer(role: 'executive');
    container.listen(chatListProvider, (_, _) {});

    final threads = await container.read(chatListProvider.future);
    expect(threads.items, isNotEmpty);
    final everyone = threads.items.firstWhere((t) => t.isEveryone);
    expect(everyone.unreadCount, 3);
    expect(threads.items.every((t) => t.isParticipant), isTrue);
  });

  test('a sent message arrives, then the teammate reads, types and replies '
      'on the stream', () async {
    container = await teamContainer(
      role: 'executive',
      overrides: [_quickReplies],
    );
    final thread = await directWithRumpa();
    final rooms = <ChatRoom>[];
    container.listen(chatRoomProvider(thread.id), (_, next) {
      if (next.value case final room?) rooms.add(room);
    }, fireImmediately: true);
    final loaded = await container.read(chatRoomProvider(thread.id).future);
    final before = loaded.messages.length;

    await container
        .read(chatRoomProvider(thread.id).notifier)
        .send(const MessageInput(text: 'Delta র sample কাল নিয়ে যাব'));
    await pumpEventQueue();

    final sent = rooms.last.messages.first;
    expect(sent.isMine, isTrue);
    expect(sent.id, greaterThan(0));
    expect(sent.status, MessageStatus.sent);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(rooms.any((r) => r.typing.any((p) => p.id == '4')), isTrue);
    final latest = rooms.last;
    expect(latest.typing, isEmpty);
    expect(latest.messages, hasLength(before + 2));
    final reply = latest.messages.first;
    expect(reply.isMine, isFalse);
    expect(reply.senderId, '4');
    expect(
      latest.messages.firstWhere((m) => m.id == sent.id).status,
      MessageStatus.read,
    );
  });

  test(
    'a failed send stays in the room as failed and can be retried',
    () async {
      container = await teamContainer(role: 'executive');
      final thread = await directWithRumpa();
      container.listen(chatRoomProvider(thread.id), (_, _) {});
      await container.read(chatRoomProvider(thread.id).future);
      setDev(container, (s) => s.copyWith(offline: true));
      final room = container.read(chatRoomProvider(thread.id).notifier);

      await room.send(const MessageInput(text: 'আছেন?'));
      await pumpEventQueue();

      var state = container.read(chatRoomProvider(thread.id)).requireValue;
      final failed = state.messages.first;
      expect(failed.status, MessageStatus.failed);
      expect((state.failure as ApiFailure?)?.isOffline, isTrue);

      setDev(container, (s) => s.copyWith(offline: false));
      await room.retry(failed);
      await pumpEventQueue();

      state = container.read(chatRoomProvider(thread.id)).requireValue;
      expect(state.messages.first.text, 'আছেন?');
      expect(state.messages.first.status, MessageStatus.sent);
      expect(state.messages.where((m) => m.id < 0), isEmpty);
    },
  );

  test('a photo on a full plan fails with the storage quota', () async {
    container = await teamContainer(role: 'executive');
    setDev(container, (s) => s.copyWith(quotaReached: true));
    final thread = await directWithRumpa();

    await expectLater(
      container
          .read(chatRepositoryProvider)
          .send(
            thread.id,
            const MessageInput(
              attachment: Attachment(
                kind: AttachmentKind.photo,
                title: 'site.jpg',
                sizeBytes: 900000,
              ),
            ),
          ),
      throwsA(
        isA<ApiFailure>().having((f) => f.quota, 'quota', QuotaKind.storage),
      ),
    );
  });

  test('the lead discussion is created once and reused', () async {
    container = await teamContainer(role: 'executive');
    container.listen(chatOpenerProvider, (_, _) {});
    final repository = container.read(chatRepositoryProvider);
    Future<int> leadThreads() async => (await repository.threads(
      const ChatQuery(scope: ChatScope.lead),
    )).totalCount;
    final before = await leadThreads();

    await container.read(chatOpenerProvider.notifier).lead('40');
    final first = container.read(chatOpenerProvider).requireValue;
    await container.read(chatOpenerProvider.notifier).lead('40');
    final second = container.read(chatOpenerProvider).requireValue;

    expect(first?.id, isNotNull);
    expect(second?.id, first?.id);
    expect(first?.kind, ChatKind.lead);
    expect(first?.lead?.id, '40');
    expect(await leadThreads(), before + 1);
  });

  test('only the owner can read every chat', () async {
    container = await teamContainer(role: 'executive');

    await expectLater(
      container.read(chatRepositoryProvider).oversight(const ChatQuery()),
      throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
    );

    container.dispose();
    container = await teamContainer();
    container.listen(oversightListProvider, (_, _) {});
    final all = await container.read(oversightListProvider.future);
    expect(all.items.any((t) => !t.isParticipant), isTrue);
    expect(all.facets[OversightListNotifier.countsKey]?['Group'], 6);
  });

  test('a group needs a name and at least one person', () async {
    container = await teamContainer(role: 'executive');
    container.listen(chatOpenerProvider, (_, _) {});

    await container.read(chatOpenerProvider.notifier).group('', ['4']);
    expect(
      (container.read(chatOpenerProvider).error as ApiFailure?)?.isValidation,
      isTrue,
    );

    await container.read(chatOpenerProvider.notifier).group('Chattogram trip', [
      '4',
      '5',
    ]);
    final group = container.read(chatOpenerProvider).requireValue;
    expect(group?.title, 'Chattogram trip');
    expect(group?.participants.map((p) => p.id), containsAll(['1', '4', '5']));
  });
}

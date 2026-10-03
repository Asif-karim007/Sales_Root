import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';

import 'growth_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a sent message streams in and the customer replies', () async {
    final container = await growthContainer();
    final updates = <List<ThreadMessage>>[];
    final sub = container.listen(threadMessagesProvider(1), (_, next) {
      final messages = next.value;
      if (messages != null) updates.add(messages);
    }, fireImmediately: true);
    addTearDown(sub.close);
    final start = await container.read(threadMessagesProvider(1).future);

    await container
        .read(messageActionsProvider.notifier)
        .send(1, const SendMessageInput(text: 'Driver: 01711-223344'));
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final last = updates.last;
    expect(last.length, start.length + 2);
    expect(last[last.length - 2].mine, isTrue);
    expect(last[last.length - 2].text, 'Driver: 01711-223344');
    expect(last.last.mine, isFalse);
  });

  test('the filters count threads and Mine keeps my threads', () async {
    final container = await growthContainer();
    container.read(threadFilterProvider.notifier).set(ThreadFilter.mine);
    final mine = await container.read(threadListProvider.future);
    expect(mine.items, isNotEmpty);
    expect(mine.items.every((t) => t.assignedToMe), isTrue);
    expect(mine.facets['Counts']?['Mine'], mine.items.length);
  });

  test('a closed WhatsApp window only takes templates', () async {
    final container = await growthContainer();
    final id = await container
        .read(messageActionsProvider.notifier)
        .open(phone: '+8801999000111', name: 'Sohag Mia');
    final thread = await container.read(messageThreadProvider(id).future);
    expect(thread.needsTemplate, isTrue);

    final repository = container.read(messagesRepositoryProvider);
    await expectLater(
      repository.send(id, const SendMessageInput(text: 'Hello')),
      throwsA(isA<ApiFailure>().having((f) => f.isValidation, '400', true)),
    );
    final sent = await repository.send(
      id,
      const SendMessageInput(text: 'Hello Sohag', templateId: 3),
    );
    expect(sent.mine, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';

import '../../helpers/api_stub.dart';
import 'growth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the recorded empty inbox parses', () async {
    final container = await growthContainer(stub: growthStub(empty: true));
    final paged = await container.read(inboxListProvider.future);
    expect(paged.isEmpty, isTrue);
    expect(paged.hasMore, isFalse);
  });

  test('new leads page by offset over open conversations', () async {
    final stub = growthStub();
    stubInbox(stub, [for (var n = 1; n <= 25; n++) conversationRow(n)]);
    final container = await growthContainer(stub: stub);
    final sub = container.listen(inboxListProvider, (_, _) {});
    addTearDown(sub.close);

    final first = await container.read(inboxListProvider.future);
    expect(first.items, hasLength(20));
    expect(first.totalCount, 25);
    final query = stub.last('GET', 'inbox')?.queryParameters;
    expect(query?['offset'], 0);
    expect(query?['limit'], 20);
    expect(query?['status'], 'open');
    expect(query?.containsKey('box'), isFalse);

    await container.read(inboxListProvider.notifier).loadMore();
    final all = container.read(inboxListProvider).requireValue;
    expect(stub.last('GET', 'inbox')?.queryParameters['offset'], 20);
    expect(all.items, hasLength(25));
    expect(all.hasMore, isFalse);

    container.read(inboxBoxProvider.notifier).set(ConversationBox.unassigned);
    await container.read(inboxListProvider.future);
    expect(stub.last('GET', 'inbox')?.queryParameters['box'], 'unassigned');
  });

  test('the messages list asks for every status', () async {
    final stub = growthStub();
    final container = await growthContainer(stub: stub);
    final paged = await container.read(threadListProvider.future);
    expect(paged.items, hasLength(4));
    expect(
      stub.last('GET', 'inbox')?.queryParameters.containsKey('status'),
      isFalse,
    );

    final closed = paged.items.last;
    expect(closed.open, isFalse);
    final mine = paged.items[1];
    expect(mine.isMine(container.read(myMembershipIdProvider)), isTrue);
    expect(mine.leadId, leadId);
    expect(mine.channel, ConversationChannel.whatsapp);
  });

  test('a conversation reads its wrapped detail and messages', () async {
    final container = await growthContainer();
    final conversation = await container.read(
      conversationProvider(conversationId(2)).future,
    );
    expect(conversation.name, 'Customer 2');
    expect(conversation.assignedTo, 'Rafi Ahmed');
    expect(conversation.messages, hasLength(2));
    expect(conversation.messages.first.mine, isFalse);
    expect(conversation.messages.last.status, DeliveryStatus.read);
  });

  test('take, assign and close post to their paths and reload', () async {
    final stub = growthStub()
      ..on('POST', 'inbox/{id}/take', const StubReply(204))
      ..on('POST', 'inbox/{id}/assign/{membershipId}', const StubReply(204))
      ..on('POST', 'inbox/{id}/close', const StubReply(204));
    final container = await growthContainer(stub: stub);
    final actions = container.read(inboxActionsProvider.notifier);
    final id = conversationId(1);

    await actions.take(id);
    expect(stub.last('POST', 'inbox/{id}/take')?.uri.path, contains(id));
    await actions.assign(id, bushra);
    expect(
      stub.last('POST', 'inbox/{id}/assign/{membershipId}')?.uri.path,
      endsWith('$id/assign/$bushra'),
    );
    final closed = await actions.close(id);
    expect(stub.last('POST', 'inbox/{id}/close'), isNotNull);
    expect(closed.id, id);
  });

  test('someone else took it first: accepting shows the 409', () async {
    final stub = growthStub()
      ..on(
        'POST',
        'inbox/{id}/take',
        fixture('growth_inbox_taken'),
        status: 409,
      );
    final container = await growthContainer(stub: stub);
    final provider = acceptLeadSubmitProvider(conversationId(1));
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);

    await container.read(provider.notifier).submit();
    final error = container.read(provider).error;
    expect(error, isA<ApiFailure>());
    expect((error as ApiFailure?)?.isConflict, isTrue);
  });

  test('a reply sends text, or an approved template with params', () async {
    final stub = growthStub()
      ..on('POST', 'inbox/{id}/reply', const StubReply(204));
    final container = await growthContainer(stub: stub);
    final actions = container.read(inboxActionsProvider.notifier);
    final id = conversationId(2);

    await actions.reply(id, const ReplyInput(text: ' Sending now '));
    expect(stub.lastBody('POST', 'inbox/{id}/reply'), {
      'text': 'Sending now',
      'params': <Object>[],
    });

    await actions.reply(
      id,
      const ReplyInput(templateName: 'price_list', params: ['Karim']),
    );
    expect(stub.lastBody('POST', 'inbox/{id}/reply'), {
      'templateName': 'price_list',
      'params': ['Karim'],
    });
  });

  test('only active members can be assigned', () async {
    final members = [
      for (final row in fixture('growth_members') as List)
        Map<String, dynamic>.of(row as Map<String, dynamic>),
    ];
    final stub = growthStub()
      ..on('GET', 'workspaces/members', [
        ...members,
        {...members.first, 'id': 'invited', 'status': 'invited'},
      ]);
    final container = await growthContainer(stub: stub);

    final list = await container.read(inboxMembersProvider.future);
    expect(list, hasLength(members.length));
    expect(list.map((m) => m.id), contains(rafi));
    expect(list.first.openLeads, isNull);
  });

  test('offline, the list fails as status 0', () async {
    final stub = growthStub();
    final container = await growthContainer(stub: stub);
    stub.offline = true;
    await expectLater(
      container.read(inboxListProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
    );
  });
}

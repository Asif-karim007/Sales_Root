import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/features/support/providers/ticket_providers.dart';

import 'support_test_container.dart';

void main() {
  test('support answers a reply after a delay', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    final provider = supportTicketProvider(3);
    container.listen(provider, (_, _) {});
    final before = await container.read(provider.future);
    final count = before.ticket.messages.length;

    final answered = container
        .read(supportRepositoryProvider)
        .ticketChanges
        .firstWhere((id) => id == 3);
    final sent = await container
        .read(provider.notifier)
        .send('Still an issue on the new update.');
    expect(sent, isTrue);
    final waiting = container.read(provider).requireValue;
    expect(waiting.agentTyping, isTrue);
    expect(waiting.ticket.messages, hasLength(count + 1));
    expect(waiting.ticket.status, TicketStatus.open);

    await answered;
    await Future<void>.delayed(Duration.zero);
    final thread = container.read(provider).requireValue;
    expect(thread.agentTyping, isFalse);
    expect(thread.ticket.status, TicketStatus.replied);
    expect(thread.ticket.messages, hasLength(count + 2));
    expect(thread.ticket.messages.last.fromAgent, isTrue);
    expect(thread.ticket.messages.last.body, contains('escalated'));
  });

  test('a Bangla request gets a Bangla answer', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(newTicketProvider, (_, _) {});
    final repository = container.read(supportRepositoryProvider);

    await container
        .read(newTicketProvider.notifier)
        .submit(
          const TicketInput(
            category: TicketCategory.billing,
            description: 'বিকাশে টাকা দিয়েছি কিন্তু প্ল্যান বদলায়নি।',
            channel: ReplyChannel.inAppSms,
          ),
        );
    final created = container.read(newTicketProvider).requireValue;
    expect(created, isNotNull);
    final id = created?.id ?? 0;
    expect(created?.number, 'SR-1046');

    await repository.ticketChanges.firstWhere((changed) => changed == id);
    final ticket = await repository.ticket(id);
    expect(ticket.messages.last.fromAgent, isTrue);
    expect(ticket.messages.last.body, contains('ধন্যবাদ'));
  });

  test('a too-short request is rejected with a field error', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(newTicketProvider, (_, _) {});

    await container
        .read(newTicketProvider.notifier)
        .submit(
          const TicketInput(
            category: TicketCategory.bug,
            description: 'broken',
            channel: ReplyChannel.inApp,
          ),
        );
    final error = container.read(newTicketProvider).error;
    expect(error, isA<ApiFailure>());
    expect((error as ApiFailure).fieldError('Description'), isNotNull);
  });

  test('my requests page and a resolve updates the status', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(myTicketsProvider, (_, _) {});
    final tickets = await container.read(myTicketsProvider.future);
    expect(tickets.items.first.number, 'SR-1042');
    expect(tickets.totalCount, 4);

    final provider = supportTicketProvider(3);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    await container.read(provider.notifier).resolve();
    expect(
      container.read(provider).requireValue.ticket.status,
      TicketStatus.resolved,
    );
  });
}

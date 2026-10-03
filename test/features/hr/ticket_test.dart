import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/hr/models/ticket.dart';
import 'package:salesroot/features/hr/providers/ticket_providers.dart';

import 'hr_test_utils.dart';

void main() {
  test('customer search pages over the companies', () async {
    final container = await hrContainer();
    final repository = container.read(ticketRepositoryProvider);

    final all = await repository.searchCustomers('', 1);
    final karim = await repository.searchCustomers('karim', 1);

    expect(all.items, hasLength(20));
    expect(all.totalCount, greaterThan(20));
    expect(karim.items.first.name, 'Karim Textiles');
    expect(karim.items.first.leadId, isNotNull);
  });

  test('the draft lists what is missing', () {
    expect(const TicketDraft().errors, {
      TicketField.customer,
      TicketField.title,
      TicketField.issue,
      TicketField.description,
    });
  });

  test(
    'a ticket opens with its SLA and the complaint as first message',
    () async {
      final container = await hrContainer();
      keep(container, ticketFormProvider);
      final repository = container.read(ticketRepositoryProvider);
      final customer = (await repository.searchCustomers(
        'Delta',
        1,
      )).items.first;
      final form = container.read(ticketFormProvider.notifier);

      form.edit(
        (d) => d.copyWith(
          customer: customer,
          title: 'Inverter beeping',
          issue: TicketIssue.problem,
          priority: TicketPriority.high,
          description: 'Beeps every 5 minutes, red light on.',
        ),
      );
      await form.submit();

      final ticket = container.read(ticketFormProvider).submission.value;
      expect(ticket?.status, TicketStatus.open);
      expect(ticket?.customerName, 'Delta Power');
      expect(ticket?.code, startsWith('T-'));
      expect(ticket?.slaMinutesLeft, inInclusiveRange(4 * 60 - 1, 4 * 60));
      expect(ticket?.messages.single.mine, isFalse);
    },
  );

  test('missing fields are refused by the server', () async {
    final container = await hrContainer();

    await expectLater(
      container
          .read(ticketRepositoryProvider)
          .create(
            const TicketInput(
              customerId: null,
              title: ' ',
              issue: null,
              priority: TicketPriority.medium,
            ),
          ),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.fieldErrors.keys,
          'fields',
          containsAll(['CustomerId', 'Title', 'IssueType', 'Description']),
        ),
      ),
    );
  });

  test('a reply and a status change are saved', () async {
    final container = await hrContainer();
    final actions = ticketActionsProvider(1);
    keep(container, actions);
    keep(container, ticketProvider(1));
    final before = await container.read(ticketProvider(1).future);

    await container.read(actions.notifier).reply('Arif is on the way.');
    await container.read(actions.notifier).setStatus(TicketStatus.resolved);

    final after = await container.read(ticketProvider(1).future);
    expect(after.messages, hasLength(before.messages.length + 1));
    expect(after.messages.last.mine, isTrue);
    expect(after.status, TicketStatus.resolved);
    expect(after.slaMinutesLeft, isNull);
  });
}

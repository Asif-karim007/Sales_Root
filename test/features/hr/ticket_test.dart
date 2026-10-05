import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/ticket.dart';
import 'package:salesroot/features/hr/providers/ticket_providers.dart';

import '../../helpers/api_stub.dart';
import 'hr_test_setup.dart';

void main() {
  test('customer search pages over the companies', () async {
    final stub = hrStub();
    final container = await hrContainer(stub);

    final page = await container
        .read(ticketRepositoryProvider)
        .searchCustomers(' probe ', 2);

    expect(page.items.first.id, companyId);
    expect(page.items.first.name, '[test] Co probe');
    expect(stub.last('GET', 'companies')?.queryParameters, {
      'q': 'probe',
      'offset': 20,
      'limit': 20,
    });
  });

  test('the draft lists what is missing', () {
    expect(const TicketDraft().errors, {
      TicketField.customer,
      TicketField.title,
      TicketField.issue,
      TicketField.description,
    });
  });

  test('the ticket reads the real JSON', () async {
    final container = await hrContainer(hrStub());
    listenTo(container, ticketProvider(ticketId));

    final ticket = await container.read(ticketProvider(ticketId).future);

    expect(ticket.code, 'TKT-2026-00002');
    expect(ticket.title, '[test] hr agent ticket');
    expect(ticket.issue, TicketIssue.problem);
    expect(ticket.priority, TicketPriority.high);
    expect(ticket.status, TicketStatus.fresh);
    expect(ticket.source, ticketSourceFieldVisit);
    expect(ticket.slaHours, 24);
    expect(ticket.messages.single.text, '[test] description body');
    expect(ticket.messages.single.mine, isTrue);
  });

  test('internal notes stay out of the thread', () {
    final json = fixtureMap('hr_ticket');
    final message = (json['messages'] as List).single as Map;
    final ticket = Ticket.fromJson({
      ...json,
      'messages': [
        message,
        {...message, 'isInternal': true, 'body': 'note to self'},
      ],
    });
    expect(ticket.messages.map((m) => m.text), ['[test] description body']);
  });

  test('raising a ticket sends it, then attaches the photos', () async {
    final stub = hrStub();
    final container = await hrContainer(stub);
    listenTo(container, ticketFormProvider);
    final form = container.read(ticketFormProvider.notifier);
    final photo = photoFile();

    form.edit(
      (d) => d.copyWith(
        customer: const TicketCustomer(id: companyId, name: 'Co'),
        title: ' Inverter beeping ',
        issue: TicketIssue.warranty,
        description: 'Beeps at night',
        photos: [photo],
      ),
    );
    await form.submit();

    expect(stub.lastBody('POST', 'tickets'), {
      'subject': 'Inverter beeping',
      'type': 'warranty',
      'priority': 'normal',
      'companyId': companyId,
      'body': 'Beeps at night',
      'source': 'field_visit',
    });
    final upload = stub.last('POST', 'files')?.data as FormData?;
    expect(
      {
        for (final f in upload?.fields ?? <MapEntry<String, String>>[])
          f.key: f.value,
      },
      {'entityType': 'ticket', 'entityId': ticketId},
    );
    expect(
      container.read(ticketFormProvider).submission.value?.code,
      'TKT-2026-00002',
    );
  });

  test('a status change and a reply are sent', () async {
    final stub = hrStub();
    final container = await hrContainer(stub);
    final provider = ticketActionsProvider(ticketId);
    listenTo(container, provider);

    await container.read(provider.notifier).setStatus(TicketStatus.resolved);
    expect(stub.lastBody('PATCH', 'tickets/{id}'), {'status': 'resolved'});
    expect(container.read(provider).value, TicketAction.status);

    await container.read(provider.notifier).reply(' On my way ');
    expect(stub.lastBody('POST', 'tickets/{id}/reply'), {'body': 'On my way'});
  });

  test('a reply the server cannot place is an error', () async {
    final stub = hrStub()
      ..on(
        'POST',
        'tickets/{id}/reply',
        fixture('hr_ticket_reply_missing'),
        status: 404,
      );
    final container = await hrContainer(stub);
    final provider = ticketActionsProvider(ticketId);
    listenTo(container, provider);

    await container.read(provider.notifier).reply('Hello');

    expect(
      container.read(provider).error,
      isA<ApiFailure>().having((f) => f.isNotFound, '404', isTrue),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/features/support/providers/support_form_providers.dart';
import 'package:salesroot/features/support/providers/ticket_providers.dart';

import '../../helpers/api_stub.dart';
import 'support_api_setup.dart';

void main() {
  group('requests to support', () {
    test('my requests come as a bare list', () async {
      final container = await supportApiContainer(supportStub());
      listenTo(container, myTicketsProvider);

      expect(await container.read(myTicketsProvider.future), isEmpty);
    });

    test('a desk that is not set up is an error to show', () async {
      final stub = supportStub()
        ..on(
          'GET',
          'help/tickets',
          fixture('support_help_unavailable'),
          status: 503,
        );
      final container = await supportApiContainer(stub);
      listenTo(container, myTicketsProvider);

      await expectLater(
        container.read(myTicketsProvider.future),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.statusCode, 'status', 503)
              .having((f) => f.message, 'message', isNotEmpty),
        ),
      );
    });

    test('a ticket reads the desk’s ticket JSON', () async {
      final container = await supportApiContainer(supportStub());
      final provider = supportTicketProvider(ticketId);
      listenTo(container, provider);

      final ticket = (await container.read(provider.future)).ticket;

      expect(ticket.number, 'TKT-2026-00002');
      expect(ticket.subject, '[test] hr agent ticket');
      expect(ticket.status, TicketStatus.open);
      expect(ticket.replyWithinHours, 4);
      expect(ticket.messages.single.body, '[test] description body');
    });

    test('a new request sends its subject, kind and agreed details', () async {
      final stub = supportStub();
      final container = await supportApiContainer(stub);
      listenTo(container, newTicketProvider);

      await container
          .read(newTicketProvider.notifier)
          .submit(
            const TicketInput(
              category: TicketCategory.bug,
              description: 'Sync stops\nIt says waiting forever',
              channel: ReplyChannel.phone,
              appVersion: '0.1.0',
              diagnostics: {'screen': 'leads'},
            ),
          );

      expect(stub.lastBody('POST', 'help/ticket'), {
        'subject': 'Sync stops',
        'type': 'bug',
        'body': 'Sync stops\nIt says waiting forever',
        'source': 'app',
        'appVersion': '0.1.0',
        'tags': ['reply:phone', 'screen:leads'],
      });
      expect(stub.last('POST', 'help/tickets/{id}/reply'), isNull);
      expect(container.read(newTicketProvider).value?.id, ticketId);
    });

    test('screenshots go up first and ride on a reply', () async {
      final stub = supportStub();
      final container = await supportApiContainer(stub);
      listenTo(container, newTicketProvider);

      await container
          .read(newTicketProvider.notifier)
          .submit(
            TicketInput(
              category: TicketCategory.question,
              description: 'How do I export?',
              channel: ReplyChannel.inApp,
              attachments: [
                SupportAttachment(
                  path: pickedFile('screen.png'),
                  name: 'screen.png',
                  kind: AttachmentKind.image,
                ),
              ],
            ),
          );

      expect(stub.lastBody('POST', 'help/tickets/{id}/reply'), {
        'body': 'screen.png',
        'attachments': [fixtureMap('support_uploaded')['key']],
      });
    });

    test('a failed reply keeps the thread and names the failure', () async {
      final stub = supportStub()
        ..fail('POST', 'help/tickets/{id}/reply', 422, field: 'body');
      final container = await supportApiContainer(stub);
      final provider = supportTicketProvider(ticketId);
      listenTo(container, provider);
      await container.read(provider.future);

      final sent = await container.read(provider.notifier).send('Hello');

      expect(sent, isFalse);
      expect(container.read(provider).value?.failure?.isValidation, isTrue);
      expect(container.read(provider).value?.sending, isFalse);
    });
  });

  group('feedback', () {
    test('feedback carries the face, the note and the areas', () async {
      final stub = supportStub();
      final container = await supportApiContainer(stub);
      listenTo(container, feedbackSubmitProvider);

      await container
          .read(feedbackSubmitProvider.notifier)
          .submit(
            FeedbackInput(
              rating: FeedbackRating.good,
              areas: {FeedbackArea.scanning, FeedbackArea.chat},
              text: ' Love the voice lead ',
              wantsReply: true,
              screenshot: SupportAttachment(
                path: pickedFile('shot.png'),
                name: 'shot.png',
                kind: AttachmentKind.image,
              ),
            ),
          );

      final body = stub.lastBody('POST', 'help/feedback');
      expect(body['kind'], 'feedback');
      expect(body['rating'], 4);
      expect(
        body['body'],
        'Love the voice lead\nareas: scanning, chat\nreply: yes',
      );
      expect(body['screenshotKey'], fixtureMap('support_uploaded')['key']);
      expect(body['platform'], isNotEmpty);
      expect(container.read(feedbackSubmitProvider).value, isTrue);
    });

    test('a survey answer is feedback for its moment', () async {
      final stub = supportStub();
      final container = await supportApiContainer(stub);
      final provider = momentSurveyProvider('quotationSent');
      listenTo(container, provider);

      await container.read(provider.notifier).answer(SurveyScore.easy);

      expect(container.read(provider).value, SurveyScore.easy);
      final body = stub.lastBody('POST', 'help/feedback');
      expect(body['kind'], 'survey');
      expect(body['rating'], 3);
      expect(body['screen'], 'quotationSent');
    });

    test('an enquiry checks its fields, then goes as one text', () async {
      const empty = EnquiryInput(
        kind: null,
        company: '',
        name: ' ',
        mobile: '123',
        details: '',
        callWindow: CallWindow.midday,
      );
      expect(empty.errors, EnquiryField.values.toSet());

      final stub = supportStub();
      final container = await supportApiContainer(stub);
      listenTo(container, enquirySubmitProvider);
      await container
          .read(enquirySubmitProvider.notifier)
          .submit(
            const EnquiryInput(
              kind: EnquiryKind.erp,
              company: 'Karim Textiles',
              name: 'Karim Hossain',
              mobile: '+880 1711-000000',
              details: 'Stock and payroll',
              callWindow: CallWindow.evening,
            ),
          );

      final body = stub.lastBody('POST', 'help/feedback');
      expect(body['kind'], 'enquiry');
      expect(
        body['body'],
        'kind: Erp\ncompany: Karim Textiles\nname: Karim Hossain\n'
        'mobile: +880 1711-000000\ncall: Evening\nStock and payroll',
      );
    });
  });
}

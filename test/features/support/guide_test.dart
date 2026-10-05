import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/support/models/app_destination.dart';
import 'package:salesroot/features/support/models/guide.dart';
import 'package:salesroot/features/support/providers/guide_providers.dart';

import '../../helpers/api_stub.dart';
import 'support_api_setup.dart';

void main() {
  test('answers read the real JSON and map routes to screens', () {
    final lead = GuideAnswer.fromJson(fixtureMap('support_guide_answer'));
    expect(lead.text, startsWith('নতুন লিড'));
    expect(lead.kind, GuideAnswerKind.answer);
    expect(lead.actions.single.destination, AppDestination.leads);
    expect(lead.conversationId, '01a10d29-76d0-73ac-b381-390c3116c7dd');

    final field = GuideAnswer.fromJson(fixtureMap('support_guide_field'));
    expect(field.actions.single.location, Routes.visits);

    final unknown = GuideAnswer.fromJson(fixtureMap('support_guide_unknown'));
    expect(unknown.actions, isEmpty);
  });

  test('the status says when the rules answer instead of AI', () async {
    final container = await supportApiContainer(supportStub());
    listenTo(container, guideStatusProvider);

    final status = await container.read(guideStatusProvider.future);

    expect(status.enabled, isFalse);
    expect(status.limit, 1500);
  });

  test('the chat sends the question and keeps the thread', () async {
    final stub = supportStub();
    final container = await supportApiContainer(stub);
    listenTo(container, guideChatProvider);
    final chat = container.read(guideChatProvider.notifier);

    await chat.ask(' How do I add a lead? ');
    expect(stub.lastBody('POST', 'ai/guide'), {
      'question': 'How do I add a lead?',
      'screen': 'ai_guide',
    });
    await chat.ask('And by voice?');
    expect(
      stub.lastBody('POST', 'ai/guide')['conversationId'],
      '01a10d29-76d0-73ac-b381-390c3116c7dd',
    );

    final state = container.read(guideChatProvider);
    expect(state.messages.map((m) => m.kind), [
      GuideMessageKind.greeting,
      GuideMessageKind.mine,
      GuideMessageKind.answer,
      GuideMessageKind.mine,
      GuideMessageKind.answer,
    ]);
  });

  test('a failed answer can be asked again', () async {
    final stub = supportStub();
    final failing = await supportApiContainer(stub);
    stub.offline = true;
    listenTo(failing, guideChatProvider);
    final chat = failing.read(guideChatProvider.notifier);

    await chat.ask('Hello');
    expect(failing.read(guideChatProvider).failure?.isOffline, isTrue);
    expect(failing.read(guideChatProvider).unanswered, 'Hello');

    stub.offline = false;
    await chat.retry();
    expect(failing.read(guideChatProvider).failure, isNull);
    expect(
      failing.read(guideChatProvider).messages.last.kind,
      GuideMessageKind.answer,
    );
  });

  test('a rating goes once for the thread', () async {
    final stub = supportStub();
    final container = await supportApiContainer(stub);
    listenTo(container, guideChatProvider);
    final chat = container.read(guideChatProvider.notifier);
    await chat.ask('How do I add a lead?');

    await chat.rate(helpful: true);
    await chat.rate(helpful: false);

    expect(stub.lastBody('POST', 'ai/guide/rate'), {
      'conversationId': '01a10d29-76d0-73ac-b381-390c3116c7dd',
      'rating': 5,
    });
    expect(stub.requests.where((r) => r.path == 'ai/guide/rate'), hasLength(1));
    expect(container.read(guideChatProvider).rated, isTrue);
  });
}

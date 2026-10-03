import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/support/models/app_destination.dart';
import 'package:salesroot/features/support/models/guide.dart';
import 'package:salesroot/features/support/providers/guide_providers.dart';

import 'support_test_container.dart';

void main() {
  Future<GuideAnswer> ask(String text, {bool appInBangla = true}) async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    return container
        .read(guideRepositoryProvider)
        .ask(GuideQuestion(text: text, appInBangla: appInBangla));
  }

  test('an English question gets the English article steps', () async {
    final answer = await ask('How do I scan a visiting card?');
    expect(answer.kind, GuideAnswerKind.answer);
    expect(answer.text, contains('Tap the camera icon on Home.'));
    expect(answer.articleId, isNotNull);
    expect(answer.hasVideo, isTrue);
    expect(answer.actions.single.destination, AppDestination.scanCard);
  });

  test('a Bangla question gets the Bangla answer', () async {
    final answer = await ask('কার্ড স্ক্যান কীভাবে করব?', appInBangla: false);
    expect(answer.text, contains('হোমে ক্যামেরা আইকন চাপুন।'));
    expect(answer.actions.single.destination, AppDestination.scanCard);

    final lead = await ask('লিড কীভাবে যোগ করব?');
    expect(lead.text, contains('সবুজ + বোতাম'));
    expect(lead.actions.single.location, '/leads/new');
  });

  test('a stage question uses the app knowledge', () async {
    final answer = await ask('What does this stage mean?');
    expect(answer.text, contains('“Interested” means'));
    expect(answer.actions.single.destination, AppDestination.newQuotation);
  });

  test('a task request asks to confirm before creating it', () async {
    final english = await ask('Call Karim Textiles tomorrow at ten');
    expect(english.kind, GuideAnswerKind.confirm);
    expect(english.text, contains('“Call Karim Textiles” for tomorrow 10:00'));
    expect(english.actions.single.destination, AppDestination.newTask);
    expect(english.actions.single.params['title'], 'Call Karim Textiles');

    final bangla = await ask('করিম টেক্সটাইলসকে কাল দশটায় কল');
    expect(bangla.kind, GuideAnswerKind.confirm);
    expect(bangla.text, contains('কাল ১০:০০-এ'));
    expect(bangla.actions.single.params['title'], 'করিম টেক্সটাইলসকে কল');
  });

  test('an unknown question falls back to help and support', () async {
    final answer = await ask('What is the capital of Peru?');
    expect(answer.kind, GuideAnswerKind.fallback);
    expect(answer.actions.map((a) => a.destination), [
      AppDestination.help,
      AppDestination.support,
    ]);
  });

  test('the chat keeps the question, the answer and a decline', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(guideChatProvider, (_, _) {});
    final chat = container.read(guideChatProvider.notifier);

    await chat.ask('Call Karim Textiles tomorrow at ten', appInBangla: false);
    final asked = container.read(guideChatProvider);
    expect(asked.messages.map((m) => m.kind), [
      GuideMessageKind.greeting,
      GuideMessageKind.mine,
      GuideMessageKind.answer,
    ]);

    chat.settle(asked.messages.last.id, accepted: false);
    final declined = container.read(guideChatProvider);
    expect(declined.messages[2].settled, isTrue);
    expect(declined.messages.last.kind, GuideMessageKind.declined);
  });
}

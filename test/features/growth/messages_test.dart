import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';

import '../../helpers/api_stub.dart';
import 'growth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('templates are asked for one channel', () async {
    final stub = growthStub();
    final container = await growthContainer(stub: stub);

    final templates = await container.read(
      messageTemplatesProvider(ConversationChannel.whatsapp.wire).future,
    );
    expect(
      stub.last('GET', 'templates')?.queryParameters['channel'],
      'whatsapp',
    );
    expect(templates.first.approved, isTrue);
    expect(templates.last.approved, isFalse);

    await container.read(smsTemplatesProvider.future);
    expect(stub.last('GET', 'templates')?.queryParameters['channel'], 'sms');
  });

  test('the recorded empty template list parses', () async {
    final container = await growthContainer(stub: growthStub(empty: true));
    expect(await container.read(smsTemplatesProvider.future), isEmpty);
  });

  test('a conversation with a lead gets an AI follow-up draft', () async {
    final stub = growthStub();
    final container = await growthContainer(stub: stub);

    final draft = await container.read(
      replyDraftProvider(conversationId(2)).future,
    );
    expect(draft, (fixture('growth_ai_draft') as Map)['text']);
    expect(stub.lastBody('POST', 'ai/draft'), {
      'purpose': 'followup',
      'leadId': leadId,
    });
  });

  test('no draft for a number the CRM does not know', () async {
    final stub = growthStub();
    final container = await growthContainer(stub: stub);

    final draft = await container.read(
      replyDraftProvider(conversationId(1)).future,
    );
    expect(draft, isNull);
    expect(stub.last('POST', 'ai/draft'), isNull);
  });
}

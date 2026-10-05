import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';

import '../../helpers/api_stub.dart';
import 'growth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LeadChannel of(List<LeadChannel> channels, ChannelKind kind) =>
      channels.firstWhere((c) => c.kind == kind);

  test('nothing connected yet: every channel is available or soon', () async {
    final container = await growthContainer(stub: growthStub(empty: true));
    final channels = await container.read(leadChannelsProvider.future);

    expect(channels.where((c) => c.isConnected), isEmpty);
    expect(of(channels, ChannelKind.website).embedCode, isNull);
    expect(of(channels, ChannelKind.email).status, ChannelStatus.soon);
    expect(await container.read(facebookPageProvider.future), isNull);
    expect(container.read(messagingAccountProvider), isNull);
  });

  test('channels come from the integrations and the forms', () async {
    final container = await growthContainer();
    final channels = await container.read(leadChannelsProvider.future);

    final facebook = of(channels, ChannelKind.facebook);
    expect(facebook.isConnected, isTrue);
    expect(facebook.account, 'Rahim Traders');
    expect(facebook.integration?.id, metaId);
    expect(of(channels, ChannelKind.messenger).isConnected, isTrue);
    expect(of(channels, ChannelKind.whatsapp).account, '+8801711000099');
    expect(
      of(channels, ChannelKind.website).embedCode,
      contains('https://salesroot-api.salebee.net/f/dhaka-sales-enquiry/'),
    );
    expect(
      of(channels, ChannelKind.hostedForm).shareUrl,
      'https://salesroot-api.salebee.net/f/dhaka-sales-enquiry',
    );
    final sub = container.listen(messagingAccountProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(integrationsProvider.future);
    expect(sub.read(), 'Rahim Traders · +8801711000099');
  });

  test('turning on the first form creates an enquiry form', () async {
    final stub = growthStub(empty: true)
      ..on('POST', 'forms', {'id': formId, 'slug': 'dhaka-sales-enquiry'});
    final container = await growthContainer(stub: stub);

    final form = await container
        .read(channelActionsProvider.notifier)
        .setForm(null, active: true, name: 'Website enquiry');
    final body = stub.lastBody('POST', 'forms');
    expect(body['name'], 'Website enquiry');
    expect(body['isActive'], isTrue);
    expect(body['fields'], hasLength(3));
    expect(form.shareUrl, endsWith('/f/dhaka-sales-enquiry'));
  });

  test('turning a form off patches only its name and switch', () async {
    final stub = growthStub()..on('PATCH', 'forms/{id}', <String, Object>{});
    final container = await growthContainer(stub: stub);
    final channels = await container.read(leadChannelsProvider.future);

    await container
        .read(channelActionsProvider.notifier)
        .setForm(
          of(channels, ChannelKind.hostedForm).form,
          active: false,
          name: 'unused',
        );
    expect(stub.last('PATCH', 'forms/{id}')?.uri.path, endsWith(formId));
    expect(stub.lastBody('PATCH', 'forms/{id}'), {
      'name': 'Website enquiry',
      'isActive': false,
    });
  });

  test('an executive gets the server 403 for forms', () async {
    final stub = growthStub(empty: true)
      ..on('POST', 'forms', fixture('growth_forbidden'), status: 403);
    final container = await growthContainer(stub: stub, role: 'executive');

    await expectLater(
      container
          .read(channelActionsProvider.notifier)
          .setForm(null, active: true, name: 'Website enquiry'),
      throwsA(
        isA<ApiFailure>().having((f) => f.isForbidden, 'forbidden', true),
      ),
    );
  });

  test(
    'WhatsApp connects with the Cloud API ids; disconnect deletes',
    () async {
      final stub = growthStub(empty: true)
        ..on('POST', 'integrations/whatsapp/connect', {'id': whatsappId})
        ..on('DELETE', 'integrations/{id}', const StubReply(204));
      final container = await growthContainer(stub: stub);
      final actions = container.read(channelActionsProvider.notifier);

      final integration = await actions.connectWhatsApp(
        const WhatsAppConnectInput(
          phoneNumberId: ' 1098 ',
          wabaId: '2201',
          accessToken: 'EAAG',
          displayPhone: '',
        ),
      );
      expect(stub.lastBody('POST', 'integrations/whatsapp/connect'), {
        'phoneNumberId': '1098',
        'wabaId': '2201',
        'accessToken': 'EAAG',
      });
      expect(integration.provider, IntegrationProvider.whatsapp);

      await actions.disconnect(whatsappId);
      expect(
        stub.last('DELETE', 'integrations/{id}')?.uri.path,
        endsWith(whatsappId),
      );
    },
  );
}

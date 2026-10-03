import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';

import 'growth_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disconnecting and reconnecting the Facebook Page', () async {
    final container = await growthContainer();
    final sub = container.listen(facebookSetupProvider, (_, _) {});
    addTearDown(sub.close);
    final connected = await container.read(facebookSetupProvider.future);
    expect(connected.step, FacebookStep.connected);

    final channels = await container.read(leadChannelsProvider.future);
    final page = channels.firstWhere((c) => c.kind == ChannelKind.facebook);
    await container.read(channelActionsProvider.notifier).disconnect(page.id);
    final signIn = await container.read(facebookSetupProvider.future);
    expect(signIn.step, FacebookStep.signIn);

    final notifier = container.read(facebookSetupProvider.notifier);
    await notifier.signIn();
    final pages = container.read(facebookSetupProvider).requireValue.pages;
    await notifier.pickPage(pages.first);
    final forms = container.read(facebookSetupProvider).requireValue;
    expect(forms.step, FacebookStep.forms);
    expect(forms.enabled, isNotEmpty);

    notifier.goTo(FacebookStep.mapping);
    notifier.map('phone_number', LeadField.skip);
    await expectLater(
      notifier.save(),
      throwsA(isA<ApiFailure>().having((f) => f.isValidation, '400', true)),
    );

    notifier.map('phone_number', LeadField.mobile);
    final saved = await notifier.save();
    expect(saved.isConnected, isTrue);
    final after = await container.read(leadChannelsProvider.future);
    expect(
      after.firstWhere((c) => c.kind == ChannelKind.facebook).status,
      ChannelStatus.connected,
    );
  });
}

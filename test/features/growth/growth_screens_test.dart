import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/growth/providers/distribution_providers.dart';
import 'package:salesroot/features/growth/view/bulk_email_screen.dart';
import 'package:salesroot/features/growth/view/bulk_sms_screen.dart';
import 'package:salesroot/features/growth/view/campaign_result_screen.dart';
import 'package:salesroot/features/growth/view/campaigns_screen.dart';
import 'package:salesroot/features/growth/view/channels_screen.dart';
import 'package:salesroot/features/growth/view/distribution_screen.dart';
import 'package:salesroot/features/growth/view/facebook_connect_screen.dart';
import 'package:salesroot/features/growth/view/message_thread_screen.dart';
import 'package:salesroot/features/growth/view/messages_screen.dart';
import 'package:salesroot/features/growth/view/new_lead_screen.dart';
import 'package:salesroot/features/growth/view/new_leads_screen.dart';
import 'package:salesroot/features/growth/view/notice_screen.dart';
import 'package:salesroot/features/growth/view/notice_write_screen.dart';
import 'package:salesroot/features/growth/view/notices_screen.dart';
import 'package:salesroot/features/growth/view/rule_edit_screen.dart';
import 'package:salesroot/features/growth/view/sms_credits_screen.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import '../../helpers/api_stub.dart';
import 'growth_test_helpers.dart';

/// Every growth screen, at phone size.
final _screens = <String, Widget>{
  'channels': const ChannelsScreen(),
  'facebook': const FacebookConnectScreen(),
  'new leads': const NewLeadsScreen(),
  'new lead': NewLeadScreen(id: conversationId(1)),
  'accept': NewLeadScreen(id: conversationId(1), openAccept: true),
  'rules': const DistributionScreen(),
  'rule': const RuleEditScreen(id: '2'),
  'new rule': const RuleEditScreen(id: newRuleId),
  'messages': const MessagesScreen(),
  'thread': MessageThreadScreen(id: conversationId(2)),
  'campaigns': const CampaignsScreen(),
  'bulk sms': const BulkSmsScreen(),
  'bulk email': const BulkEmailScreen(),
  'sent campaign': const CampaignResultScreen(id: sentCampaign),
  'scheduled campaign': const CampaignResultScreen(id: scheduledCampaign),
  'credits': const SmsCreditsScreen(),
  'notices': const NoticesScreen(),
  'new notice': const NoticeWriteScreen(),
  'notice': const NoticeScreen(id: '1'),
};

Future<void> _show(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen,
) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.light,
          locale: ref.watch(appLocaleProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: screen,
        ),
      ),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Builds the container, with the role's grants and the plan loaded,
/// outside the widget test's fake clock: signing in does real async work.
Future<ProviderContainer> _container(
  WidgetTester tester, {
  ApiStub? stub,
  String role = 'owner',
}) async {
  final container = await tester.runAsync(() async {
    final container = await growthContainer(stub: stub, role: role);
    await container.read(permissionsProvider.future);
    await container.read(planProvider.future);
    return container;
  });
  if (container == null) throw StateError('No container');
  return container;
}

void main() {
  for (final locale in const [bangla, english]) {
    testWidgets('growth screens render in ${locale.languageCode}', (
      tester,
    ) async {
      final container = await _container(tester, stub: growthStub());
      container.read(appLocaleProvider.notifier).set(locale);

      for (final MapEntry(key: name, value: screen) in _screens.entries) {
        await _show(tester, container, screen);
        expect(tester.takeException(), isNull, reason: name);
        expect(find.byType(SrErrorState), findsNothing, reason: name);
      }
    });
  }

  testWidgets('an executive, offline and an empty workspace render cleanly', (
    tester,
  ) async {
    final stub = growthStub(empty: true)
      ..on('POST', 'forms', fixture('growth_forbidden'), status: 403);
    final container = await _container(tester, stub: stub, role: 'executive');
    final states = <void Function()>[() {}, () => stub.offline = true];
    for (final state in states) {
      state();
      for (final MapEntry(key: name, value: screen) in _screens.entries) {
        await _show(tester, container, screen);
        expect(tester.takeException(), isNull, reason: name);
      }
    }
  });

  bool hasReject() => find
      .byWidgetPredicate(
        (w) => w is SrButton && w.variant == SrButtonVariant.danger,
      )
      .evaluate()
      .isNotEmpty;

  testWidgets('the inbox lists open enquiries an owner can act on', (
    tester,
  ) async {
    final container = await _container(tester, stub: growthStub());
    await _show(tester, container, const NewLeadsScreen());
    expect(find.text('Customer 1'), findsOneWidget);

    await _show(tester, container, NewLeadScreen(id: conversationId(1)));
    expect(hasReject(), isTrue);
  });

  testWidgets('a member can read an enquiry but not act on it', (tester) async {
    final container = await _container(
      tester,
      stub: growthStub(),
      role: 'executive',
    );
    await _show(tester, container, NewLeadScreen(id: conversationId(1)));
    expect(find.text('Customer 1'), findsWidgets);
    expect(hasReject(), isFalse);
  });

  testWidgets('a sent campaign shows its four numbers', (tester) async {
    final container = await _container(tester, stub: growthStub());
    container.read(appLocaleProvider.notifier).set(english);
    await _show(
      tester,
      container,
      const CampaignResultScreen(id: sentCampaign),
    );
    expect(find.byType(SrKpiTile), findsNWidgets(4));
    expect(find.text('90%'), findsOneWidget);
  });
}

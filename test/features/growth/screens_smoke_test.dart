import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/routing/no_access_screen.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/widgets/widgets.dart';

void main() {
  final routes = [
    Routes.growthChannels,
    Routes.growthFacebook,
    Routes.newLeads,
    Routes.newLeadFor(1),
    Routes.newLeadAcceptFor(4),
    Routes.distribution,
    Routes.distributionRuleFor(2),
    Routes.distributionRuleFor(0),
    Routes.messages,
    Routes.messageThreadFor(1),
    Routes.campaigns,
    Routes.campaignSms,
    Routes.campaignEmail,
    Routes.campaignFor(1),
    Routes.campaignFor(3),
    Routes.campaignCredits,
    Routes.notices,
    Routes.noticeNew,
    Routes.noticeFor(1),
  ];

  for (final locale in [bangla, english]) {
    testWidgets('every growth screen renders in ${locale.languageCode}', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({
        'session': jsonEncode({
          'Token': 't',
          'UserId': 1,
          'Name': 'Karim Hossain',
        }),
      });
      SharedPreferences.setMockInitialValues({
        'current_workspace': 300,
        'language': locale.languageCode,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      container
          .read(devSettingsProvider.notifier)
          .update(
            (s) => s.copyWith(latency: false, role: () => WorkspaceRole.owner),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await _settle(tester);

      for (final route in routes) {
        container.read(appRouterProvider).go(route);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: route);
        expect(find.byType(SrComingSoonScreen), findsNothing, reason: route);
        expect(find.byType(SrErrorState), findsNothing, reason: route);
        expect(find.byType(NoAccessScreen), findsNothing, reason: route);
        expect(find.byType(SrSkeletonList), findsNothing, reason: route);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

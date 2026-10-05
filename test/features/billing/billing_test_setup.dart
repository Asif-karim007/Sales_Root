import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/translations/translations.dart';

import '../../helpers/api_stub.dart';

const referralId = '01a10d1d-663d-707f-958f-870a41e2d634';

/// Every billing and referral endpoint, answering from the recorded
/// responses of the test user. `billing` comes from `apiContainer`.
ApiStub billingStub() => ApiStub()
  ..on('GET', 'billing/catalogue', fixture('billing_catalogue'))
  ..on('GET', 'billing/history', fixture('billing_history'))
  ..on('POST', 'billing/quote', fixture('billing_quote'))
  ..on('GET', 'referrals', fixture('billing_referrals'))
  ..on('GET', 'referrals/check', fixture('billing_referral_check'))
  ..on('POST', 'referrals', fixture('billing_referral_created'))
  ..on('GET', 'wallet/transactions', fixture('billing_wallet_transactions'))
  ..on('GET', 'contacts', fixture('billing_contacts'));

/// A signed-in container over [stub] as Rafi with [role], whose workspace and
/// grants are loaded.
Future<ProviderContainer> billingContainer(
  ApiStub stub, {
  String role = 'owner',
  List<Override> overrides = const [],
}) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: role, level: 'advanced'),
    overrides: overrides,
  );
  container.listen(currentWorkspaceProvider, (_, _) {});
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  return container;
}

void listenTo(ProviderContainer container, ProviderListenable<Object?> p) {
  final sub = container.listen(p, (_, _) {});
  addTearDown(sub.close);
}

/// Pumps [screen] at phone width in [locale] and lets its requests land.
Future<void> pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: screen,
      ),
    ),
  );
  await settle(tester);
}

/// Lets requests answered by the stub land between frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

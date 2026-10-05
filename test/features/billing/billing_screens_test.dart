import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/view/add_on_store_screen.dart';
import 'package:salesroot/features/billing/view/add_ons_later_screen.dart';
import 'package:salesroot/features/billing/view/billing_history_screen.dart';
import 'package:salesroot/features/billing/view/checkout_screen.dart';
import 'package:salesroot/features/billing/view/choose_plan_screen.dart';
import 'package:salesroot/features/billing/view/plan_activated_screen.dart';
import 'package:salesroot/features/billing/view/plan_compare_screen.dart';
import 'package:salesroot/features/billing/view/plan_usage_screen.dart';
import 'package:salesroot/features/billing/view/refer_screen.dart';
import 'package:salesroot/features/billing/view/referral_list_screen.dart';
import 'package:salesroot/features/billing/view/referral_qr_screen.dart';
import 'package:salesroot/features/billing/view/referral_wallet_screen.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import 'billing_test_setup.dart';

const _upgrade = CheckoutRequest(
  plan: 'business',
  seats: 25,
  cycle: BillingCycle.yearly,
  packs: ['sms_1000'],
);

void main() {
  final screens = <String, (Widget, String?)>{
    'plan and usage': (const PlanUsageScreen(), 'Business'),
    'compare': (const PlanCompareScreen(target: 'business'), null),
    'choose': (const ChoosePlanScreen(), 'Team'),
    'card scans limit': (
      const ChoosePlanScreen(quota: QuotaKind.cardScans),
      null,
    ),
    'users limit': (const ChoosePlanScreen(quota: QuotaKind.users), null),
    'sms limit': (const ChoosePlanScreen(quota: QuotaKind.smsCredits), null),
    'add-ons later': (
      const AddOnsLaterScreen(request: CheckoutRequest(plan: 'team', seats: 5)),
      'Field Force',
    ),
    'checkout': (
      const CheckoutScreen(request: _upgrade),
      'Business · 25 users · yearly',
    ),
    'activated': (const PlanActivatedScreen(), 'Business'),
    'add-on store': (const AddOnStoreScreen(), '+200 card scans'),
    'refer': (const ReferScreen(), 'Q95ED5'),
    'my referrals': (const ReferralListScreen(), 'se***@example.com'),
    'wallet': (const ReferralWalletScreen(), null),
    'qr': (const ReferralQrScreen(), 'Q95ED5'),
  };

  for (final locale in [english, bangla]) {
    group('owner screens in ${locale.languageCode}', () {
      for (final MapEntry(key: name, value: (screen, text))
          in screens.entries) {
        testWidgets(name, (tester) async {
          final container = await tester.runAsync(
            () => billingContainer(billingStub()),
          );
          if (container == null) return;

          await pumpScreen(tester, container, screen, locale: locale);

          expect(tester.takeException(), isNull);
          expect(find.byType(SrErrorState), findsNothing);
          if (locale == english && text != null) {
            expect(find.textContaining(text), findsWidgets);
          }
        });
      }
    });
  }

  testWidgets('an empty history offers the plans', (tester) async {
    final container = await tester.runAsync(
      () => billingContainer(billingStub()),
    );
    if (container == null) return;
    final l10n = lookupAppLocalizations(english);

    await pumpScreen(tester, container, const BillingHistoryScreen());

    expect(find.text(l10n.billingHistoryEmpty), findsOneWidget);
  });

  testWidgets('a member at a limit is told to ask the owner', (tester) async {
    final container = await tester.runAsync(
      () => billingContainer(billingStub(), role: 'executive'),
    );
    if (container == null) return;
    final l10n = lookupAppLocalizations(english);

    await pumpScreen(
      tester,
      container,
      const ChoosePlanScreen(quota: QuotaKind.cardScans),
    );

    expect(find.text(l10n.billingNotNow), findsOneWidget);
  });

  testWidgets('a refused payment shows why, with a retry', (tester) async {
    final stub = billingStub()
      ..fail('POST', 'billing/checkout', 403, message: 'Owner only');
    final container = await tester.runAsync(() => billingContainer(stub));
    if (container == null) return;
    listenTo(container, checkoutFlowProvider);
    final l10n = lookupAppLocalizations(english);

    await pumpScreen(
      tester,
      container,
      const CheckoutScreen(request: _upgrade),
    );
    await tester.tap(find.textContaining('Pay ').last);
    await settle(tester);

    expect(container.read(checkoutFlowProvider).phase, CheckoutPhase.failed);
    expect(find.text(l10n.billingPaymentFailed), findsOneWidget);
    expect(find.text('Owner only'), findsOneWidget);
  });

  testWidgets('a failed price shows the error state', (tester) async {
    final stub = billingStub()..fail('POST', 'billing/quote', 500);
    final container = await tester.runAsync(() => billingContainer(stub));
    if (container == null) return;

    await pumpScreen(
      tester,
      container,
      const CheckoutScreen(request: _upgrade),
    );

    expect(find.byType(SrErrorState), findsOneWidget);
    expect(
      container
          .read(checkoutQuoteProvider(_upgrade, PaymentKind.bkash, true))
          .error,
      isA<ApiFailure>(),
    );
  });
}

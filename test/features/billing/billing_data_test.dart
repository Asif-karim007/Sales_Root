import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/models/usage.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';

import '../../helpers/api_stub.dart';
import 'billing_test_setup.dart';

void main() {
  group('catalogue', () {
    final catalog = BillingCatalog.fromJson(fixtureMap('billing_catalogue'));

    test('plans are cheapest first; plans sold on request are left out', () {
      expect(catalog.plans.map((p) => p.code), [
        'free',
        'personal',
        'team',
        'business',
      ]);
      final team = catalog.plan('team');
      expect(team.pricePerUser, 399);
      expect(team.yearlyPerUser, 333);
      expect(team.minUsers, 3);
      expect(team.storageGb, 20);
      expect(team.layers, ['sales', 'collection', 'customer360']);
      expect(catalog.nextAfter(team)?.code, 'business');
    });

    test('a year is billed twelve months at the yearly price', () {
      final business = catalog.plan('business');
      expect(business.seatPrice(BillingCycle.yearly), 5988);
      expect(business.seatPrice(BillingCycle.monthly), 599);
      expect(business.yearlySaving(25), (599 - 499) * 12 * 25);
    });

    test('add-ons open a layer or raise a quota', () {
      final fieldForce = catalog.addOnOrNull('fieldforce');
      final sms = catalog.addOnOrNull('sms_1000');
      final storage = catalog.addOnOrNull('storage_10');
      expect(fieldForce?.unit, AddOnUnit.perUser);
      expect(fieldForce?.layer, 'fieldforce');
      expect(fieldForce?.isPack, isFalse);
      expect(fieldForce?.name.bn, 'ফিল্ড ফোর্স');
      expect(sms?.isPack, isTrue);
      expect(sms?.quota, QuotaKind.smsCredits);
      expect(sms?.amount, 1000);
      expect(storage?.quota, QuotaKind.storage);
      expect(storage?.amount, 10);
      expect(
        catalog.includingPlan(fieldForce ?? sms ?? storage!)?.code,
        'business',
      );
    });

    test('a limit offers its pack and the plan that raises it', () {
      const subscription = Subscription(
        planCode: 'team',
        seats: 5,
        activeUsers: 5,
      );
      final scans = LimitOffer.of(QuotaKind.cardScans, catalog, subscription);
      final users = LimitOffer.of(QuotaKind.users, catalog, subscription);
      final sms = LimitOffer.of(QuotaKind.smsCredits, catalog, subscription);

      expect(scans.pack?.code, 'scans_200');
      expect(scans.upgrade?.code, 'business');
      expect(users.extraSeats, LimitOffer.seatStep);
      expect(users.quickFix(subscription)?.seats, 10);
      expect(sms.pack?.code, 'sms_1000');
      expect(sms.upgrade, isNull);
    });
  });

  group('subscription', () {
    test('comes from GET billing', () async {
      final container = await billingContainer(billingStub());

      final overview = await container.read(billingOverviewProvider.future);

      expect(overview.plan.code, 'business');
      expect(overview.subscription.seats, 25);
      expect(overview.subscription.activeUsers, 5);
      expect(overview.addOns, isEmpty);
      final fieldForce = overview.catalog.addOnOrNull('fieldforce');
      expect(fieldForce != null && overview.isOn(fieldForce), isTrue);
      expect(overview.meters.first.used, 5);
      expect(overview.meters.first.limit, 25);
    });

    test('a member is refused billing', () async {
      final stub = billingStub()..fail('GET', 'billing', 403);
      final container = await billingContainer(stub, role: 'executive');

      await expectLater(
        container.read(subscriptionProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', isTrue)),
      );
    });

    test('the bill history parses an empty year', () async {
      final container = await billingContainer(billingStub());

      expect(await container.read(invoicesProvider.future), isEmpty);
    });
  });

  group('checkout', () {
    const request = CheckoutRequest(
      plan: 'business',
      seats: 25,
      cycle: BillingCycle.yearly,
      packs: ['sms_1000'],
    );

    test('the server prices the order', () async {
      final stub = billingStub();
      final container = await billingContainer(stub);
      final provider = checkoutQuoteProvider(request, PaymentKind.bkash, true);
      listenTo(container, provider);

      final quote = await container.read(provider.future);

      expect(stub.lastBody('POST', 'billing/quote'), {
        'planKey': 'business',
        'users': 25,
        'cycle': 'yearly',
        'addons': [
          {'key': 'sms_1000', 'qty': 1},
        ],
        'gateway': 'bkash',
        'useCredits': true,
      });
      expect(quote.lines.first.item, 'Business · 25 users · yearly');
      expect(quote.lines.first.amount, 149700);
      expect(quote.subtotal, 150050);
      expect(quote.vatPercent, 5);
      expect(quote.total, 157553);
    });

    test('an unknown plan is a validation error', () async {
      final stub = billingStub()
        ..on(
          'POST',
          'billing/quote',
          fixture('billing_quote_unknown_plan'),
          status: 422,
        );
      final container = await billingContainer(stub);
      final provider = checkoutQuoteProvider(
        const CheckoutRequest(plan: 'nope'),
        PaymentKind.bkash,
        false,
      );
      listenTo(container, provider);

      await expectLater(
        container.read(provider.future),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.fieldErrors['planKey'],
            'planKey',
            'Plan not found',
          ),
        ),
      );
    });

    test('a pack keeps the plan the workspace is on', () {
      const current = Subscription(
        planCode: 'team',
        seats: 5,
        activeUsers: 5,
        layers: ['sales', 'collection', 'customer360', 'fieldforce'],
      );
      final catalog = BillingCatalog.fromJson(fixtureMap('billing_catalogue'));

      final order = const CheckoutRequest(packs: ['scans_200']).toCheckout(
        current: current,
        catalog: catalog,
        method: PaymentKind.nagad,
        useCredits: false,
      );

      expect(order['planKey'], 'team');
      expect(order['users'], 5);
      expect(order['addons'], [
        {'key': 'fieldforce', 'qty': 1},
        {'key': 'scans_200', 'qty': 1},
      ]);
    });

    test('a refused payment leaves the flow failed', () async {
      final stub = billingStub()..fail('POST', 'billing/checkout', 403);
      final container = await billingContainer(stub);
      listenTo(container, checkoutFlowProvider);

      await container.read(checkoutFlowProvider.notifier).pay(request);

      final flow = container.read(checkoutFlowProvider);
      expect(flow.phase, CheckoutPhase.failed);
      expect(flow.failure?.isForbidden, isTrue);
    });

    test('a gateway page is opened, then the payment is verified', () async {
      final stub = billingStub()
        ..on('POST', 'billing/checkout', const {
          'invoiceId': 'inv-1',
          'txId': 'tx-1',
          'paymentUrl': 'https://pay.example/tx-1',
        })
        ..on('POST', 'billing/verify/{txId}', const {});
      final container = await billingContainer(stub);
      listenTo(container, checkoutFlowProvider);
      final notifier = container.read(checkoutFlowProvider.notifier);

      await notifier.pay(request);
      expect(
        container.read(checkoutFlowProvider).phase,
        CheckoutPhase.awaitingPayment,
      );

      await notifier.confirm();
      expect(container.read(checkoutFlowProvider).phase, CheckoutPhase.done);
      expect(
        stub.last('POST', 'billing/verify/{txId}')?.path,
        endsWith('tx-1'),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/data/billing_fixtures.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/pricing.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/models/usage.dart';

void main() {
  final catalog = BillingCatalog.fromJson(billingCatalogJson);

  Subscription team({int unusedDays = 6, int seats = 25}) => Subscription(
    planCode: 'Team',
    seats: seats,
    cycle: BillingCycle.monthly,
    activeUsers: 18,
    unusedDays: unusedDays,
    addOns: const {'FieldForce'},
  );

  group('seat prices', () {
    test('Team is 399 a user, so 25 users cost 9,975 a month', () {
      expect(BillingPricing.seatsPrice(399, 25, BillingCycle.monthly), 9975);
    });

    test('a year bills ten months and saves two', () {
      expect(BillingPricing.seatsPrice(399, 25, BillingCycle.yearly), 99750);
      expect(BillingPricing.yearlySaving(399, 25), 19950);
    });

    test('the renewal adds recurring add-ons per seat', () {
      expect(BillingPricing.renewal(catalog, team()), 9975 + 2475);
    });
  });

  group('quote', () {
    test('Team to Business matches the prototype order (#100)', () {
      final quote = BillingPricing.quote(
        catalog: catalog,
        current: team(),
        request: const CheckoutRequest(plan: 'Business'),
      );
      expect([for (final l in quote.lines) l.amount], [14975, -1995, 2475]);
      expect(quote.lines[1].kind, OrderLineKind.planCredit);
      expect(quote.subtotal, 15455);
      expect(quote.vat, 773);
      expect(quote.total, 16228);
    });

    test('referral credits come off before VAT', () {
      final quote = BillingPricing.quote(
        catalog: catalog,
        current: team(),
        request: const CheckoutRequest(plan: 'Business'),
        walletBalance: 760,
        useCredits: true,
      );
      expect(quote.credits, 760);
      expect(quote.vat, 735);
      expect(quote.total, 15455 - 760 + 735);
    });

    test('credits never take the bill below zero', () {
      final quote = BillingPricing.quote(
        catalog: catalog,
        current: team(),
        request: const CheckoutRequest(packs: ['Scans50']),
        walletBalance: 5000,
        useCredits: true,
      );
      expect(quote.credits, 199);
      expect(quote.total, 0);
      expect(quote.isFree, isTrue);
    });

    test('credits are ignored when switched off', () {
      final quote = BillingPricing.quote(
        catalog: catalog,
        current: team(),
        request: const CheckoutRequest(packs: ['Scans50']),
        walletBalance: 5000,
      );
      expect(quote.credits, 0);
      expect(quote.total, 199 + 10);
    });

    test('an add-on bought mid-period is prorated for every seat', () {
      final quote = BillingPricing.quote(
        catalog: catalog,
        current: team(unusedDays: 3),
        request: const CheckoutRequest(addOns: {'FieldForce', 'Growth'}),
      );
      expect(quote.lines, hasLength(1));
      expect(quote.lines.single.kind, OrderLineKind.addOnProrated);
      expect(quote.lines.single.amount, 373);
    });

    test('extra seats are prorated with the add-ons they carry', () {
      final quote = BillingPricing.quote(
        catalog: catalog,
        current: team(unusedDays: 15),
        request: const CheckoutRequest(seats: 30),
      );
      expect([for (final l in quote.lines) l.amount], [998, 248]);
    });

    test('a yearly switch starts a new period at ten months', () {
      final quote = BillingPricing.quote(
        catalog: catalog,
        current: team(unusedDays: 0),
        request: const CheckoutRequest(cycle: BillingCycle.yearly),
      );
      expect([for (final l in quote.lines) l.amount], [99750, 24750]);
    });

    test('an add-on included in the plan is not charged', () {
      final quote = BillingPricing.quote(
        catalog: catalog,
        current: team(unusedDays: 0),
        request: const CheckoutRequest(
          plan: 'Business',
          addOns: {'FieldForce', 'AiAssistant'},
        ),
      );
      expect(quote.lines.map((l) => l.code), ['Business', 'FieldForce']);
    });

    test('an unknown plan is a 400', () {
      expect(
        () => BillingPricing.quote(
          catalog: catalog,
          current: team(),
          request: const CheckoutRequest(plan: 'Gold'),
        ),
        throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'status', 400)),
      );
    });
  });

  group('limit prompt (#98)', () {
    LimitOffer offer(QuotaKind kind, Subscription subscription) =>
        LimitOffer.of(kind, catalog, subscription);

    test('card scans offer +50 for 199 or Business', () {
      final limit = offer(QuotaKind.cardScans, team());
      expect(limit.limit, 50);
      expect(limit.pack?.code, 'Scans50');
      expect(limit.quickFixPrice, 199);
      expect(limit.upgrade?.code, 'Business');
      expect(limit.quickFix(team()), const CheckoutRequest(packs: ['Scans50']));
    });

    test('users offer five more seats on the same plan', () {
      final limit = offer(QuotaKind.users, team());
      expect(limit.pack, isNull);
      expect(limit.extraSeats, 5);
      expect(limit.quickFixPrice, 1995);
      expect(limit.quickFix(team()), const CheckoutRequest(seats: 30));
      expect(limit.upgrade?.code, 'Business');
    });

    test('records only offer the upgrade', () {
      final limit = offer(QuotaKind.records, team());
      expect(limit.hasQuickFix, isFalse);
      expect(limit.limit, 25000);
      expect(limit.upgrade?.code, 'Business');
    });

    test('storage offers +10 GB and the upgrade', () {
      final limit = offer(QuotaKind.storage, team());
      expect(limit.pack?.code, 'Storage10');
      expect(limit.upgrade?.code, 'Business');
    });

    test('SMS credits offer a pack and no plan', () {
      final limit = offer(QuotaKind.smsCredits, team());
      expect(limit.pack?.code, 'Sms1000');
      expect(limit.upgrade, isNull);
    });

    test('a Free user cannot add seats and is sent to Team', () {
      const free = Subscription(
        planCode: 'Free',
        seats: 1,
        cycle: BillingCycle.monthly,
        activeUsers: 1,
      );
      final limit = offer(QuotaKind.users, free);
      expect(limit.hasQuickFix, isFalse);
      expect(limit.upgrade?.code, 'Team');
      expect(offer(QuotaKind.cardScans, free).upgrade?.code, 'PersonalPro');
    });

    test('bought packs raise the limit and the top plan has no upgrade', () {
      const business = Subscription(
        planCode: 'Business',
        seats: 10,
        cycle: BillingCycle.monthly,
        activeUsers: 6,
        extraCardScans: 50,
      );
      final limit = offer(QuotaKind.cardScans, business);
      expect(limit.limit, 550);
      expect(limit.upgrade, isNull);
      expect(limit.pack?.code, 'Scans50');
    });
  });
}

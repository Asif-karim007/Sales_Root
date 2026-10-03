import 'dart:math';

import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

/// The price maths, in whole taka. The server runs the same rules and rejects
/// a payment whose total disagrees.
abstract final class BillingPricing {
  static int seatsPrice(int pricePerUser, int seats, BillingCycle cycle) =>
      pricePerUser * seats * cycle.billedMonths;

  /// What a year saves against paying monthly.
  static int yearlySaving(int pricePerUser, int seats) =>
      pricePerUser *
      seats *
      (BillingCycle.yearly.months - BillingCycle.yearly.billedMonths);

  static int prorate(int periodAmount, int days, int periodDays) =>
      periodDays <= 0 ? 0 : (periodAmount * days / periodDays).round();

  static int vatOf(int amount, int percent) => (amount * percent / 100).round();

  /// The recurring bill at the next renewal, before VAT.
  static int renewal(BillingCatalog catalog, Subscription subscription) {
    final plan = catalog.planOrNull(subscription.planCode);
    if (plan == null) return 0;
    var total = seatsPrice(
      plan.pricePerUser,
      subscription.seats,
      subscription.cycle,
    );
    for (final code in subscription.addOns) {
      final offer = catalog.addOnOrNull(code);
      if (offer == null || offer.isPack || offer.includedIn == plan.code) {
        continue;
      }
      total += seatsPrice(offer.price, subscription.seats, subscription.cycle);
    }
    return total;
  }

  /// Prices [request] against [current]. A new plan or cycle starts a fresh
  /// period and credits the unused days of the old plan; anything else is
  /// prorated to the end of the current period. Referral credits come off
  /// before VAT and never below zero.
  static Quote quote({
    required BillingCatalog catalog,
    required Subscription current,
    required CheckoutRequest request,
    int walletBalance = 0,
    bool useCredits = false,
  }) {
    final plan = catalog.plan(request.plan ?? current.planCode);
    final cycle = request.cycle ?? current.cycle;
    final seats = request.seats ?? current.seats;
    final addOns = request.addOns ?? current.addOns;
    final newPeriod = plan.code != current.planCode || cycle != current.cycle;
    final lines = newPeriod
        ? _newPeriod(catalog, current, plan, cycle, seats, addOns)
        : _prorated(catalog, current, plan, cycle, seats, addOns);
    for (final code in request.packs) {
      final pack = catalog.addOn(code);
      lines.add(
        OrderLine(
          kind: OrderLineKind.pack,
          code: pack.code,
          name: pack.name,
          amount: pack.price,
        ),
      );
    }
    final subtotal = max(0, lines.fold<int>(0, (sum, l) => sum + l.amount));
    final credits = useCredits ? min(max(0, walletBalance), subtotal) : 0;
    final vat = vatOf(subtotal - credits, catalog.vatPercent);
    return Quote(
      lines: lines,
      subtotal: subtotal,
      credits: credits,
      vatPercent: catalog.vatPercent,
      vat: vat,
      total: subtotal - credits + vat,
    );
  }

  static List<OrderLine> _newPeriod(
    BillingCatalog catalog,
    Subscription current,
    PlanOffer plan,
    BillingCycle cycle,
    int seats,
    Set<String> addOns,
  ) {
    final lines = [
      OrderLine(
        kind: OrderLineKind.plan,
        code: plan.code,
        name: LocalizedName(plan.name, plan.name),
        amount: seatsPrice(plan.pricePerUser, seats, cycle),
        seats: seats,
        cycle: cycle,
      ),
    ];
    final old = catalog.planOrNull(current.planCode);
    if (old != null && !old.isFree && current.unusedDays > 0) {
      final credit = prorate(
        seatsPrice(old.pricePerUser, current.seats, current.cycle),
        current.unusedDays,
        current.cycle.days,
      );
      if (credit > 0) {
        lines.add(
          OrderLine(
            kind: OrderLineKind.planCredit,
            code: old.code,
            name: LocalizedName(old.name, old.name),
            amount: -credit,
            days: current.unusedDays,
          ),
        );
      }
    }
    for (final offer in _recurring(catalog, plan, addOns)) {
      lines.add(
        OrderLine(
          kind: OrderLineKind.addOn,
          code: offer.code,
          name: offer.name,
          amount: seatsPrice(offer.price, seats, cycle),
          seats: seats,
          cycle: cycle,
        ),
      );
    }
    return lines;
  }

  static List<OrderLine> _prorated(
    BillingCatalog catalog,
    Subscription current,
    PlanOffer plan,
    BillingCycle cycle,
    int seats,
    Set<String> addOns,
  ) {
    final days = current.unusedDays;
    final extra = seats - current.seats;
    final lines = <OrderLine>[
      if (extra > 0)
        OrderLine(
          kind: OrderLineKind.seats,
          code: plan.code,
          name: LocalizedName(plan.name, plan.name),
          amount: prorate(
            seatsPrice(plan.pricePerUser, extra, cycle),
            days,
            cycle.days,
          ),
          seats: extra,
          days: days,
          cycle: cycle,
        ),
    ];
    for (final offer in _recurring(catalog, plan, addOns)) {
      final billed = current.hasAddOn(offer.code) ? extra : seats;
      if (billed <= 0) continue;
      lines.add(
        OrderLine(
          kind: OrderLineKind.addOnProrated,
          code: offer.code,
          name: offer.name,
          amount: prorate(
            seatsPrice(offer.price, billed, cycle),
            days,
            cycle.days,
          ),
          seats: billed,
          days: days,
          cycle: cycle,
        ),
      );
    }
    return lines;
  }

  static Iterable<AddOnOffer> _recurring(
    BillingCatalog catalog,
    PlanOffer plan,
    Set<String> codes,
  ) => [
    for (final code in codes) catalog.addOn(code),
  ].where((offer) => !offer.isPack && offer.includedIn != plan.code);
}

import 'package:collection/collection.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

/// What the user is about to buy. Null fields keep the current subscription's
/// value; [addOns] is the full set of per-seat add-ons wanted afterwards.
class CheckoutRequest {
  const CheckoutRequest({
    this.plan,
    this.seats,
    this.cycle,
    this.addOns,
    this.packs = const [],
  });

  final String? plan;
  final int? seats;
  final BillingCycle? cycle;
  final Set<String>? addOns;
  final List<String> packs;

  bool get isEmpty =>
      plan == null &&
      seats == null &&
      cycle == null &&
      addOns == null &&
      packs.isEmpty;

  factory CheckoutRequest.fromQuery(Map<String, String> query) {
    final addOns = query['addOns'];
    final packs = query['packs'];
    return CheckoutRequest(
      plan: query['plan'],
      seats: int.tryParse(query['seats'] ?? ''),
      cycle: BillingCycle.values.asNameMap()[query['cycle']],
      addOns: addOns?.split(',').where((c) => c.isNotEmpty).toSet(),
      packs: packs == null
          ? const []
          : packs.split(',').where((c) => c.isNotEmpty).toList(),
    );
  }

  Map<String, String> toQuery() {
    final plan = this.plan;
    final seats = this.seats;
    final cycle = this.cycle;
    final addOns = this.addOns;
    return {
      'plan': ?plan,
      if (seats != null) 'seats': '$seats',
      if (cycle != null) 'cycle': cycle.name,
      if (addOns != null) 'addOns': addOns.join(','),
      if (packs.isNotEmpty) 'packs': packs.join(','),
    };
  }

  String locationOf(String path) =>
      Uri(path: path, queryParameters: toQuery()).toString();

  String get checkoutLocation => locationOf(Routes.checkout);

  CheckoutRequest copyWith({Set<String>? addOns, List<String>? packs}) =>
      CheckoutRequest(
        plan: plan,
        seats: seats,
        cycle: cycle,
        addOns: addOns ?? this.addOns,
        packs: packs ?? this.packs,
      );

  /// The `Checkout` body that `billing/quote` prices and `billing/checkout`
  /// charges: the whole plan with its add-ons and packs.
  Map<String, dynamic> toCheckout({
    required Subscription current,
    required BillingCatalog catalog,
    required PaymentKind method,
    required bool useCredits,
  }) => {
    'planKey': plan ?? current.planCode,
    'users': seats ?? current.seats,
    'cycle': (cycle ?? BillingCycle.monthly).wire,
    'addons': [
      for (final code in addOns ?? current.addOnsOver(catalog))
        {'key': code, 'qty': 1},
      for (final code in packs) {'key': code, 'qty': 1},
    ],
    'gateway': method.wire,
    'useCredits': useCredits,
  };

  @override
  bool operator ==(Object other) =>
      other is CheckoutRequest &&
      other.plan == plan &&
      other.seats == seats &&
      other.cycle == cycle &&
      const SetEquality<String>().equals(other.addOns, addOns) &&
      const ListEquality<String>().equals(other.packs, packs);

  @override
  int get hashCode => Object.hash(
    plan,
    seats,
    cycle,
    addOns == null ? null : const SetEquality<String>().hash(addOns),
    const ListEquality<String>().hash(packs),
  );
}

/// One priced line, as the server words it.
class OrderLine {
  const OrderLine({required this.item, required this.amount});

  final String item;
  final int amount;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    item: json['item'] as String? ?? '',
    amount: jsonDouble(json['amount'])?.round() ?? 0,
  );
}

/// The server's price for an order: lines, referral credits taken before VAT,
/// VAT and the amount to pay now.
class Quote {
  const Quote({
    required this.lines,
    required this.subtotal,
    required this.credits,
    required this.vat,
    required this.total,
  });

  final List<OrderLine> lines;
  final int subtotal;
  final int credits;
  final int vat;
  final int total;

  bool get isFree => total == 0;

  /// VAT as a share of what it was charged on.
  int get vatPercent {
    final base = subtotal - credits;
    return base <= 0 ? 0 : (vat * 100 / base).round();
  }

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    lines: jsonList(json['lines'], OrderLine.fromJson),
    subtotal: jsonDouble(json['subtotal'])?.round() ?? 0,
    credits: jsonDouble(json['creditsApplied'])?.round() ?? 0,
    vat: jsonDouble(json['vat'])?.round() ?? 0,
    total: jsonDouble(json['total'])?.round() ?? 0,
  );
}

/// What `billing/checkout` answers: the bill raised and, for a gateway, where
/// to pay it and the transaction to verify afterwards.
class CheckoutResult {
  const CheckoutResult({
    this.invoiceId,
    this.transactionId,
    this.paymentUrl,
    this.paid = false,
  });

  final String? invoiceId;
  final String? transactionId;
  final String? paymentUrl;

  /// Nothing left to pay: credits covered it, or the plan is free.
  final bool paid;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final invoice = jsonMap(json['invoice']);
    final url = json['paymentUrl'] ?? json['redirectUrl'] ?? json['gatewayUrl'];
    return CheckoutResult(
      invoiceId: jsonId(json['invoiceId'] ?? invoice['id']),
      transactionId: jsonId(json['txId'] ?? json['transactionId']),
      paymentUrl: url is String && url.isNotEmpty ? url : null,
      paid: json['status'] == 'paid' || invoice['status'] == 'paid',
    );
  }
}

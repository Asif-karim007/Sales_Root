import 'package:collection/collection.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

/// What the user is about to buy. Null fields keep the current subscription's
/// value; [addOns] is the full set of recurring add-ons wanted afterwards.
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

enum OrderLineKind {
  plan('Plan'),
  seats('Seats'),
  planCredit('PlanCredit'),
  addOn('AddOn'),
  addOnProrated('AddOnProrated'),
  pack('Pack');

  const OrderLineKind(this.wire);

  final String wire;

  static OrderLineKind fromWire(String? value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => pack);
}

/// One priced line of an order or invoice; [amount] is negative for credits.
class OrderLine {
  const OrderLine({
    required this.kind,
    required this.code,
    required this.name,
    required this.amount,
    this.seats = 0,
    this.days = 0,
    this.cycle = BillingCycle.monthly,
  });

  final OrderLineKind kind;
  final String code;
  final LocalizedName name;
  final int amount;
  final int seats;
  final int days;
  final BillingCycle cycle;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    kind: OrderLineKind.fromWire(json['Kind'] as String?),
    code: json['Code'] as String? ?? '',
    name: LocalizedName.fromJson(json),
    amount: jsonInt(json['Amount']) ?? 0,
    seats: jsonInt(json['Seats']) ?? 0,
    days: jsonInt(json['Days']) ?? 0,
    cycle: BillingCycle.fromWire(json['Cycle'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'Kind': kind.wire,
    'Code': code,
    'Name': name.en,
    'NameBn': name.bn,
    'Amount': amount,
    'Seats': seats,
    'Days': days,
    'Cycle': cycle.wire,
  };
}

/// The priced order: lines, referral credits taken before VAT, VAT and the
/// amount to pay now.
class Quote {
  const Quote({
    required this.lines,
    required this.subtotal,
    required this.credits,
    required this.vatPercent,
    required this.vat,
    required this.total,
  });

  final List<OrderLine> lines;
  final int subtotal;
  final int credits;
  final int vatPercent;
  final int vat;
  final int total;

  bool get isFree => total == 0;

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    lines: jsonList(json['Lines'], OrderLine.fromJson),
    subtotal: jsonInt(json['Subtotal']) ?? 0,
    credits: jsonInt(json['CreditsApplied']) ?? 0,
    vatPercent: jsonInt(json['VatPercent']) ?? 0,
    vat: jsonInt(json['Vat']) ?? 0,
    total: jsonInt(json['Total']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'Lines': [for (final line in lines) line.toJson()],
    'Subtotal': subtotal,
    'CreditsApplied': credits,
    'VatPercent': vatPercent,
    'Vat': vat,
    'Total': total,
  };
}

/// What a successful payment returns.
class Purchase {
  const Purchase({required this.invoice, required this.subscription});

  final Invoice invoice;
  final Subscription subscription;
}

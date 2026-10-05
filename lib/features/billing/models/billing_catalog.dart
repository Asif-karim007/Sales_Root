import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum BillingCycle {
  monthly('monthly', months: 1),
  yearly('yearly', months: 12);

  const BillingCycle(this.wire, {required this.months});

  final String wire;
  final int months;

  static BillingCycle fromWire(String? value) =>
      value == yearly.wire ? yearly : monthly;
}

/// A plan from `GET billing/catalogue`. Prices are per user per month; a
/// yearly plan is billed twelve months at [yearlyPerUser].
class PlanOffer {
  const PlanOffer({
    required this.code,
    required this.name,
    required this.rank,
    required this.pricePerUser,
    required this.yearlyPerUser,
    required this.minUsers,
    required this.records,
    required this.cardScans,
    required this.storageGb,
    this.layers = const [],
  });

  final String code;
  final String name;
  final int rank;
  final int pricePerUser;
  final int yearlyPerUser;

  /// The fewest seats the plan is sold with.
  final int minUsers;
  final int records;
  final int cardScans;
  final int storageGb;

  /// The parts of the app the plan opens: sales, collection, fieldforce…
  final List<String> layers;

  bool get isFree => code == 'free';

  /// The price of one seat for one [cycle].
  int seatPrice(BillingCycle cycle) => cycle == BillingCycle.yearly
      ? yearlyPerUser * BillingCycle.yearly.months
      : pricePerUser;

  /// What a year saves against paying monthly, for [seats].
  int yearlySaving(int seats) =>
      (pricePerUser - yearlyPerUser) * BillingCycle.yearly.months * seats;

  num limitOf(QuotaKind kind) => switch (kind) {
    QuotaKind.users => 1 << 20,
    QuotaKind.records => records,
    QuotaKind.storage => storageGb,
    QuotaKind.cardScans => cardScans,
    QuotaKind.smsCredits => 0,
  };

  factory PlanOffer.fromJson(Map<String, dynamic> json) => PlanOffer(
    code: json['key'] as String? ?? '',
    name: json['name'] as String? ?? '',
    rank: jsonInt(json['sortOrder']) ?? 0,
    pricePerUser: jsonDouble(json['monthlyPerUser'])?.round() ?? 0,
    yearlyPerUser: jsonDouble(json['yearlyPerUser'])?.round() ?? 0,
    minUsers: jsonInt(json['minUsers']) ?? 1,
    records: jsonInt(json['recordLimit']) ?? 0,
    cardScans: jsonInt(json['scanLimit']) ?? 0,
    storageGb: ((jsonDouble(json['storageLimitMb']) ?? 0) / 1024).round(),
    layers: jsonStrings(json['layers']),
  );
}

enum AddOnUnit {
  perUser('user_month'),
  monthly('month'),
  once('once');

  const AddOnUnit(this.wire);

  final String wire;

  static AddOnUnit fromWire(String? value) =>
      values.firstWhere((u) => u.wire == value, orElse: () => once);
}

/// An add-on billed per seat that opens a [layer], or a pack that raises a
/// [quota] by [amount].
class AddOnOffer {
  const AddOnOffer({
    required this.code,
    required this.name,
    required this.unit,
    required this.price,
    this.layer,
    this.quota,
    this.amount = 0,
  });

  final String code;
  final LocalizedName name;
  final AddOnUnit unit;
  final int price;
  final String? layer;
  final QuotaKind? quota;

  /// Gigabytes for storage, credits or scans otherwise.
  final int amount;

  bool get isPack => unit != AddOnUnit.perUser;

  /// What [seats] pay for one [cycle]; a pack's price doesn't depend on
  /// either.
  int priceFor(int seats, BillingCycle cycle) =>
      isPack ? price : price * seats * cycle.months;

  /// Whether [plan] already has what the add-on opens.
  bool includedIn(PlanOffer plan) {
    final layer = this.layer;
    return layer != null && plan.layers.contains(layer);
  }

  /// `grants` is a JSON string: `{"layer": "fieldforce"}`, `{"sms": 1000}`,
  /// `{"scans": 200}` or `{"storageMb": 10240}`.
  factory AddOnOffer.fromJson(Map<String, dynamic> json) {
    final grants = jsonMap(json['grants']);
    final (quota, amount) = switch (grants) {
      {'sms': final value} => (QuotaKind.smsCredits, jsonInt(value) ?? 0),
      {'scans': final value} => (QuotaKind.cardScans, jsonInt(value) ?? 0),
      {'storageMb': final value} => (
        QuotaKind.storage,
        ((jsonDouble(value) ?? 0) / 1024).round(),
      ),
      _ => (null, 0),
    };
    return AddOnOffer(
      code: json['key'] as String? ?? '',
      name: LocalizedName.pair(json),
      unit: AddOnUnit.fromWire(json['unit'] as String?),
      price: jsonDouble(json['price'])?.round() ?? 0,
      layer: grants['layer'] as String?,
      quota: quota,
      amount: amount,
    );
  }
}

class BillingCatalog {
  const BillingCatalog({required this.plans, required this.addOns});

  /// Cheapest first. Plans sold only on request (no price) are left out.
  final List<PlanOffer> plans;
  final List<AddOnOffer> addOns;

  PlanOffer? planOrNull(String? code) {
    for (final plan in plans) {
      if (plan.code == code) return plan;
    }
    return null;
  }

  PlanOffer plan(String code) =>
      planOrNull(code) ?? (throw ApiFailure(404, 'Unknown plan $code'));

  AddOnOffer? addOnOrNull(String? code) {
    for (final addOn in addOns) {
      if (addOn.code == code) return addOn;
    }
    return null;
  }

  /// The next plan up from [current], or null at the top.
  PlanOffer? nextAfter(PlanOffer current) {
    for (final plan in plans) {
      if (plan.rank > current.rank) return plan;
    }
    return null;
  }

  /// The cheapest plan that already has what [addOn] opens.
  PlanOffer? includingPlan(AddOnOffer addOn) {
    for (final plan in plans) {
      if (addOn.includedIn(plan)) return plan;
    }
    return null;
  }

  factory BillingCatalog.fromJson(Map<String, dynamic> json) => BillingCatalog(
    plans:
        jsonList(
            json['plans'],
            PlanOffer.fromJson,
          ).where((p) => p.isFree || p.pricePerUser > 0).toList()
          ..sort((a, b) => a.rank.compareTo(b.rank)),
    addOns: jsonList(json['addons'], AddOnOffer.fromJson),
  );
}

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum BillingCycle {
  monthly('Monthly', billedMonths: 1, months: 1),
  yearly('Yearly', billedMonths: 10, months: 12);

  const BillingCycle(
    this.wire, {
    required this.billedMonths,
    required this.months,
  });

  final String wire;

  /// Months charged per period; a year bills ten and gives two free.
  final int billedMonths;
  final int months;

  int get days => months * 30;

  static BillingCycle fromWire(String? value) =>
      value == yearly.wire ? yearly : monthly;
}

const Map<QuotaKind, String> _quotaWires = {
  QuotaKind.users: 'Users',
  QuotaKind.records: 'Records',
  QuotaKind.storage: 'Storage',
  QuotaKind.cardScans: 'CardScans',
  QuotaKind.smsCredits: 'SmsCredits',
};

QuotaKind? quotaFromWire(String? value) {
  for (final entry in _quotaWires.entries) {
    if (entry.value == value) return entry.key;
  }
  return null;
}

/// One line of what a plan adds over the plan below it.
class PlanFeature {
  const PlanFeature({required this.name, required this.detail});

  final LocalizedName name;
  final LocalizedName detail;

  factory PlanFeature.fromJson(Map<String, dynamic> json) => PlanFeature(
    name: LocalizedName.fromJson(json),
    detail: LocalizedName(
      json['Detail'] as String? ?? '',
      json['DetailBn'] as String? ?? '',
    ),
  );
}

class PlanOffer {
  const PlanOffer({
    required this.code,
    required this.name,
    required this.rank,
    required this.pricePerUser,
    required this.records,
    required this.cardScans,
    required this.storageGb,
    required this.summary,
    this.maxUsers,
    this.features = const [],
  });

  final String code;
  final String name;
  final int rank;
  final int pricePerUser;

  /// Null when any number of seats can be bought.
  final int? maxUsers;
  final int records;
  final int cardScans;
  final int storageGb;
  final LocalizedName summary;
  final List<PlanFeature> features;

  bool get isFree => pricePerUser == 0;

  bool get singleUser => maxUsers == 1;

  bool fits(int seats) {
    final max = maxUsers;
    return max == null || seats <= max;
  }

  num limitOf(QuotaKind kind) => switch (kind) {
    QuotaKind.users => maxUsers ?? 1 << 20,
    QuotaKind.records => records,
    QuotaKind.storage => storageGb,
    QuotaKind.cardScans => cardScans,
    QuotaKind.smsCredits => 0,
  };

  factory PlanOffer.fromJson(Map<String, dynamic> json) => PlanOffer(
    code: json['Code'] as String? ?? '',
    name: json['Name'] as String? ?? '',
    rank: jsonInt(json['Rank']) ?? 0,
    pricePerUser: jsonInt(json['PricePerUser']) ?? 0,
    maxUsers: jsonInt(json['MaxUsers']),
    records: jsonInt(json['Records']) ?? 0,
    cardScans: jsonInt(json['CardScans']) ?? 0,
    storageGb: jsonInt(json['StorageGb']) ?? 0,
    summary: LocalizedName(
      json['Summary'] as String? ?? '',
      json['SummaryBn'] as String? ?? '',
    ),
    features: jsonList(json['Features'], PlanFeature.fromJson),
  );
}

enum AddOnKind { recurring, pack }

/// A recurring add-on billed per seat, or a one-time pack that raises a quota.
class AddOnOffer {
  const AddOnOffer({
    required this.code,
    required this.name,
    required this.detail,
    required this.kind,
    required this.price,
    this.grants,
    this.quota,
    this.amount = 0,
    this.minPlan,
    this.includedIn,
    this.inStore = true,
    this.promptFor,
  });

  final String code;
  final LocalizedName name;
  final LocalizedName detail;
  final AddOnKind kind;
  final int price;

  /// The app module family the add-on unlocks.
  final AddOn? grants;

  /// The quota a pack raises, by [amount].
  final QuotaKind? quota;
  final int amount;
  final String? minPlan;
  final String? includedIn;
  final bool inStore;

  /// The limit this pack is offered for when it is hit.
  final QuotaKind? promptFor;

  bool get isPack => kind == AddOnKind.pack;

  factory AddOnOffer.fromJson(Map<String, dynamic> json) => AddOnOffer(
    code: json['Code'] as String? ?? '',
    name: LocalizedName.fromJson(json),
    detail: LocalizedName(
      json['Detail'] as String? ?? '',
      json['DetailBn'] as String? ?? '',
    ),
    kind: json['Kind'] == 'Pack' ? AddOnKind.pack : AddOnKind.recurring,
    price: jsonInt(json['Price']) ?? 0,
    grants: AddOn.fromWire(json['Grants'] as String?),
    quota: quotaFromWire(json['Quota'] as String?),
    amount: jsonInt(json['Amount']) ?? 0,
    minPlan: json['MinPlan'] as String?,
    includedIn: json['IncludedIn'] as String?,
    inStore: json['InStore'] as bool? ?? true,
    promptFor: quotaFromWire(json['PromptFor'] as String?),
  );
}

class BillingCatalog {
  const BillingCatalog({
    required this.plans,
    required this.addOns,
    required this.vatPercent,
  });

  final List<PlanOffer> plans;
  final List<AddOnOffer> addOns;
  final int vatPercent;

  PlanOffer? planOrNull(String? code) {
    for (final plan in plans) {
      if (plan.code == code) return plan;
    }
    return null;
  }

  PlanOffer plan(String code) =>
      planOrNull(code) ?? (throw ApiFailure(400, 'Unknown plan $code'));

  AddOnOffer? addOnOrNull(String? code) {
    for (final addOn in addOns) {
      if (addOn.code == code) return addOn;
    }
    return null;
  }

  AddOnOffer addOn(String code) =>
      addOnOrNull(code) ?? (throw ApiFailure(400, 'Unknown add-on $code'));

  /// The next plan up from [current], or null at the top.
  PlanOffer? nextAfter(PlanOffer current) {
    final higher = plans.where((p) => p.rank > current.rank).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return higher.isEmpty ? null : higher.first;
  }

  /// Whether [addOn] can be bought on [plan].
  bool available(AddOnOffer addOn, PlanOffer plan) {
    final min = planOrNull(addOn.minPlan);
    return min == null || plan.rank >= min.rank;
  }

  factory BillingCatalog.fromJson(Map<String, dynamic> json) {
    final plans = jsonList(json['Plans'], PlanOffer.fromJson)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return BillingCatalog(
      plans: plans,
      addOns: jsonList(json['AddOns'], AddOnOffer.fromJson),
      vatPercent: jsonInt(json['VatPercent']) ?? 0,
    );
  }
}

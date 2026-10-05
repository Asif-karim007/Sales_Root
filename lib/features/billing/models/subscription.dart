import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';

/// A gateway the server can charge through.
enum PaymentKind {
  bkash('bkash'),
  nagad('nagad'),
  card('card'),
  bank('bank');

  const PaymentKind(this.wire);

  final String wire;

  /// Paid in the app; a bank transfer is made on the web.
  bool get inApp => this != bank;
}

/// The workspace's plan as `GET billing` reports it: seats, the layers it
/// opens and the packs bought.
class Subscription {
  const Subscription({
    required this.planCode,
    required this.seats,
    required this.activeUsers,
    this.status,
    this.renewsAt,
    this.layers = const [],
    this.extraCardScans = 0,
    this.smsCredits = 0,
    this.extraStorageGb = 0,
  });

  final String planCode;
  final int seats;
  final int activeUsers;

  /// `active`, `trial`, `past_due`…
  final String? status;
  final DateTime? renewsAt;
  final List<String> layers;
  final int extraCardScans;
  final int smsCredits;
  final int extraStorageGb;

  bool get isTrial => status == 'trial';

  /// Whether the workspace has what [addOn] opens.
  bool hasAddOn(AddOnOffer addOn) {
    final layer = addOn.layer;
    return layer != null && layers.contains(layer);
  }

  /// The per-seat add-ons bought on top of the plan.
  Set<String> addOnsOver(BillingCatalog catalog) {
    final plan = catalog.planOrNull(planCode);
    return {
      for (final addOn in catalog.addOns)
        if (!addOn.isPack &&
            hasAddOn(addOn) &&
            (plan == null || !addOn.includedIn(plan)))
          addOn.code,
    };
  }

  /// `GET billing`: `{workspace: {plan, usersPurchased, layers, …},
  /// usage: {users, …}}`.
  factory Subscription.fromJson(Map<String, dynamic> json) {
    final workspace = jsonMap(json['workspace']);
    final usage = jsonMap(json['usage']);
    return Subscription(
      planCode: workspace['plan'] as String? ?? 'free',
      seats: jsonInt(workspace['usersPurchased']) ?? 1,
      activeUsers: jsonInt(usage['users']) ?? 1,
      status: workspace['planStatus'] as String?,
      renewsAt: jsonDate(workspace['billingDate']),
      layers: jsonStrings(workspace['layers']),
      extraCardScans: jsonInt(workspace['extraScans']) ?? 0,
      smsCredits: jsonInt(workspace['smsCredits']) ?? 0,
      extraStorageGb: ((jsonDouble(workspace['extraStorageMb']) ?? 0) / 1024)
          .round(),
    );
  }
}

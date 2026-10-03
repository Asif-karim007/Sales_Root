import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';

enum PaymentKind {
  bkash('Bkash'),
  nagad('Nagad'),
  card('Card'),
  bank('Bank');

  const PaymentKind(this.wire);

  final String wire;

  /// Paid in the app; a bank transfer is made on the web.
  bool get inApp => this != bank;

  static PaymentKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

class PaymentMethod {
  const PaymentMethod({required this.kind, this.account});

  final PaymentKind kind;

  /// Masked by the server, e.g. 01711••••67.
  final String? account;

  static PaymentMethod? fromJson(Map<String, dynamic> json) {
    final kind = PaymentKind.fromWire(json['Kind'] as String?);
    if (kind == null) return null;
    return PaymentMethod(kind: kind, account: json['Account'] as String?);
  }
}

/// The workspace's plan as billing sees it: seats, cycle, add-ons and the
/// one-time packs bought this period.
class Subscription {
  const Subscription({
    required this.planCode,
    required this.seats,
    required this.cycle,
    required this.activeUsers,
    this.renewsAt,
    this.unusedDays = 0,
    this.addOns = const {},
    this.grants = const {},
    this.extraCardScans = 0,
    this.extraSmsCredits = 0,
    this.extraStorageGb = 0,
    this.paymentMethod,
  });

  final String planCode;
  final int seats;
  final BillingCycle cycle;
  final int activeUsers;
  final DateTime? renewsAt;

  /// Days left in the paid period, counted by the server.
  final int unusedDays;

  /// Recurring add-on codes.
  final Set<String> addOns;

  /// The app add-ons those codes unlock.
  final Set<AddOn> grants;
  final int extraCardScans;
  final int extraSmsCredits;
  final int extraStorageGb;
  final PaymentMethod? paymentMethod;

  bool hasAddOn(String code) => addOns.contains(code);

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    planCode: json['PlanCode'] as String? ?? 'Free',
    seats: jsonInt(json['Seats']) ?? 1,
    cycle: BillingCycle.fromWire(json['Cycle'] as String?),
    activeUsers: jsonInt(json['ActiveUsers']) ?? 1,
    renewsAt: jsonDate(json['RenewsAt']),
    unusedDays: jsonInt(json['UnusedDays']) ?? 0,
    addOns: jsonStrings(json['AddOns']).toSet(),
    grants: {
      for (final wire in jsonStrings(json['Grants'])) ?AddOn.fromWire(wire),
    },
    extraCardScans: jsonInt(json['ExtraCardScans']) ?? 0,
    extraSmsCredits: jsonInt(json['ExtraSmsCredits']) ?? 0,
    extraStorageGb: jsonInt(json['ExtraStorageGb']) ?? 0,
    paymentMethod: jsonObject<PaymentMethod?>(
      json['PaymentMethod'],
      PaymentMethod.fromJson,
    ),
  );
}

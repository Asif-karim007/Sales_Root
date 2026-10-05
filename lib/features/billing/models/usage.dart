import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

/// One quota on the plan screen; [limit] is null for a balance like SMS
/// credits.
class UsageMeter {
  const UsageMeter({required this.kind, required this.used, this.limit});

  final QuotaKind kind;
  final num used;
  final num? limit;

  double get ratio {
    final limit = this.limit;
    if (limit == null || limit <= 0) return 0;
    return (used / limit).clamp(0, 1).toDouble();
  }

  bool get nearLimit => ratio >= 0.85;
}

/// Usage and limits from `GET billing`, as the access plan reads them; seats
/// are the ones bought.
List<UsageMeter> usageMeters(Plan usage, Subscription subscription) => [
  UsageMeter(
    kind: QuotaKind.users,
    used: usage.usersUsed,
    limit: subscription.seats,
  ),
  UsageMeter(
    kind: QuotaKind.records,
    used: usage.recordsUsed,
    limit: usage.records,
  ),
  UsageMeter(
    kind: QuotaKind.storage,
    used: usage.storageUsedGb,
    limit: usage.storageGb,
  ),
  UsageMeter(
    kind: QuotaKind.cardScans,
    used: usage.cardScansUsed,
    limit: usage.cardScans,
  ),
  UsageMeter(kind: QuotaKind.smsCredits, used: usage.smsCredits),
];

/// The two ways out of a hit quota (#98): a one-time pack (or more seats,
/// for users) and the next plan that raises the limit.
class LimitOffer {
  const LimitOffer({
    required this.kind,
    required this.limit,
    required this.current,
    this.pack,
    this.extraSeats = 0,
    this.upgrade,
  });

  static const int seatStep = 5;

  final QuotaKind kind;
  final num limit;
  final PlanOffer current;
  final AddOnOffer? pack;

  /// Seats offered on the current plan when the users quota is hit.
  final int extraSeats;
  final PlanOffer? upgrade;

  bool get hasQuickFix => pack != null || extraSeats > 0;

  /// The monthly price of [extraSeats], or the pack's one-time price.
  int get quickFixPrice {
    final pack = this.pack;
    if (pack != null) return pack.price;
    return current.pricePerUser * extraSeats;
  }

  CheckoutRequest? quickFix(Subscription subscription) {
    final pack = this.pack;
    if (pack != null) return CheckoutRequest(packs: [pack.code]);
    if (extraSeats > 0) {
      return CheckoutRequest(seats: subscription.seats + extraSeats);
    }
    return null;
  }

  factory LimitOffer.of(
    QuotaKind kind,
    BillingCatalog catalog,
    Subscription subscription,
  ) {
    final current = catalog.plan(subscription.planCode);
    final limit = switch (kind) {
      QuotaKind.users => subscription.seats,
      QuotaKind.records => current.records,
      QuotaKind.storage => current.storageGb + subscription.extraStorageGb,
      QuotaKind.cardScans => current.cardScans + subscription.extraCardScans,
      QuotaKind.smsCredits => subscription.smsCredits,
    };
    final pack = catalog.addOns
        .where((a) => a.isPack && a.quota == kind)
        .firstOrNull;
    final seatsFit = kind == QuotaKind.users && !current.isFree;
    return LimitOffer(
      kind: kind,
      limit: limit,
      current: current,
      pack: pack,
      extraSeats: seatsFit ? seatStep : 0,
      upgrade: _upgradeFor(kind, catalog, current),
    );
  }

  static PlanOffer? _upgradeFor(
    QuotaKind kind,
    BillingCatalog catalog,
    PlanOffer current,
  ) {
    if (kind == QuotaKind.smsCredits) return null;
    if (kind == QuotaKind.users) return catalog.nextAfter(current);
    for (final plan in catalog.plans) {
      if (plan.rank > current.rank &&
          plan.limitOf(kind) > current.limitOf(kind)) {
        return plan;
      }
    }
    return null;
  }
}

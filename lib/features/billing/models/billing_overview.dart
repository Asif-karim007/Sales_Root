import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/pricing.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/models/usage.dart';

/// The plan screen's data: the subscribed plan, its usage and add-ons.
class BillingOverview {
  const BillingOverview({
    required this.catalog,
    required this.subscription,
    required this.usage,
  });

  final BillingCatalog catalog;
  final Subscription subscription;

  /// The access plan: usage counters and the add-ons the app unlocks.
  final Plan usage;

  PlanOffer get plan => catalog.plan(subscription.planCode);

  PlanOffer? get nextPlan => catalog.nextAfter(plan);

  List<UsageMeter> get meters => usageMeters(usage, plan, subscription);

  int get renewal => BillingPricing.renewal(catalog, subscription);

  /// On when the app unlocks it, or when billing holds an add-on the app has
  /// no module for.
  bool isOn(AddOnOffer addOn) {
    final grants = addOn.grants;
    if (addOn.includedIn == plan.code) return true;
    return grants == null
        ? subscription.hasAddOn(addOn.code)
        : usage.has(grants);
  }
}

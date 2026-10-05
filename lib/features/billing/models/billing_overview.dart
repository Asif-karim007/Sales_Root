import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
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

  /// The access plan: usage counters and limits.
  final Plan usage;

  PlanOffer get plan => catalog.plan(subscription.planCode);

  PlanOffer? get nextPlan => catalog.nextAfter(plan);

  List<UsageMeter> get meters => usageMeters(usage, subscription);

  /// The per-seat add-ons bought on top of the plan.
  Set<String> get addOns => subscription.addOnsOver(catalog);

  /// On when the plan includes what it opens, or the workspace has it.
  bool isOn(AddOnOffer addOn) =>
      addOn.includedIn(plan) || subscription.hasAddOn(addOn);
}

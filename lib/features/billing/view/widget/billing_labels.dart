import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/models/usage.dart';
import 'package:salesroot/translations/translations.dart';

/// Joins the parts of a meta line the way the prototype does.
String joinDot(Iterable<String> parts) =>
    parts.where((p) => p.isNotEmpty).join(' · ');

extension BillingLabels on BuildContext {
  bool get isBangla => fmt.isBangla;

  String perCycleUnit(BillingCycle cycle) => switch (cycle) {
    BillingCycle.monthly => l10n.billingPerMonth,
    BillingCycle.yearly => l10n.billingPerYear,
  };

  String users(int count) => l10n.billingUsers(fmt.number(count));

  String quotaLabel(QuotaKind kind) => switch (kind) {
    QuotaKind.users => l10n.billingQuotaUsers,
    QuotaKind.records => l10n.billingQuotaRecords,
    QuotaKind.storage => l10n.billingQuotaStorage,
    QuotaKind.cardScans => l10n.billingQuotaCardScans,
    QuotaKind.smsCredits => l10n.billingQuotaSms,
  };

  String usageValue(UsageMeter meter) {
    final limit = meter.limit;
    final decimals = meter.kind == QuotaKind.storage ? 1 : 0;
    final used = fmt.number(meter.used, decimals: decimals);
    if (limit == null) return used;
    final value = l10n.billingUsedOf(used, fmt.number(limit));
    return meter.kind == QuotaKind.storage ? l10n.billingGb(value) : value;
  }

  String methodName(PaymentKind kind) => switch (kind) {
    PaymentKind.bkash => l10n.billingMethodBkash,
    PaymentKind.nagad => l10n.billingMethodNagad,
    PaymentKind.card => l10n.billingMethodCard,
    PaymentKind.bank => l10n.billingMethodBank,
  };

  /// A payment gateway by its server key; unknown ones show as sent.
  String gatewayName(String? gateway) => switch (gateway) {
    null => '',
    final key => switch (PaymentKind.values.asNameMap()[key]) {
      final PaymentKind kind => methodName(kind),
      null => key,
    },
  };

  /// What a plan layer opens, by its server key.
  String layerLabel(String layer) => switch (layer) {
    'sales' => l10n.billingLayerSales,
    'collection' => l10n.billingLayerCollection,
    'customer360' => l10n.billingLayerCustomer360,
    'fieldforce' => l10n.billingLayerFieldForce,
    'growth' => l10n.billingLayerGrowth,
    'teamops' => l10n.billingLayerTeamOps,
    'support' => l10n.billingLayerSupport,
    'intelligence' => l10n.billingLayerIntelligence,
    _ => layer,
  };

  String layerHint(String layer) => switch (layer) {
    'sales' => l10n.billingLayerSalesHint,
    'collection' => l10n.billingLayerCollectionHint,
    'customer360' => l10n.billingLayerCustomer360Hint,
    'fieldforce' => l10n.billingLayerFieldForceHint,
    'growth' => l10n.billingLayerGrowthHint,
    'teamops' => l10n.billingLayerTeamOpsHint,
    'support' => l10n.billingLayerSupportHint,
    'intelligence' => l10n.billingLayerIntelligenceHint,
    _ => '',
  };

  /// What an add-on's price is per: a seat a month, a month or once.
  String addOnUnit(AddOnOffer addOn) => switch (addOn.unit) {
    AddOnUnit.perUser => l10n.billingPerUserMonth,
    AddOnUnit.monthly => l10n.billingPerMonth,
    AddOnUnit.once => l10n.billingPerOnce,
  };

  /// What an add-on gives: the layer it opens or the quota it raises.
  String addOnNote(AddOnOffer addOn) {
    final layer = addOn.layer;
    if (layer != null) return layerHint(layer);
    final amount = fmt.number(addOn.amount);
    return switch (addOn.quota) {
      QuotaKind.smsCredits => l10n.billingGivesSms(amount),
      QuotaKind.storage => l10n.billingGivesStorage(amount),
      QuotaKind.cardScans => l10n.billingGivesScans(amount),
      _ => '',
    };
  }

  /// "Sales · Collection · Customer 360" for a plan.
  String layersLine(PlanOffer plan) => joinDot(plan.layers.map(layerLabel));

  /// "− ৳ 1,995" for credits.
  String signedMoney(int amount) =>
      amount < 0 ? l10n.billingMinus(fmt.money(-amount)) : fmt.money(amount);
}

IconData addOnIcon(AddOnOffer addOn) => switch ((addOn.layer, addOn.quota)) {
  ('fieldforce', _) => Icons.directions_walk_rounded,
  ('growth', _) => Icons.campaign_outlined,
  ('intelligence', _) => Icons.auto_awesome_outlined,
  (_, QuotaKind.smsCredits) => Icons.sms_outlined,
  (_, QuotaKind.storage) => Icons.cloud_outlined,
  _ => Icons.document_scanner_outlined,
};

IconData quotaIcon(QuotaKind kind) => switch (kind) {
  QuotaKind.users => Icons.group_outlined,
  QuotaKind.records => Icons.contacts_outlined,
  QuotaKind.storage => Icons.cloud_outlined,
  QuotaKind.cardScans => Icons.document_scanner_outlined,
  QuotaKind.smsCredits => Icons.sms_outlined,
};

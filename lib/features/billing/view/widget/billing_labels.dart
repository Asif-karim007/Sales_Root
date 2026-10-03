import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/models/usage.dart';
import 'package:salesroot/l10n/l10n.dart';

/// Joins the parts of a meta line the way the prototype does.
String joinDot(Iterable<String> parts) =>
    parts.where((p) => p.isNotEmpty).join(' · ');

extension BillingLabels on BuildContext {
  bool get isBangla => fmt.isBangla;

  String cycleLabel(BillingCycle cycle) => switch (cycle) {
    BillingCycle.monthly => l10n.billingCycleMonthly,
    BillingCycle.yearly => l10n.billingCycleYearly,
  };

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

  String methodLine(PaymentMethod method) =>
      joinDot([methodName(method.kind), fmt.digits(method.account ?? '')]);

  String orderLineLabel(OrderLine line) {
    final name = line.name.of(isBangla);
    return switch (line.kind) {
      OrderLineKind.plan => joinDot([
        name,
        users(line.seats),
        cycleLabel(line.cycle),
      ]),
      OrderLineKind.seats => l10n.billingLineSeats(
        name,
        fmt.number(line.seats),
        fmt.number(line.days),
      ),
      OrderLineKind.planCredit => l10n.billingLineCredit(
        fmt.number(line.days),
        name,
      ),
      OrderLineKind.addOn => l10n.billingLineAddOn(name),
      OrderLineKind.addOnProrated => l10n.billingLineAddOnProrated(
        name,
        fmt.number(line.seats),
        fmt.number(line.days),
      ),
      OrderLineKind.pack => name,
    };
  }

  /// "− ৳ 1,995" for credits.
  String signedMoney(int amount) =>
      amount < 0 ? l10n.billingMinus(fmt.money(-amount)) : fmt.money(amount);
}

IconData addOnIcon(String code) => switch (code) {
  'FieldForce' => Icons.directions_walk_rounded,
  'Growth' => Icons.campaign_outlined,
  'AiAssistant' => Icons.auto_awesome_outlined,
  'Sms1000' => Icons.sms_outlined,
  'Storage10' => Icons.cloud_outlined,
  _ => Icons.document_scanner_outlined,
};

IconData quotaIcon(QuotaKind kind) => switch (kind) {
  QuotaKind.users => Icons.group_outlined,
  QuotaKind.records => Icons.contacts_outlined,
  QuotaKind.storage => Icons.cloud_outlined,
  QuotaKind.cardScans => Icons.document_scanner_outlined,
  QuotaKind.smsCredits => Icons.sms_outlined,
};

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/usage.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/features/billing/view/widget/plan_option_card.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

String limitTitle(AppLocalizations l10n, QuotaKind kind) => switch (kind) {
  QuotaKind.users => l10n.billingLimitUsersTitle,
  QuotaKind.records => l10n.billingLimitRecordsTitle,
  QuotaKind.storage => l10n.billingLimitStorageTitle,
  QuotaKind.cardScans => l10n.billingLimitScansTitle,
  QuotaKind.smsCredits => l10n.billingLimitSmsTitle,
};

/// #98 The limit that was hit, with a one-time fix and the upgrade side by
/// side. Without [onSelect] the user cannot buy and is sent to the owner.
class LimitHeader extends StatelessWidget {
  const LimitHeader({
    super.key,
    required this.offer,
    required this.quickFixSelected,
    required this.onSelect,
    this.ownerName,
  });

  final LimitOffer offer;
  final bool quickFixSelected;

  /// Called with true for the quick fix, false for the upgrade.
  final ValueChanged<bool>? onSelect;
  final String? ownerName;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final onSelect = this.onSelect;

    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SrAvatar(icon: quotaIcon(offer.kind), tone: SrAvatarTone.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  limitTitle(l10n, offer.kind),
                  style: AppText.pageTitle(c.ink, size: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_message(context), style: AppText.lead(c.ink2)),
          const SizedBox(height: 12),
          if (onSelect == null)
            SrNote(
              tone: SrNoteTone.gold,
              message: ownerName == null
                  ? l10n.billingAskOwner
                  : l10n.billingAskOwnerNamed(ownerName ?? ''),
            )
          else
            _Options(
              offer: offer,
              quickFixSelected: quickFixSelected,
              onSelect: onSelect,
            ),
          Center(
            child: SrButton(
              label: l10n.billingNotNow,
              variant: SrButtonVariant.ghost,
              size: SrButtonSize.sm,
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  String _message(BuildContext context) {
    final l10n = context.l10n;
    final limit = context.fmt.number(offer.limit);
    return switch (offer.kind) {
      QuotaKind.users => l10n.billingLimitUsersBody(limit),
      QuotaKind.records => l10n.billingLimitRecordsBody(limit),
      QuotaKind.storage => l10n.billingLimitStorageBody(limit),
      QuotaKind.cardScans => l10n.billingLimitScansBody(limit),
      QuotaKind.smsCredits => l10n.billingLimitSmsBody,
    };
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.offer,
    required this.quickFixSelected,
    required this.onSelect,
  });

  final LimitOffer offer;
  final bool quickFixSelected;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final upgrade = offer.upgrade;
    final cards = [
      if (offer.hasQuickFix)
        PlanOptionCard(
          selected: quickFixSelected || upgrade == null,
          onTap: () => onSelect(true),
          child: _QuickFix(offer: offer),
        ),
      if (upgrade != null)
        PlanOptionCard(
          selected: !quickFixSelected || !offer.hasQuickFix,
          onTap: () => onSelect(false),
          child: _Upgrade(plan: upgrade, kind: offer.kind),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickFix extends StatelessWidget {
  const _QuickFix({required this.offer});

  final LimitOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pack = offer.pack;
    if (pack != null) {
      return OptionCardBody(
        title: pack.name.of(context.isBangla),
        price: PriceText(amount: pack.price, unit: l10n.billingPerOnce),
        note: pack.detail.of(context.isBangla),
      );
    }
    return OptionCardBody(
      title: l10n.billingMoreUsers(context.fmt.number(offer.extraSeats)),
      price: PriceText(amount: offer.quickFixPrice, unit: l10n.billingPerMonth),
      note: l10n.billingProratedToday,
    );
  }
}

class _Upgrade extends StatelessWidget {
  const _Upgrade({required this.plan, required this.kind});

  final PlanOffer plan;
  final QuotaKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final note = switch (kind) {
      QuotaKind.users =>
        plan.maxUsers == null
            ? l10n.billingGivesAnyUsers
            : l10n.billingGivesUsers(fmt.number(plan.maxUsers ?? 1)),
      QuotaKind.records => l10n.billingGivesRecords(fmt.number(plan.records)),
      QuotaKind.storage => l10n.billingGivesStorage(fmt.number(plan.storageGb)),
      QuotaKind.cardScans => l10n.billingGivesScans(fmt.number(plan.cardScans)),
      QuotaKind.smsCredits => plan.summary.of(context.isBangla),
    };
    return OptionCardBody(
      title: plan.name,
      price: PriceText(
        amount: plan.pricePerUser,
        unit: l10n.billingPerUserMonth,
      ),
      note: note,
    );
  }
}

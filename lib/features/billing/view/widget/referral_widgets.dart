import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The gold wallet card on the referral screens.
class WalletCard extends StatelessWidget {
  const WalletCard({super.key, required this.overview, this.onDetails});

  final ReferralOverview overview;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final meta = AppText.meta(c.ink2);

    return SrCard(
      tone: SrCardTone.gold,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SrSectionHeader(
            title: l10n.billingWalletBalance,
            actionLabel: onDetails == null ? null : l10n.billingDetails,
            onAction: onDetails,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                fmt.money(overview.balance),
                style: AppText.hero(c.ink, size: 30),
              ),
              if (overview.onHold > 0)
                SrTag(
                  l10n.billingOnHold(fmt.money(overview.onHold)),
                  tone: SrTone.warn,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(l10n.billingEarned(fmt.money(overview.earned)), style: meta),
              Text(
                l10n.billingFriendsJoined(fmt.number(overview.joined)),
                style: meta,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension ReferralLabels on BuildContext {
  String referralStatus(ReferralStatus status) => switch (status) {
    ReferralStatus.pending => l10n.billingReferPending,
    ReferralStatus.registered => l10n.billingReferRegistered,
    ReferralStatus.bought => l10n.billingReferBought,
    ReferralStatus.notEligible => l10n.billingReferNotEligible,
    ReferralStatus.expired => l10n.billingReferExpired,
    ReferralStatus.reversed => l10n.billingReferReversed,
  };

  String referralDetail(Referral referral) {
    final registered = referral.registeredAt;
    final bought = referral.boughtAt;
    final invited = referral.invitedAt;
    return switch (referral.status) {
      ReferralStatus.bought => joinDot([
        l10n.billingReferBought,
        if (bought != null) fmt.dayMonth(bought),
      ]),
      ReferralStatus.registered => joinDot([
        l10n.billingReferRegistered,
        if (registered != null) fmt.dayMonth(registered),
      ]),
      ReferralStatus.pending => joinDot([
        l10n.billingReferInvited,
        if (invited != null) fmt.dayMonth(invited),
      ]),
      ReferralStatus.notEligible => l10n.billingReferWasUser,
      ReferralStatus.expired => l10n.billingReferNoSignup,
      ReferralStatus.reversed => l10n.billingReferRefunded,
    };
  }
}

SrTone referralTone(ReferralStatus status) => switch (status) {
  ReferralStatus.bought => SrTone.ok,
  ReferralStatus.registered => SrTone.accent,
  ReferralStatus.pending => SrTone.neutral,
  ReferralStatus.notEligible => SrTone.warn,
  ReferralStatus.expired || ReferralStatus.reversed => SrTone.err,
};

class ReferralRow extends StatelessWidget {
  const ReferralRow({
    super.key,
    required this.referral,
    this.showStatus = true,
    this.divider = false,
  });

  final Referral referral;
  final bool showStatus;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final contact = fmt.digits(referral.contact);
    final name = referral.name ?? contact;

    return SrListRow(
      title: joinDot([?referral.name, contact]),
      subtitle: context.referralDetail(referral),
      leading: SrAvatar(
        name: name,
        tone: referral.status == ReferralStatus.bought
            ? SrAvatarTone.accent
            : SrAvatarTone.neutral,
      ),
      divider: divider,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showStatus)
            SrTag(
              context.referralStatus(referral.status),
              tone: referralTone(referral.status),
            ),
          if (referral.reward > 0) ...[
            if (showStatus) const SizedBox(height: 4),
            Text(
              context.l10n.billingPlus(fmt.money(referral.reward)),
              style: AppText.rowTitle(c.success, size: 13.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// A QR of [data], drawn from the `pdf` package's encoder so it needs no
/// platform raster step. Dark modules on a light tile in either theme.
class QrCodeView extends StatelessWidget {
  const QrCodeView({super.key, required this.data, this.size = 180});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.onDeep,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      ),
      child: Semantics(
        image: true,
        label: data,
        child: CustomPaint(
          size: Size.square(size),
          painter: _QrPainter(data: data, color: c.deep),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter({required this.data, required this.color});

  final String data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final elements = pw.Barcode.qrCode().make(
      data,
      width: size.width,
      height: size.height,
      drawText: false,
    );
    for (final element in elements) {
      if (element is pw.BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width + 0.4,
            element.height + 0.4,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.data != data || old.color != color;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Shows #190 once when a reward is waiting; [onShare] runs from its button.
void listenForReward(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onShare,
}) {
  ref.listen(pendingRewardProvider, (previous, next) {
    final moment = next.value;
    if (moment == null) return;
    ref.read(pendingRewardProvider.notifier).markSeen(moment.id);
    showSrSheet<void>(
      context: context,
      builder: (_) => RewardSheet(moment: moment, onShare: onShare),
    );
  });
}

/// #190 The reward moment: who joined, what was added, the next milestone.
class RewardSheet extends StatelessWidget {
  const RewardSheet({super.key, required this.moment, this.onShare});

  final RewardMoment moment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final overview = moment.overview;
    final next = overview.nextMilestone;
    final name = moment.name.of(context.isBangla);

    return SrSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: BigCheck(icon: Icons.celebration_rounded)),
            const SizedBox(height: 12),
            Text(
              l10n.billingRewardTitle(name),
              textAlign: TextAlign.center,
              style: AppText.pageTitle(c.ink, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              moment.holdHours > 0
                  ? l10n.billingRewardHeld(
                      fmt.money(moment.amount),
                      fmt.number(moment.holdHours),
                      fmt.number(overview.conversionPercent),
                    )
                  : l10n.billingRewardBody(
                      fmt.money(moment.amount),
                      fmt.number(overview.conversionPercent),
                    ),
              textAlign: TextAlign.center,
              style: AppText.lead(c.ink2),
            ),
            const SizedBox(height: 14),
            SrCard(
              tone: SrCardTone.gold,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.billingBalance,
                      style: AppText.label(c.ink2),
                    ),
                  ),
                  Text(
                    fmt.money(overview.balance + overview.onHold),
                    style: AppText.metric(c.ink, size: 22),
                  ),
                ],
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 10),
              _NextPrize(milestone: next, paid: overview.paid),
            ],
            const SizedBox(height: 16),
            SrButton(
              label: l10n.billingShareMore,
              icon: Icons.share_rounded,
              expand: true,
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                final share = onShare;
                if (share != null) {
                  share();
                } else {
                  router.push(Routes.refer);
                }
              },
            ),
            const SizedBox(height: 4),
            SrButton(
              label: l10n.billingLater,
              variant: SrButtonVariant.ghost,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far the user is from [milestone].
class _NextPrize extends StatelessWidget {
  const _NextPrize({required this.milestone, required this.paid});

  final Milestone milestone;
  final int paid;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nextPrizeLine(context, milestone, paid),
            style: AppText.rowTitle(c.ink, size: 13.5),
          ),
          const SizedBox(height: 8),
          SrProgressBar(value: paid / milestone.paid, color: c.gold),
        ],
      ),
    );
  }
}

/// "2 more paid friends unlock the ৳500 bonus".
String nextPrizeLine(BuildContext context, Milestone milestone, int paid) {
  final l10n = context.l10n;
  final fmt = context.fmt;
  final more = fmt.number(milestone.paid - paid);
  return milestone.reward > 0
      ? l10n.billingNextBonus(more, fmt.money(milestone.reward))
      : l10n.billingNextFreeMonth(more, fmt.number(milestone.freeMonths));
}

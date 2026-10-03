import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/models/referral.dart';
import 'package:salesroot/features/auth/providers/invite_providers.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #188's inviter banner. An unknown code shows nothing; the code field
/// reports it when the code is sent.
class ReferralBanner extends ConsumerWidget {
  const ReferralBanner({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(referralProvider(code))) {
      AsyncData(:final value) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: _Banner(referral: value),
      ),
      AsyncError() => const SizedBox.shrink(),
      _ => const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: SrSkeletonBox(height: 66, radius: SrMetrics.radiusCard),
      ),
    };
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.referral});

  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final name = referral.inviter.of(fmt.isBangla);

    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SrAvatar(name: name, tone: SrAvatarTone.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.authReferralInvitedYou(name),
                  style: AppText.rowTitle(c.ink, size: 14),
                ),
                Text(
                  l10n.authReferralReward(
                    referral.code,
                    fmt.money(referral.creditAmount),
                    fmt.number(referral.trialDays),
                  ),
                  style: AppText.meta(c.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.card_giftcard_rounded, size: 22, color: c.accent),
        ],
      ),
    );
  }
}

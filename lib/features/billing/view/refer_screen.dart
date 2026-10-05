import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/invite_sheet.dart';
import 'package:salesroot/features/billing/view/widget/referral_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #183 Refer & earn. [openInvite] opens #184 on arrival.
class ReferScreen extends ConsumerStatefulWidget {
  const ReferScreen({super.key, this.openInvite = false});

  final bool openInvite;

  @override
  ConsumerState<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends ConsumerState<ReferScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.openInvite) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showInviteSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.billingReferTitle,
        actions: [
          SrIconButton(
            icon: Icons.format_list_bulleted_rounded,
            tooltip: l10n.billingMyReferrals,
            onTap: () => context.push(Routes.referList),
          ),
          const BillingLanguageAction(),
        ],
      ),
      body: SrAsyncView(
        value: ref.watch(referralOverviewProvider),
        onRetry: () => ref.invalidate(referralOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 3, cards: true),
        data: (context, overview) => _ReferBody(overview: overview),
      ),
    );
  }
}

/// The invite message every share channel sends: the server's, or ours when
/// it sent none.
String referralShareText(BuildContext context, ReferralOverview overview) {
  final server = overview.shareText.of(context.fmt.isBangla);
  if (server.isNotEmpty) return server;
  return context.l10n.billingShareText(
    overview.code,
    context.fmt.money(overview.friendCredits),
    overview.link,
  );
}

class _ReferBody extends ConsumerWidget {
  const _ReferBody({required this.overview});

  final ReferralOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAdd = ref.watch(
      moduleAccessProvider(AppModule.referral).select((a) => a.canAdd),
    );
    final next = overview.nextPrize;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(referralOverviewProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          _CodeCard(overview: overview),
          const SizedBox(height: 12),
          _ShareTiles(overview: overview, canInvite: canAdd),
          if (canAdd) ...[
            const SizedBox(height: 12),
            SrButton(
              label: l10n.billingInviteByPhone,
              icon: Icons.person_add_alt_1_rounded,
              expand: true,
              onPressed: () => showInviteSheet(context),
            ),
          ],
          const SizedBox(height: 12),
          WalletCard(
            overview: overview,
            onDetails: () => context.push(Routes.referWallet),
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            _NextPrizeCard(prize: next),
          ],
          if (overview.recent.isNotEmpty) ...[
            const SizedBox(height: 12),
            SrRowGroup(
              title: l10n.billingRecent,
              seeAllLabel: l10n.commonSeeAll,
              onSeeAll: () => context.push(Routes.referList),
              rows: [
                for (final referral in overview.recent)
                  ReferralRow(referral: referral, showStatus: false),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.overview});

  final ReferralOverview overview;

  Future<void> _copy(BuildContext context, String text) async {
    final done = context.l10n.billingCopied;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) showSrSuccess(context, done);
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final link = overview.link.split('//').last;

    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard_rounded, color: c.accent, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.billingReferHeadline,
                  style: AppText.sectionTitle(c.ink, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.billingReferRules(
              fmt.money(overview.registerReward),
              fmt.number(overview.conversionPercent),
              fmt.money(overview.conversionCap),
            ),
            textAlign: TextAlign.center,
            style: AppText.lead(c.ink2, size: 13.5),
          ),
          const SizedBox(height: 12),
          SrCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.billingYourCode, style: AppText.label(c.ink2)),
                      Text(overview.code, style: AppText.hero(c.ink)),
                    ],
                  ),
                ),
                SrButton(
                  label: l10n.billingCopy,
                  icon: Icons.copy_rounded,
                  size: SrButtonSize.sm,
                  variant: SrButtonVariant.secondary,
                  onPressed: () => _copy(context, overview.code),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _copy(context, overview.link),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta(c.ink2, size: 12),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded, size: 14, color: c.ink2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTiles extends StatelessWidget {
  const _ShareTiles({required this.overview, required this.canInvite});

  final ReferralOverview overview;
  final bool canInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = referralShareText(context, overview);
    final tiles = [
      _Tile(
        icon: Icons.chat_rounded,
        label: l10n.billingWhatsApp,
        onTap: () => launchUrl(
          Uri.https('wa.me', '/', {'text': text}),
          mode: LaunchMode.externalApplication,
        ),
      ),
      if (canInvite)
        _Tile(
          icon: Icons.sms_outlined,
          label: l10n.billingSms,
          onTap: () => showInviteSheet(context),
        ),
      _Tile(
        icon: Icons.share_rounded,
        label: l10n.billingMessenger,
        onTap: () => SharePlus.instance.share(ShareParams(text: text)),
      ),
      _Tile(
        icon: Icons.qr_code_2_rounded,
        label: l10n.billingQr,
        onTap: () => context.push(Routes.referQr),
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        children: [
          SrAvatar(icon: icon, square: true, tone: SrAvatarTone.accent),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.chip(c.ink),
          ),
        ],
      ),
    );
  }
}

class _NextPrizeCard extends StatelessWidget {
  const _NextPrizeCard({required this.prize});

  final NextPrize prize;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(
            title: l10n.billingNextPrize,
            actionLabel: prize.referralsNeeded > 0
                ? l10n.billingMoreFriends(fmt.number(prize.referralsNeeded))
                : null,
          ),
          const SizedBox(height: 8),
          SrProgressBar(value: prize.progress, color: c.gold),
          const SizedBox(height: 8),
          Text(
            l10n.billingPrizeCredits(
              prize.name.of(fmt.isBangla),
              fmt.money(prize.missing),
            ),
            style: AppText.meta(c.ink2),
          ),
        ],
      ),
    );
  }
}

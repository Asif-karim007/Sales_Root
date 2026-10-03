import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';
import 'package:salesroot/features/growth/view/widget/campaign_text.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #143 Campaigns with the SMS and email balance.
class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.campaign)).canAdd;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthCampaignsTitle,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(campaignListProvider),
        onRetry: () => ref.invalidate(campaignListProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        data: (context, paged) => GrowthClock(
          every: const Duration(minutes: 1),
          builder: (context) => GrowthPagedList<Campaign>(
            paged: paged,
            title: l10n.growthCampaignsTitle,
            onLoadMore: () =>
                ref.read(campaignListProvider.notifier).loadMore(),
            onRefresh: () => ref.read(campaignListProvider.notifier).refresh(),
            header: [const _Balance(), if (canAdd) const _NewButtons()],
            empty: SrEmptyState(
              icon: Icons.campaign_outlined,
              title: l10n.growthCampaignsEmpty,
              message: l10n.growthCampaignsEmptyBody,
            ),
            row: (campaign) => _CampaignRow(campaign: campaign),
          ),
        ),
      ),
    );
  }
}

class _Balance extends ConsumerWidget {
  const _Balance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final canBuy = ref.watch(moduleAccessProvider(AppModule.campaign)).canAdd;
    return switch (ref.watch(messagingBalanceProvider)) {
      AsyncData(:final value) => SrStatGrid(
        columns: 2,
        tiles: [
          _BalanceTile(
            label: l10n.growthCampaignsSmsCredits,
            value: fmt.number(value.smsCredits),
            footer: canBuy
                ? GestureDetector(
                    onTap: () => context.push(Routes.campaignCredits),
                    child: Text(
                      l10n.growthCampaignsBuyMore,
                      style: AppText.label(c.accent, size: 12.5),
                    ),
                  )
                : null,
          ),
          _BalanceTile(
            label: l10n.growthCampaignsEmailMonth,
            value: l10n.growthCampaignOf(
              fmt.number(value.emailUsed),
              fmt.number(value.emailLimit),
            ),
            footer: SrProgressBar(
              value: value.emailLimit == 0
                  ? 0
                  : value.emailUsed / value.emailLimit,
            ),
          ),
        ],
      ),
      AsyncError(:final error) => SrErrorState(
        error: error,
        compact: true,
        onRetry: () => ref.invalidate(messagingBalanceProvider),
      ),
      _ => const SrSkeletonBox(height: 84, radius: 14),
    };
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.label, required this.value, this.footer});

  final String label;
  final String value;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final footer = this.footer;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label(c.ink2)),
          const SizedBox(height: 4),
          Text(value, style: AppText.metric(c.ink, size: 20)),
          if (footer != null) ...[const SizedBox(height: 6), footer],
        ],
      ),
    );
  }
}

class _NewButtons extends StatelessWidget {
  const _NewButtons();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: SrButton(
            label: l10n.growthCampaignsBulkSms,
            icon: Icons.sms_outlined,
            onPressed: () => context.push(Routes.campaignSms),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SrButton(
            label: l10n.growthCampaignsBulkEmail,
            icon: Icons.mail_outline_rounded,
            variant: SrButtonVariant.secondary,
            onPressed: () => context.push(Routes.campaignEmail),
          ),
        ),
      ],
    );
  }
}

class _CampaignRow extends StatelessWidget {
  const _CampaignRow({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheduled = campaign.status == CampaignStatus.scheduled;
    return SrListRow(
      leading: SrAvatar(
        icon: campaign.isSms ? Icons.sms_outlined : Icons.mail_outline_rounded,
        tone: scheduled
            ? SrAvatarTone.gold
            : campaign.isSms
            ? SrAvatarTone.accent
            : SrAvatarTone.neutral,
      ),
      title: l10n.growthCampaignTitleLine(
        campaign.name,
        campaignChannelLabel(l10n, campaign.channel),
      ),
      subtitle: campaignSummary(context, campaign),
      trailing: CampaignStatusTag(status: campaign.status),
      onTap: () => context.push(Routes.campaignFor(campaign.id)),
    );
  }
}

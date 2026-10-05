import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

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
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #146 How a campaign did: delivery, failures and replies.
class CampaignResultScreen extends ConsumerWidget {
  const CampaignResultScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final value = ref.watch(campaignProvider(id));
    final campaign = value.value;
    final when = campaign?.sentAt ?? campaign?.scheduledAt;
    return SrScaffold(
      appBar: SrAppBar(
        title: campaign?.name ?? l10n.growthCampaignsTitle,
        subtitle: campaign == null
            ? null
            : [
                campaignChannelLabel(l10n, campaign.channel),
                if (when != null) fmt.date(when),
              ].join(' · '),
        actions: [
          const GrowthLanguageAction(),
          if (campaign != null && campaign.status == CampaignStatus.done)
            SrIconButton(
              icon: Icons.share_outlined,
              tooltip: l10n.commonShare,
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      '${campaign.name}\n${campaignSummary(context, campaign)}',
                ),
              ),
            ),
        ],
      ),
      body: SrAsyncView(
        value: value,
        onRetry: () => ref.invalidate(campaignProvider(id)),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 4, cards: true),
        data: (context, campaign) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: switch (campaign.status) {
            CampaignStatus.scheduled => [
              _ScheduledCard(campaign: campaign),
              const SizedBox(height: 12),
              _MessageCard(campaign: campaign),
            ],
            CampaignStatus.cancelled => [
              SrNote(
                tone: SrNoteTone.neutral,
                icon: Icons.cancel_outlined,
                message: campaign.isSms
                    ? l10n.growthCampaignCancelledSms
                    : l10n.growthCampaignCancelledEmail,
              ),
              const SizedBox(height: 12),
              _MessageCard(campaign: campaign),
            ],
            _ => [
              _Kpis(campaign: campaign),
              const SizedBox(height: 16),
              _MessageCard(campaign: campaign),
            ],
          },
        ),
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final tiles = [
      (l10n.growthCampaignKpiSent, fmt.number(campaign.sent)),
      (
        l10n.growthCampaignKpiDelivered,
        fmt.percent(campaign.deliveredShare * 100),
      ),
      (l10n.growthCampaignKpiFailed, fmt.number(campaign.failed)),
      (l10n.growthCampaignKpiReplies, fmt.number(campaign.replies)),
    ];
    return SrStatGrid(
      columns: 2,
      tiles: [
        for (final (label, value) in tiles)
          SrKpiTile(label: label, value: value),
      ],
    );
  }
}

class _ScheduledCard extends ConsumerWidget {
  const _ScheduledCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final at = campaign.scheduledAt;
    final canCancel = ref
        .watch(moduleAccessProvider(AppModule.campaign))
        .canDelete;
    return SrNote(
      tone: SrNoteTone.gold,
      icon: Icons.schedule_rounded,
      title: at == null
          ? null
          : l10n.growthCampaignScheduledFor(fmt.dayTime(at)),
      message: campaignPeople(context, campaign),
      action: canCancel
          ? SrButton(
              label: l10n.growthCampaignCancel,
              size: SrButtonSize.sm,
              variant: SrButtonVariant.secondary,
              onPressed: () => _cancel(context, ref),
            )
          : null,
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.growthCampaignCancelTitle,
      message: campaign.isSms
          ? l10n.growthCampaignCancelSmsBody
          : l10n.growthCampaignCancelEmailBody,
      confirmLabel: l10n.growthCampaignCancel,
      icon: Icons.cancel_outlined,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final done = await runGrowthAction(
      context,
      ref.read(campaignActionsProvider.notifier).cancel(campaign.id),
    );
    if (done != null && context.mounted) {
      showSrInfo(context, l10n.growthCampaignCancelled);
    }
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final text = campaign.message ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return SrCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.isSms ? l10n.growthSmsMessage : l10n.growthEmailBody,
            style: AppText.fieldLabel(c.ink2),
          ),
          const SizedBox(height: 6),
          Text(text, style: AppText.body(c.ink, size: 14)),
        ],
      ),
    );
  }
}

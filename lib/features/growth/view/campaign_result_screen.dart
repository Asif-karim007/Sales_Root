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
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #146 How a campaign did: delivery, replies, leads and failures.
class CampaignResultScreen extends ConsumerWidget {
  const CampaignResultScreen({super.key, required this.id});

  final int id;

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
              if (campaign.repliesByHour.isNotEmpty) ...[
                const SizedBox(height: 12),
                _RepliesChart(campaign: campaign),
              ],
              const SizedBox(height: 16),
              _ReplyLeads(campaign: campaign),
              if (campaign.isSms && campaign.failed > 0) ...[
                const SizedBox(height: 16),
                _Failed(campaign: campaign),
              ],
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
    final tiles = campaign.isSms
        ? [
            (l10n.growthCampaignKpiSent, fmt.number(campaign.sent)),
            (
              l10n.growthCampaignKpiDelivered,
              fmt.percent(campaign.deliveredShare * 100),
            ),
            (l10n.growthCampaignKpiReplies, fmt.number(campaign.replies)),
            (l10n.growthCampaignKpiLeads, fmt.number(campaign.leadsCreated)),
          ]
        : [
            (l10n.growthCampaignKpiSent, fmt.number(campaign.sent)),
            (
              l10n.growthCampaignKpiOpened,
              fmt.percent(campaign.openedShare * 100),
            ),
            (l10n.growthCampaignKpiClicks, fmt.number(campaign.clicked)),
            (l10n.growthCampaignKpiLeads, fmt.number(campaign.leadsCreated)),
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

class _RepliesChart extends StatelessWidget {
  const _RepliesChart({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.isSms
                ? l10n.growthCampaignRepliesByHour
                : l10n.growthCampaignOpensByHour,
            style: AppText.rowTitle(c.ink, size: 14),
          ),
          const SizedBox(height: 10),
          SrColumnChart(
            height: 90,
            showValues: true,
            series: [
              for (var i = 0; i < campaign.repliesByHour.length; i++)
                SrSeries(
                  label: l10n.growthCampaignHour(fmt.number(i + 1)),
                  value: campaign.repliesByHour[i].toDouble(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyLeads extends StatefulWidget {
  const _ReplyLeads({required this.campaign});

  final Campaign campaign;

  @override
  State<_ReplyLeads> createState() => _ReplyLeadsState();
}

class _ReplyLeadsState extends State<_ReplyLeads> {
  static const _preview = 3;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final campaign = widget.campaign;
    final replies = campaign.replyLeads;
    final shown = _all ? replies : replies.take(_preview).toList();
    final title = l10n.growthCampaignLeadsFromReplies(
      fmt.number(campaign.leadsCreated),
    );
    if (replies.isEmpty) {
      return SrRowGroup(
        title: title,
        rows: [
          SrListRow(
            leading: const SrAvatar(icon: Icons.hourglass_empty_rounded),
            title: l10n.growthCampaignNoReplies,
            subtitle: l10n.growthCampaignNoRepliesBody,
          ),
        ],
      );
    }
    return SrRowGroup(
      title: title,
      seeAllLabel: _all ? l10n.growthCampaignShowLess : l10n.commonSeeAll,
      onSeeAll: replies.length > _preview
          ? () => setState(() => _all = !_all)
          : null,
      rows: [
        for (final reply in shown)
          SrListRow(
            leading: SrAvatar(name: reply.name),
            title: reply.name,
            subtitle: reply.createdTask
                ? l10n.growthCampaignReplyTask(reply.text)
                : l10n.growthCampaignReplyLead(reply.text),
            trailing: SrTag(l10n.growthMessagesLead, tone: SrTone.accent),
            chevron: reply.leadId != null,
            onTap: switch (reply.leadId) {
              final leadId? => () => context.push(Routes.leadFor(leadId)),
              null => null,
            },
          ),
      ],
    );
  }
}

class _Failed extends ConsumerWidget {
  const _Failed({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final canRetry =
        ref.watch(moduleAccessProvider(AppModule.campaign)).canAdd &&
        campaign.switchedOff > 0;
    return SrRowGroup(
      title: l10n.growthCampaignFailed(fmt.number(campaign.failed)),
      rows: [
        SrListRow(
          leading: const SrAvatar(
            icon: Icons.error_outline_rounded,
            tone: SrAvatarTone.danger,
          ),
          title: l10n.growthCampaignFailedSplit(
            fmt.number(campaign.wrongNumber),
            fmt.number(campaign.switchedOff),
          ),
          subtitle: canRetry
              ? l10n.growthCampaignTapRetry
              : l10n.growthCampaignWrongNumbersHint,
          chevron: canRetry,
          onTap: canRetry ? () => _retry(context, ref) : null,
        ),
      ],
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.growthCampaignRetryTitle,
      message: l10n.growthCampaignRetryBody(fmt.number(campaign.switchedOff)),
      confirmLabel: l10n.growthCampaignRetry,
      icon: Icons.replay_rounded,
    );
    if (!confirmed || !context.mounted) return;
    final updated = await runGrowthAction(
      context,
      ref.read(campaignActionsProvider.notifier).retry(campaign.id),
      onQuota: () => context.push(Routes.campaignCredits),
    );
    if (updated == null || !context.mounted) return;
    showSrSuccess(
      context,
      l10n.growthCampaignRetried(
        fmt.number(updated.delivered - campaign.delivered),
      ),
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
    final canCancel =
        ref.watch(moduleAccessProvider(AppModule.campaign)).canDelete &&
        campaign.canDelete;
    return SrNote(
      tone: SrNoteTone.gold,
      icon: Icons.schedule_rounded,
      title: at == null
          ? null
          : l10n.growthCampaignScheduledFor(fmt.dayTime(at)),
      message: l10n.growthCampaignPeople(
        fmt.number(campaign.recipients),
        campaign.segment.label(l10n),
      ),
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
    final text = campaign.message ?? campaign.subject ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return SrCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.isSms ? l10n.growthSmsMessage : l10n.growthEmailSubject,
            style: AppText.fieldLabel(c.ink2),
          ),
          const SizedBox(height: 6),
          Text(text, style: AppText.body(c.ink, size: 14)),
        ],
      ),
    );
  }
}

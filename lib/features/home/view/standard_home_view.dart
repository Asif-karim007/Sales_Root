import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/view/widget/agenda_card.dart';
import 'package:salesroot/features/home/view/widget/home_scroll_view.dart';
import 'package:salesroot/features/home/view/widget/pipeline_card.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #15: the Standard home — follow-ups, open deal value and target, the
/// pipeline by stage and quotations waiting for an answer.
class StandardHomeView extends ConsumerWidget {
  const StandardHomeView({super.key, required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final role = ref.watch(currentRoleProvider);
    final leads = ref.watch(moduleAccessProvider(AppModule.lead));
    final quotations = ref.watch(
      moduleAccessProvider(AppModule.quotation).select((a) => a.visible),
    );
    return HomeScrollView(
      children: [
        _StandardTiles(summary: summary),
        PipelineCard(
          stages: summary.pipeline,
          canOpen: leads.canView,
          scopeLabel: role == WorkspaceRole.member
              ? l10n.homePipelineMine
              : l10n.homePipelineAll,
        ),
        if (quotations) _AwaitingQuotations(items: summary.quotations),
        AgendaCard(items: summary.agenda),
      ],
    );
  }
}

class _StandardTiles extends ConsumerWidget {
  const _StandardTiles({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final tasks = ref.watch(
      moduleAccessProvider(AppModule.task).select((a) => a.canView),
    );
    final leads = ref.watch(
      moduleAccessProvider(AppModule.lead).select((a) => a.canView),
    );
    final reports = ref.watch(
      moduleAccessProvider(AppModule.reports).select((a) => a.visible),
    );
    final target = summary.targetPercent;
    final tiles = [
      SrKpiTile(
        label: l10n.homeFollowUpsDue,
        value: fmt.number(summary.followUpsDue),
        onTap: tasks ? () => context.go(Routes.tasks) : null,
      ),
      SrKpiTile(
        label: l10n.homeOpenDeals,
        value: fmt.moneyCompact(summary.openDealsValue),
        onTap: leads ? () => context.go(Routes.leads) : null,
      ),
      if (target != null)
        SrKpiTile(
          label: l10n.homeTarget,
          value: fmt.percent(target),
          onTap: reports ? () => context.push(Routes.reportSales) : null,
        ),
    ];
    return SrStatGrid(columns: tiles.length, tiles: tiles);
  }
}

class _AwaitingQuotations extends ConsumerWidget {
  const _AwaitingQuotations({required this.items});

  final List<AwaitingQuotation> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(title: l10n.homeQuotationsAwaiting),
          const SizedBox(height: 8),
          SrCard(
            child: SrEmptyState(
              icon: Icons.request_quote_outlined,
              title: l10n.homeQuotationsEmpty,
            ),
          ),
        ],
      );
    }
    return SrRowGroup(
      title: l10n.homeQuotationsAwaiting,
      seeAllLabel: l10n.commonAll,
      onSeeAll: () => context.push(Routes.quotations),
      rows: [for (final item in items) _QuotationRow(item: item)],
    );
  }
}

class _QuotationRow extends StatelessWidget {
  const _QuotationRow({required this.item});

  final AwaitingQuotation item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final sent = item.sentDaysAgo == 0
        ? l10n.homeQuotationSentToday
        : l10n.homeQuotationSentDaysAgo(fmt.number(item.sentDaysAgo));
    final leadId = item.leadId;
    return SrListRow(
      title: item.companyName,
      subtitle: '${fmt.moneyCompact(item.amount)} · $sent',
      leading: SrAvatar(name: item.companyName),
      trailing: item.needsFollowUp
          ? SrTag(l10n.homeTagFollowUp, tone: SrTone.warn)
          : SrTag(l10n.homeTagSent),
      chevron: true,
      onTap: () => context.push(
        leadId == null ? Routes.quotationFor(item.id) : Routes.leadFor(leadId),
      ),
    );
  }
}

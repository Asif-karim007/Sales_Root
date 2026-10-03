import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/models/report_models.dart';
import 'package:salesroot/features/settings/providers/report_providers.dart';
import 'package:salesroot/features/settings/view/widget/report_export.dart';
import 'package:salesroot/features/settings/view/widget/report_filters.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #94: outcomes and new leads for the period, and the detailed reports.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final overview = ref.watch(reportOverviewProvider);
    final canExport = ref.watch(
      moduleAccessProvider(AppModule.reports).select((a) => a.canExport),
    );
    final loaded = overview.value;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsReportsTitle,
        actions: [
          if (canExport && loaded != null)
            SrIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: l10n.settingsReportExport,
              onTap: () => _export(context, ref, loaded),
            ),
          const LanguageAction(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(reportOverviewProvider.future),
        child: ListView(
          padding: screenPadding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const ReportFilters(),
            const SizedBox(height: 14),
            AsyncSection(
              value: overview,
              onRetry: () => ref.invalidate(reportOverviewProvider),
              data: (context, data) => _Overview(overview: data),
            ),
            const SizedBox(height: 14),
            const _ReportLinks(),
          ],
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ReportOverview overview,
  ) async {
    final l10n = context.l10n;
    final query = ref.read(reportQueryProvider);
    try {
      await shareFile(
        'reports-${ReportQuery.dayString(query.from)}.csv',
        csvBytes(overviewRows(l10n, query, overview)),
        'text/csv',
      );
    } on Exception {
      if (!context.mounted) return;
      showSrError(context, l10n.settingsReportExportFailed);
    }
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.overview});

  final ReportOverview overview;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final outcomes = [
      SrSeries(
        label: l10n.settingsReportWon,
        value: overview.won.toDouble(),
        color: c.accent,
      ),
      SrSeries(
        label: l10n.settingsReportLost,
        value: overview.lost.toDouble(),
        color: c.danger,
      ),
      SrSeries(
        label: l10n.settingsReportOpen,
        value: overview.open.toDouble(),
        color: c.track,
      ),
    ];
    final weeks = overview.weeklyNewLeads;
    final trend = overview.weeklyTrend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrCard(
          child: Row(
            children: [
              SrDonut(
                series: outcomes,
                center: SrDonutCenter(
                  value: fmt.percent(overview.winRate * 100),
                  label: l10n.settingsReportWinRate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: SrLegend(series: outcomes)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsReportWeekly,
                      style: AppText.sectionTitle(c.ink),
                    ),
                  ),
                  if (trend != null)
                    Text(
                      trend >= 0
                          ? l10n.settingsReportTrendUp(fmt.percent(trend * 100))
                          : l10n.settingsReportTrendDown(
                              fmt.percent(-trend * 100),
                            ),
                      style: AppText.rowTitle(
                        trend >= 0 ? c.success : c.danger,
                        size: 13,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SrColumnChart(
                height: 70,
                showLabels: false,
                series: [
                  for (var i = 0; i < weeks.length; i++)
                    SrSeries(
                      label: '',
                      value: weeks[i].toDouble(),
                      dim: i < weeks.length - 3,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportLinks extends ConsumerWidget {
  const _ReportLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final collection = ref.watch(moduleAccessProvider(AppModule.collection));
    final activity = ref.watch(moduleAccessProvider(AppModule.teamAttendance));
    return SrRowGroup(
      rows: [
        SrListRow(
          title: l10n.settingsReportSalesTitle,
          subtitle: l10n.settingsReportSalesHint,
          leading: const RowIcon(
            Icons.trending_up_rounded,
            tone: SrAvatarTone.accent,
          ),
          chevron: true,
          onTap: () => context.push(Routes.reportSales),
        ),
        if (collection.visible)
          SrListRow(
            title: l10n.settingsReportCollection,
            subtitle: l10n.settingsReportCollectionHint,
            leading: const RowIcon(
              Icons.account_balance_wallet_outlined,
              tone: SrAvatarTone.gold,
            ),
            chevron: true,
            onTap: () => context.push(Routes.outstanding),
          ),
        SrListRow(
          title: l10n.settingsReportSources,
          subtitle: l10n.settingsReportSourcesHint,
          leading: const RowIcon(Icons.hub_outlined),
          chevron: true,
          onTap: () => showSrSheet<void>(
            context: context,
            builder: (_) => const _SourcesSheet(),
          ),
        ),
        if (activity.visible)
          SrListRow(
            title: l10n.settingsReportActivity,
            subtitle: l10n.settingsReportActivityHint,
            leading: const RowIcon(Icons.directions_walk_rounded),
            chevron: true,
            onTap: () => context.push(Routes.attendanceTeam),
          ),
      ],
    );
  }
}

class _SourcesSheet extends ConsumerWidget {
  const _SourcesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final overview = ref.watch(reportOverviewProvider);
    final query = ref.watch(reportQueryProvider);
    return SrSheet(
      title: l10n.settingsReportSources,
      subtitle: periodLabel(context, query),
      child: SingleChildScrollView(
        child: AsyncSection(
          value: overview,
          onRetry: () => ref.invalidate(reportOverviewProvider),
          data: (context, data) {
            if (data.sources.isEmpty) {
              return SrEmptyState(title: l10n.settingsReportNoLeads);
            }
            final max = data.sources.first.leads.toDouble();
            return Column(
              children: [
                for (final s in data.sources) ...[
                  SrBarRow(
                    label: s.source,
                    value: s.leads.toDouble(),
                    max: max,
                    valueWidth: 96,
                    valueLabel: l10n.settingsReportSourceLine(
                      fmt.number(s.leads),
                      fmt.percent(s.leads == 0 ? 0 : s.won * 100 / s.leads),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

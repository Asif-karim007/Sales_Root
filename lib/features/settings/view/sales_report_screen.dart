import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/models/report_models.dart';
import 'package:salesroot/features/settings/providers/report_providers.dart';
import 'package:salesroot/features/settings/view/widget/report_export.dart';
import 'package:salesroot/features/settings/view/widget/report_filters.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #95: sales for the period, by month, member and product, with export.
class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(reportQueryProvider);
    final report = ref.watch(salesReportProvider);
    final canExport = ref.watch(
      moduleAccessProvider(AppModule.reports).select((a) => a.canExport),
    );
    final loaded = report.value;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsReportSalesTitle,
        subtitle: periodLabel(context, query),
        actions: [
          if (canExport && loaded != null)
            SrIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: l10n.settingsReportExport,
              onTap: () => showSrSheet<void>(
                context: context,
                builder: (_) => _ExportSheet(query: query, report: loaded),
              ),
            ),
          const LanguageAction(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(salesReportProvider.future),
        child: ListView(
          padding: screenPadding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const ReportFilters(),
            const SizedBox(height: 14),
            AsyncSection(
              value: report,
              onRetry: () => ref.invalidate(salesReportProvider),
              skeletonRows: 5,
              data: (context, data) => _SalesBody(query: query, report: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesBody extends StatelessWidget {
  const _SalesBody({required this.query, required this.report});

  final ReportQuery query;
  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final growth = report.growth;
    final members = report.members.where((m) => m.wonValue > 0).toList();
    final maxMember = members.isEmpty ? 0 : members.first.wonValue;
    final maxCategory = report.categories.isEmpty
        ? 0
        : report.categories.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrStatGrid(
          columns: 2,
          tiles: [
            SrKpiTile(
              label: query.range == ReportRange.thisMonth
                  ? l10n.settingsReportSalesThisMonth
                  : l10n.settingsReportSalesTotal,
              value: fmt.moneyCompact(report.total),
              delta: growth == null
                  ? null
                  : l10n.settingsReportVsPrevious(
                      fmt.percent(growth.abs() * 100),
                    ),
              deltaUp: growth == null ? null : growth >= 0,
            ),
            SrKpiTile(
              label: l10n.settingsReportTarget,
              value: fmt.percent(report.targetShare * 100),
              delta: l10n.settingsReportOfTarget(
                fmt.moneyCompact(report.target),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SrSectionHeader(title: l10n.settingsReportByMonth),
              const SizedBox(height: 12),
              SrColumnChart(
                height: 80,
                series: [
                  for (var i = 0; i < report.months.length; i++)
                    SrSeries(
                      label: _month(fmt, report.months[i].month),
                      value: report.months[i].value.toDouble(),
                      dim: i < report.months.length - 1,
                    ),
                ],
              ),
            ],
          ),
        ),
        if (report.total == 0) ...[
          const SizedBox(height: 12),
          SrCard(
            child: SrEmptyState(
              icon: Icons.bar_chart_rounded,
              title: l10n.settingsReportNoSales,
              message: l10n.settingsReportNoSalesHint,
            ),
          ),
        ],
        if (members.isNotEmpty) ...[
          const SizedBox(height: 18),
          SrSectionHeader(title: l10n.settingsReportByMember),
          const SizedBox(height: 8),
          SrCard(
            child: Column(
              children: [
                for (final m in members.take(6)) ...[
                  SrBarRow(
                    label: m.name.of(fmt.isBangla).split(' ').first,
                    value: m.wonValue.toDouble(),
                    max: maxMember.toDouble(),
                    valueWidth: 76,
                    valueLabel: fmt.moneyCompact(m.wonValue),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
        if (report.categories.isNotEmpty) ...[
          const SizedBox(height: 18),
          SrSectionHeader(title: l10n.settingsReportByProduct),
          const SizedBox(height: 8),
          SrCard(
            child: Column(
              children: [
                for (final cat in report.categories) ...[
                  SrBarRow(
                    label: productCategoryLabel(l10n, cat.category),
                    value: cat.value.toDouble(),
                    max: maxCategory.toDouble(),
                    color: c.gold,
                    valueWidth: 76,
                    valueLabel: fmt.moneyCompact(cat.value),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
        if (report.members.isNotEmpty) ...[
          const SizedBox(height: 18),
          SrSectionHeader(title: l10n.settingsReportTable),
          const SizedBox(height: 8),
          _MemberTable(members: report.members),
        ],
      ],
    );
  }

  static String _month(AppFormat fmt, DateTime month) =>
      fmt.digits(DateFormat.MMM(fmt.locale.languageCode).format(month));
}

class _MemberTable extends StatelessWidget {
  const _MemberTable({required this.members});

  final List<MemberSales> members;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final head = AppText.label(c.ink2);
    final cell = AppText.meta(c.ink, size: 13);
    TableRow row(List<String> cells, TextStyle style, {bool line = true}) =>
        TableRow(
          decoration: line
              ? BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                )
              : null,
          children: [
            for (var i = 0; i < cells.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  cells[i],
                  style: style,
                  textAlign: i == 0 ? TextAlign.start : TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.4),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(1.6),
        },
        children: [
          row(
            [
              l10n.settingsReportMember,
              l10n.settingsReportLeads,
              l10n.settingsReportWon,
              l10n.settingsReportWonValue,
            ],
            head,
            line: false,
          ),
          for (final m in members)
            row([
              m.name.of(fmt.isBangla),
              fmt.number(m.leads),
              fmt.number(m.won),
              fmt.moneyCompact(m.wonValue),
            ], cell),
        ],
      ),
    );
  }
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.query, required this.report});

  final ReportQuery query;
  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.settingsReportExport,
      subtitle: periodLabel(context, query),
      child: SrRowGroup(
        rows: [
          SrListRow(
            title: l10n.settingsReportCsv,
            subtitle: l10n.settingsReportCsvHint,
            leading: const RowIcon(Icons.table_chart_outlined),
            onTap: () => _share(context, csv: true),
          ),
          SrListRow(
            title: l10n.settingsReportPdf,
            subtitle: l10n.settingsReportPdfHint,
            leading: const RowIcon(Icons.picture_as_pdf_outlined),
            onTap: () => _share(context, csv: false),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, {required bool csv}) async {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final navigator = Navigator.of(context);
    final name = 'sales-${ReportQuery.dayString(query.from)}';
    try {
      if (csv) {
        await shareFile(
          '$name.csv',
          csvBytes(salesReportRows(l10n, query, report, bangla)),
          'text/csv',
        );
      } else {
        final pdf = await showSrLoader(context, salesReportPdf(query, report));
        await shareFile('$name.pdf', pdf, 'application/pdf');
      }
      navigator.pop();
    } on Exception {
      if (!context.mounted) return;
      showSrError(context, l10n.settingsReportExportFailed);
    }
  }
}

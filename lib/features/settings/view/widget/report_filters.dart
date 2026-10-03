import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/settings/models/report_models.dart';
import 'package:salesroot/features/settings/providers/report_providers.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// `October 2026`, or `1 Sep – 15 Oct 2026` for other periods.
String periodLabel(BuildContext context, ReportQuery query) {
  final fmt = context.fmt;
  if (query.isMonth) return fmt.monthYear(query.from);
  return '${fmt.dayMonth(query.from)} – ${fmt.date(query.to)}';
}

/// Mine / Team (for leads and owners) and the period chips both report
/// screens share.
class ReportFilters extends ConsumerWidget {
  const ReportFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(reportQueryProvider);
    final team = ref.watch(canSeeTeamReportsProvider);
    final notifier = ref.read(reportQueryProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (team) ...[
          SrSegmented(
            segments: [
              SrSegment(l10n.settingsReportMine),
              SrSegment(l10n.settingsReportTeam),
            ],
            index: query.scope.index,
            onChanged: (i) => notifier.setScope(ReportScope.values[i]),
          ),
          const SizedBox(height: 12),
        ],
        SrChipRow(
          padding: EdgeInsets.zero,
          chips: [
            SrChipItem(l10n.settingsReportThisMonth),
            SrChipItem(l10n.settingsReportLastMonth),
            SrChipItem(l10n.settingsReportQuarter),
            SrChipItem(
              query.range == ReportRange.custom
                  ? periodLabel(context, query)
                  : l10n.settingsReportCustom,
            ),
          ],
          index: query.range.index,
          onChanged: (i) => i == ReportRange.custom.index
              ? _pickCustom(context, ref, query)
              : notifier.setRange(ReportRange.values[i]),
        ),
      ],
    );
  }

  Future<void> _pickCustom(
    BuildContext context,
    WidgetRef ref,
    ReportQuery query,
  ) async {
    final now = DateTime.now();
    final from = await showSrDatePicker(
      context: context,
      initial: query.from,
      last: now,
    );
    if (from == null || !context.mounted) return;
    final to = await showSrDatePicker(
      context: context,
      initial: query.to.isBefore(from) ? from : query.to,
      first: from,
    );
    if (to == null || !context.mounted) return;
    ref.read(reportQueryProvider.notifier).setCustom(from, to);
  }
}

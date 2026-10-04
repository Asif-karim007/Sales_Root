import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/service/csv_export.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #129 visitreport: planned against done per period and member, and the
/// far check-ins, with a CSV export.
class VisitReportScreen extends ConsumerWidget {
  const VisitReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final report = ref.watch(visitReportProvider);
    final canExport = ref.watch(
      moduleAccessProvider(AppModule.visit).select((a) => a.canExport),
    );
    final value = report.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffReportTitle,
        actions: [
          const FfLanguageToggle(),
          if (canExport)
            SrIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: l10n.ffExport,
              onTap: value == null ? null : () => _export(context, value),
            ),
        ],
      ),
      body: FieldForceGate(
        module: AppModule.visit,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(visitReportProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: SrScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              const _Filters(),
              const SizedBox(height: 12),
              switch (report) {
                AsyncValue(:final value?) => _ReportBody(report: value),
                AsyncError(:final error) => SrErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(visitReportProvider),
                ),
                _ => const SrSkeletonList(
                  count: 4,
                  cards: true,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, VisitReport report) {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final day = AppDateUtils.toApiDateOnly;
    return shareCsv(
      fileName: 'visit-report-${day(report.from)}-${day(report.to)}.csv',
      subject: l10n.ffReportTitle,
      rows: [
        [l10n.ffCsvMember, l10n.ffKpiPlanned, l10n.ffKpiDone, l10n.ffKpiFar],
        for (final m in report.byMember)
          [m.name.of(bangla), '${m.planned}', '${m.done}', '${m.far}'],
        [],
        [
          l10n.ffCsvMember,
          l10n.ffCsvCompany,
          l10n.ffCsvDate,
          l10n.ffCsvDistance,
          l10n.ffCsvReason,
        ],
        for (final f in report.farCheckIns)
          [
            f.memberName.of(bangla),
            f.company,
            if (f.date case final date?) day(date) else '',
            '${f.distance}',
            f.reason ?? '',
          ],
      ],
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final filter = ref.watch(visitReportFilterProvider);
    final notifier = ref.read(visitReportFilterProvider.notifier);
    final members = ref.watch(visitReportMembersProvider).value ?? const [];
    final member = members.where((m) => m.id == filter.memberId).firstOrNull;

    Future<void> pickMember() async {
      final everyone = ReportMember(
        id: 0,
        name: LocalizedName(l10n.ffEveryone, l10n.ffEveryone),
      );
      final picked = await showSrSheet<ReportMember>(
        context: context,
        builder: (_) => SrOptionSheet<ReportMember>(
          title: l10n.ffReportMember,
          options: [everyone, ...members],
          labelOf: (m) => m.name.of(bangla),
          isSelected: (m) => m.id == (filter.memberId ?? 0),
          withAvatar: true,
        ),
      );
      if (picked != null) notifier.setMember(picked.id == 0 ? null : picked.id);
    }

    final chips = [
      SrChip(
        label: l10n.ffThisWeek,
        selected: filter.period == ReportPeriod.week,
        onTap: () => notifier.setPeriod(ReportPeriod.week),
      ),
      SrChip(
        label: l10n.ffThisMonth,
        selected: filter.period == ReportPeriod.month,
        onTap: () => notifier.setPeriod(ReportPeriod.month),
      ),
      if (members.length > 1)
        SrChip(
          label: l10n.ffMemberChip(member?.name.of(bangla) ?? l10n.ffEveryone),
          icon: Icons.expand_more_rounded,
          selected: member != null,
          onTap: pickMember,
        ),
      SrChip(
        label: l10n.ffFarCheckIns,
        tone: SrTone.err,
        selected: filter.farOnly,
        onTap: notifier.toggleFar,
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            chips[i],
          ],
        ],
      ),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.report});

  final VisitReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final farOnly = ref.watch(
      visitReportFilterProvider.select((f) => f.farOnly),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrStatGrid(
          columns: 4,
          spacing: 8,
          tiles: [
            SrKpiTile(
              label: l10n.ffKpiPlanned,
              value: fmt.number(report.planned),
            ),
            SrKpiTile(label: l10n.ffKpiDone, value: fmt.number(report.done)),
            SrKpiTile(
              label: l10n.ffKpiMissed,
              value: fmt.number(report.missed),
            ),
            SrKpiTile(label: l10n.ffKpiFar, value: fmt.number(report.far)),
          ],
        ),
        if (report.planned == 0) ...[
          const SizedBox(height: 12),
          SrCard(
            child: SrEmptyState(
              icon: Icons.insights_outlined,
              title: l10n.ffReportEmptyTitle,
              message: l10n.ffReportEmptyBody,
            ),
          ),
        ],
        if (!farOnly && report.byMember.isNotEmpty) ...[
          const SizedBox(height: 16),
          SrSectionHeader(title: l10n.ffByMember),
          const SizedBox(height: 8),
          SrCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                for (final stat in report.byMember) _MemberBar(stat: stat),
              ],
            ),
          ),
        ],
        if (report.farCheckIns.isNotEmpty) ...[
          const SizedBox(height: 16),
          SrRowGroup(
            title: l10n.ffFarCheckIns,
            rows: [for (final far in report.farCheckIns) _FarRow(far: far)],
          ),
        ],
      ],
    );
  }
}

class _MemberBar extends StatelessWidget {
  const _MemberBar({required this.stat});

  final MemberVisitStat stat;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final name = stat.name.of(fmt.isBangla).split(' ').first;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              name,
              style: AppText.meta(c.ink2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: SrProgressBar(value: stat.ratio)),
          SizedBox(
            width: 60,
            child: Text(
              '${fmt.number(stat.done)}/${fmt.number(stat.planned)}',
              textAlign: TextAlign.end,
              style: AppText.rowTitle(c.ink, size: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarRow extends ConsumerWidget {
  const _FarRow({required this.far});

  final FarCheckIn far;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final name = far.memberName.of(fmt.isBangla);
    final reason = far.reason;
    final date = far.date;
    final canTrack = ref.watch(
      moduleAccessProvider(AppModule.liveTracking).select((a) => a.canView),
    );
    return SrListRow(
      leading: SrAvatar(name: name),
      title: l10n.ffFarRowTitle(name, far.company),
      subtitle: [
        if (date != null) fmt.weekdayDate(date),
        reason == null ? l10n.ffNoReason : l10n.ffReasonIs(reason),
      ].join(' · '),
      trailing: SrTag(context.ffDistance(far.distance), tone: SrTone.warn),
      chevron: true,
      onTap: () => context.push(
        canTrack
            ? Uri(
                path: Routes.trackingMemberFor(far.memberId),
                queryParameters: {
                  if (date != null) 'date': AppDateUtils.toApiDateOnly(date),
                },
              ).toString()
            : Routes.visitFor(far.visitId),
      ),
    );
  }
}

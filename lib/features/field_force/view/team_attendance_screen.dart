import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/service/csv_export.dart';
import 'package:salesroot/features/field_force/view/widget/attendance_calendar.dart';
import 'package:salesroot/features/field_force/view/widget/correction_sheet.dart';
import 'package:salesroot/features/field_force/view/widget/ff_count_tile.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #133 attendteam: the team's attendance today, this week or this month,
/// correction requests to approve, and the monthly report.
class TeamAttendanceScreen extends ConsumerStatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  ConsumerState<TeamAttendanceScreen> createState() =>
      _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends ConsumerState<TeamAttendanceScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final now = DateTime.now();
    setState(() => _exporting = true);
    try {
      final rows = await ref
          .read(attendanceRepositoryProvider)
          .teamMonth(DateTime(now.year, now.month));
      await shareCsv(
        fileName:
            'team-attendance-${AppDateUtils.toApiDateOnly(now).substring(0, 7)}.csv',
        subject: l10n.ffTeamTitle,
        rows: [
          [
            l10n.ffCsvMember,
            l10n.ffWorkingDays,
            l10n.ffPresent,
            l10n.ffLate,
            l10n.ffLeave,
            l10n.ffAbsent,
            l10n.ffCsvWorkedMinutes,
          ],
          for (final row in rows)
            if (row.summary case final s?)
              [
                row.name.of(bangla),
                '${s.workingDays}',
                '${s.present}',
                '${s.late}',
                '${s.leave}',
                '${s.absent}',
                '${s.workedMinutes}',
              ],
        ],
      );
    } on ApiFailure catch (failure) {
      if (mounted) showSrError(context, failure.message);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canExport = ref.watch(
      moduleAccessProvider(AppModule.teamAttendance).select((a) => a.canExport),
    );
    final team = ref.watch(teamAttendanceProvider);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffTeamTitle,
        actions: [
          const FfLanguageToggle(),
          if (canExport)
            SrIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: l10n.ffExport,
              onTap: _exporting ? null : _export,
            ),
        ],
      ),
      footer: canExport
          ? SrButton(
              label: l10n.ffDownloadMonthly,
              icon: Icons.download_rounded,
              variant: SrButtonVariant.secondary,
              expand: true,
              loading: _exporting,
              onPressed: _exporting ? null : _export,
            )
          : null,
      body: FieldForceGate(
        module: AppModule.teamAttendance,
        child: RefreshIndicator(
          onRefresh: () {
            ref.invalidate(teamAttendanceSummaryProvider);
            return ref.refresh(teamAttendanceProvider.future);
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (note) {
              if (note.metrics.extentAfter < 300) {
                ref.read(teamAttendanceProvider.notifier).loadMore();
              }
              return false;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: SrScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                const _SummaryRow(),
                const SizedBox(height: 12),
                const _PeriodChips(),
                const SizedBox(height: 12),
                switch (team) {
                  AsyncValue(:final value?) => _TeamList(rows: value),
                  AsyncError(:final error) => SrErrorState(
                    error: error,
                    onRetry: () => ref.invalidate(teamAttendanceProvider),
                  ),
                  _ => const SrSkeletonList(
                    count: 6,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                  ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final summary = ref.watch(teamAttendanceSummaryProvider).value;
    String count(int? n) => n == null ? '—' : fmt.number(n);
    return FfCountRow(
      tiles: [
        FfCountTile(
          value: count(summary?.present),
          label: l10n.ffPresent,
          color: c.success,
        ),
        FfCountTile(
          value: count(summary?.late),
          label: l10n.ffLate,
          color: c.gold,
        ),
        FfCountTile(
          value: count(summary?.leave),
          label: l10n.ffLeave,
          color: c.ink2,
        ),
        FfCountTile(
          value: count(summary?.absent),
          label: l10n.ffAbsent,
          color: c.danger,
        ),
      ],
    );
  }
}

class _PeriodChips extends ConsumerWidget {
  const _PeriodChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final filter = ref.watch(teamAttendanceFilterProvider);
    final notifier = ref.read(teamAttendanceFilterProvider.notifier);
    final corrections =
        ref.watch(teamAttendanceSummaryProvider).value?.corrections ?? 0;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (period, label) in [
          (TeamPeriod.today, l10n.ffToday),
          (TeamPeriod.week, l10n.ffThisWeek),
          (TeamPeriod.month, l10n.ffThisMonth),
        ])
          SrChip(
            label: label,
            selected: filter.period == period && !filter.correctionsOnly,
            onTap: () => notifier.setPeriod(period),
          ),
        if (corrections > 0 || filter.correctionsOnly)
          SrChip(
            label: l10n.ffCorrectionsChip(fmt.number(corrections)),
            tone: SrTone.err,
            selected: filter.correctionsOnly,
            onTap: notifier.toggleCorrections,
          ),
      ],
    );
  }
}

class _TeamList extends ConsumerWidget {
  const _TeamList({required this.rows});

  final Paged<TeamAttendanceRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final loadMoreError = rows.loadMoreError;
    if (rows.isEmpty) {
      return SrCard(
        child: SrEmptyState(
          icon: Icons.groups_outlined,
          title: l10n.ffTeamEmptyTitle,
          message: l10n.ffTeamEmptyBody,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrRowGroup(rows: [for (final row in rows.items) _TeamRow(row: row)]),
        if (rows.isLoadingMore) ...[
          const SizedBox(height: 12),
          const SrSkeletonRow(),
        ],
        if (loadMoreError != null)
          SrErrorState(
            error: loadMoreError,
            compact: true,
            onRetry: ref.read(teamAttendanceProvider.notifier).loadMore,
          ),
      ],
    );
  }
}

class _TeamRow extends ConsumerWidget {
  const _TeamRow({required this.row});

  final TeamAttendanceRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final name = row.name.of(fmt.isBangla);
    final canApprove = ref.watch(
      moduleAccessProvider(
        AppModule.teamAttendance,
      ).select((a) => a.canApprove),
    );
    final canTrack = ref.watch(
      moduleAccessProvider(AppModule.liveTracking).select((a) => a.canView),
    );
    final summary = row.summary;
    final checkInAt = row.checkInAt;

    final subtitle = summary != null
        ? l10n.ffTeamPeriodLine(
            fmt.number(summary.present),
            fmt.number(summary.workingDays),
            fmt.number(summary.late),
          )
        : row.needsCorrection
        ? l10n.ffTeamAskedCorrection
        : switch (row.status) {
            AttendanceStatus.late when checkInAt != null => l10n.ffTeamInLate(
              fmt.time(checkInAt),
              fmt.number(row.lateMinutes),
            ),
            AttendanceStatus.present || AttendanceStatus.late
                when checkInAt != null =>
              l10n.ffTeamIn(fmt.time(checkInAt), row.place ?? l10n.ffOffice),
            AttendanceStatus.leave => l10n.ffTeamOnLeave,
            AttendanceStatus.upcoming => l10n.ffTeamNotYet,
            _ => l10n.ffTeamNoCheckIn,
          };
    final (tag, tone) = row.needsCorrection
        ? (l10n.ffTeamCorrect, SrTone.err)
        : (
            attendanceLabel(l10n, row.status),
            switch (row.status) {
              AttendanceStatus.present => SrTone.ok,
              AttendanceStatus.late => SrTone.warn,
              AttendanceStatus.absent => SrTone.err,
              _ => SrTone.neutral,
            },
          );

    return SrListRow(
      leading: SrAvatar(name: name),
      title: name,
      subtitle: subtitle,
      trailing: SrTag(tag, tone: tone),
      onTap: row.needsCorrection && canApprove
          ? () => showCorrectionReviewSheet(context, row)
          : canTrack
          ? () => context.push(Routes.trackingMemberFor(row.memberId))
          : null,
    );
  }
}

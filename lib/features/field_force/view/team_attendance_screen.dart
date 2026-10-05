import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/service/csv_export.dart';
import 'package:salesroot/features/field_force/view/widget/attendance_calendar.dart';
import 'package:salesroot/features/field_force/view/widget/ff_count_tile.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #133 attendteam: the team's attendance today, this week or this month,
/// and the monthly report.
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
            l10n.ffPresent,
            l10n.ffLate,
            l10n.ffHalfDay,
            l10n.ffLeave,
            l10n.ffAbsent,
            l10n.ffCsvDistanceKm,
          ],
          for (final row in rows)
            [
              row.name,
              '${row.present}',
              '${row.late}',
              '${row.halfDays}',
              '${row.leave}',
              '${row.absent}',
              row.distanceKm.toStringAsFixed(1),
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
          onRefresh: () => ref.refresh(teamAttendanceProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: SrScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              _SummaryRow(summary: team.value?.summary),
              const SizedBox(height: 12),
              const _PeriodChips(),
              const SizedBox(height: 12),
              switch (team) {
                AsyncValue(:final value?) => _TeamList(rows: value.rows),
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final TeamAttendanceSummary? summary;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final summary = this.summary;
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
    final period = ref.watch(teamAttendancePeriodProvider);
    final notifier = ref.read(teamAttendancePeriodProvider.notifier);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (choice, label) in [
          (TeamPeriod.today, l10n.ffToday),
          (TeamPeriod.week, l10n.ffThisWeek),
          (TeamPeriod.month, l10n.ffThisMonth),
        ])
          SrChip(
            label: label,
            selected: period == choice,
            onTap: () => notifier.set(choice),
          ),
      ],
    );
  }
}

class _TeamList extends StatelessWidget {
  const _TeamList({required this.rows});

  final List<TeamAttendanceRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.isEmpty) {
      return SrCard(
        child: SrEmptyState(
          icon: Icons.groups_outlined,
          title: l10n.ffTeamEmptyTitle,
          message: l10n.ffTeamEmptyBody,
        ),
      );
    }
    return SrRowGroup(rows: [for (final row in rows) _TeamRow(row: row)]);
  }
}

class _TeamRow extends ConsumerWidget {
  const _TeamRow({required this.row});

  final TeamAttendanceRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
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
        : checkInAt != null
        ? l10n.ffTeamIn(fmt.time(checkInAt), placeLabel(l10n, row.inOffice))
        : switch (row.status) {
            AttendanceStatus.leave => l10n.ffTeamOnLeave,
            AttendanceStatus.upcoming => l10n.ffTeamNotYet,
            _ => l10n.ffTeamNoCheckIn,
          };
    final tone = switch (row.status) {
      AttendanceStatus.present => SrTone.ok,
      AttendanceStatus.late || AttendanceStatus.halfDay => SrTone.warn,
      AttendanceStatus.absent => SrTone.err,
      _ => SrTone.neutral,
    };

    return SrListRow(
      leading: SrAvatar(name: row.name),
      title: row.name,
      subtitle: subtitle,
      trailing: SrTag(attendanceLabel(l10n, row.status), tone: tone),
      onTap: canTrack
          ? () => context.push(Routes.trackingMemberFor(row.memberId))
          : null,
    );
  }
}

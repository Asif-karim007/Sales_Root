import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/service/csv_export.dart';
import 'package:salesroot/features/field_force/view/widget/attendance_calendar.dart';
import 'package:salesroot/features/field_force/view/widget/correction_sheet.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_info_line.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #132 attendcal: the month by day, its totals, and correction requests
/// for absent days.
class AttendanceCalendarScreen extends ConsumerWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(attendanceMonthProvider);
    final value = month.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffCalendarTitle,
        actions: [
          const FfLanguageToggle(),
          SrIconButton(
            icon: Icons.ios_share_rounded,
            tooltip: l10n.ffExport,
            onTap: value == null ? null : () => _export(context, value),
          ),
        ],
      ),
      body: FieldForceGate(
        module: AppModule.attendance,
        child: ListView(
          physics: const SrScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            const _MonthCard(),
            const SizedBox(height: 12),
            switch (month) {
              AsyncValue(:final value?) => _MonthReport(month: value),
              AsyncError(:final error) => SrErrorState(
                error: error,
                onRetry: () => ref.invalidate(attendanceMonthProvider),
              ),
              _ => const SrSkeletonList(
                count: 3,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
              ),
            },
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, AttendanceMonth month) {
    final l10n = context.l10n;
    final summary = month.summary;
    return shareCsv(
      fileName:
          'attendance-${AppDateUtils.toApiDateOnly(month.month).substring(0, 7)}.csv',
      subject: l10n.ffCalendarTitle,
      rows: [
        [l10n.ffCsvDate, l10n.ffCsvStatus],
        for (final day in month.days)
          [
            AppDateUtils.toApiDateOnly(day.date),
            attendanceLabel(l10n, day.status),
          ],
        [],
        [l10n.ffWorkingDays, '${summary.workingDays}'],
        [l10n.ffPresent, '${summary.present}'],
        [l10n.ffLate, '${summary.late}'],
        [l10n.ffLeaveApproved, '${summary.leave}'],
        [l10n.ffAbsent, '${summary.absent}'],
        [l10n.ffTotalWorked, '${summary.workedMinutes}'],
      ],
    );
  }
}

class _MonthCard extends ConsumerWidget {
  const _MonthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cursor = ref.watch(attendanceMonthCursorProvider);
    final notifier = ref.read(attendanceMonthCursorProvider.notifier);
    final days = ref.watch(attendanceMonthProvider).value?.days;

    return SrCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SrSectionHeader(title: context.fmt.monthYear(cursor)),
              ),
              SrIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: l10n.ffPreviousMonth,
                compact: true,
                onTap: notifier.previous,
              ),
              SrIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: l10n.ffNextMonth,
                compact: true,
                onTap: notifier.canGoNext ? notifier.next : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (days == null)
            const SrSkeletonBox(height: 220, radius: 10)
          else
            AttendanceMonthGrid(month: cursor, days: days),
          const SizedBox(height: 10),
          const AttendanceLegend(),
        ],
      ),
    );
  }
}

class _MonthReport extends StatelessWidget {
  const _MonthReport({required this.month});

  final AttendanceMonth month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final summary = month.summary;
    final absences = month.absences;
    final lines = [
      (l10n.ffWorkingDays, fmt.number(summary.workingDays)),
      (l10n.ffPresent, fmt.number(summary.present)),
      (l10n.ffLate, fmt.number(summary.late)),
      (l10n.ffLeaveApproved, fmt.number(summary.leave)),
      (l10n.ffAbsent, fmt.number(summary.absent)),
      (l10n.ffTotalWorked, context.ffDuration(summary.workedMinutes)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < lines.length; i++)
                FfInfoLine(
                  label: lines[i].$1,
                  value: lines[i].$2,
                  last: i == lines.length - 1,
                ),
            ],
          ),
        ),
        if (absences.isNotEmpty) ...[
          const SizedBox(height: 12),
          SrRowGroup(rows: [for (final day in absences) _AbsenceRow(day: day)]),
        ],
      ],
    );
  }
}

class _AbsenceRow extends StatelessWidget {
  const _AbsenceRow({required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final correction = day.correction;
    return SrListRow(
      leading: const SrAvatar(
        icon: Icons.event_busy_outlined,
        tone: SrAvatarTone.danger,
      ),
      title: l10n.ffAbsentOn(context.fmt.dayMonth(day.date)),
      subtitle: switch (correction) {
        CorrectionStatus.pending => l10n.ffCorrectionPending,
        CorrectionStatus.rejected => l10n.ffCorrectionWasRejected,
        CorrectionStatus.approved => l10n.ffCorrectionWasApproved,
        null => l10n.ffAskCorrection,
      },
      chevron: correction == null,
      onTap: correction == null
          ? () async {
              final sent = await showCorrectionRequestSheet(context, day.date);
              if (sent == true && context.mounted) {
                showSrSuccess(context, l10n.ffCorrectionSent);
              }
            }
          : null,
    );
  }
}

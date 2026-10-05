import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/translations/translations.dart';

/// The working week in Bangladesh order, as `DateTime.weekday` values.
const weekOrder = [6, 7, 1, 2, 3, 4, 5];

String weekdayShort(AppLocalizations l10n, int weekday) => switch (weekday) {
  DateTime.saturday => l10n.ffDaySat,
  DateTime.sunday => l10n.ffDaySun,
  DateTime.monday => l10n.ffDayMon,
  DateTime.tuesday => l10n.ffDayTue,
  DateTime.wednesday => l10n.ffDayWed,
  DateTime.thursday => l10n.ffDayThu,
  _ => l10n.ffDayFri,
};

/// Fill and ink for a day's status, as the prototype's calendar draws it.
(Color, Color) attendanceColors(SrColors c, AttendanceStatus status) =>
    switch (status) {
      AttendanceStatus.present => (c.successTint, c.success),
      AttendanceStatus.late ||
      AttendanceStatus.halfDay => (c.warningTint, c.warning),
      AttendanceStatus.absent => (c.dangerTint, c.danger),
      AttendanceStatus.leave => (c.avatarBg, c.ink2),
      AttendanceStatus.off ||
      AttendanceStatus.none ||
      AttendanceStatus.upcoming => (c.surface, c.ink3),
    };

String attendanceLabel(AppLocalizations l10n, AttendanceStatus status) =>
    switch (status) {
      AttendanceStatus.present => l10n.ffPresent,
      AttendanceStatus.late => l10n.ffLate,
      AttendanceStatus.halfDay => l10n.ffHalfDay,
      AttendanceStatus.leave => l10n.ffLeave,
      AttendanceStatus.absent => l10n.ffAbsent,
      AttendanceStatus.off => l10n.ffOff,
      AttendanceStatus.none => l10n.ffNoRecord,
      AttendanceStatus.upcoming => l10n.ffNotYet,
    };

/// Saturday to Friday, one tile per day with its status icon.
class AttendanceWeekStrip extends StatelessWidget {
  const AttendanceWeekStrip({super.key, required this.days});

  final List<AttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final now = DateTime.now();
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Column(
              children: [
                Text(
                  weekdayShort(l10n, day.date.weekday),
                  style: AppText.caption(c.ink3, size: 11),
                ),
                const SizedBox(height: 4),
                _DayTile(
                  day: day,
                  today: AppDateUtils.isSameDay(day.date, now),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.today});

  final AttendanceDay day;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final (fill, ink) = today
        ? (c.accent, c.onAccent)
        : attendanceColors(c, day.status);
    final icon = switch (day.status) {
      AttendanceStatus.present => Icons.check_rounded,
      AttendanceStatus.late ||
      AttendanceStatus.halfDay => Icons.schedule_rounded,
      AttendanceStatus.absent => Icons.close_rounded,
      AttendanceStatus.leave => Icons.beach_access_outlined,
      AttendanceStatus.off ||
      AttendanceStatus.none ||
      AttendanceStatus.upcoming => null,
    };
    final outlined = !today && icon == null;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outlined ? c.line : fill),
      ),
      child: icon == null ? null : Icon(icon, size: 16, color: ink),
    );
  }
}

/// A month in seven columns from Saturday, each day tinted by its status.
class AttendanceMonthGrid extends StatelessWidget {
  const AttendanceMonthGrid({
    super.key,
    required this.month,
    required this.days,
  });

  final DateTime month;
  final List<AttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final now = DateTime.now();
    final lead = weekOrder.indexOf(DateTime(month.year, month.month).weekday);
    final cells = <Widget>[
      for (final day in weekOrder)
        Center(
          child: Text(
            weekdayShort(l10n, day),
            style: AppText.caption(c.ink3, size: 11),
          ),
        ),
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (final day in days)
        _MonthCell(
          label: fmt.number(day.date.day),
          status: day.status,
          today: AppDateUtils.isSameDay(day.date, now),
        ),
    ];
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.1,
      children: cells,
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.status,
    required this.today,
  });

  final String label;
  final AttendanceStatus status;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final (fill, ink) = today
        ? (c.accent, c.onAccent)
        : attendanceColors(c, status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      ),
      child: Center(
        child: Text(
          label,
          style: today ? AppText.rowTitle(ink, size: 12.5) : AppText.meta(ink),
        ),
      ),
    );
  }
}

/// Present, late, absent and leave swatches under the calendar.
class AttendanceLegend extends StatelessWidget {
  const AttendanceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final status in [
          AttendanceStatus.present,
          AttendanceStatus.late,
          AttendanceStatus.absent,
          AttendanceStatus.leave,
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: attendanceColors(c, status).$1,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: attendanceColors(c, status).$2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                attendanceLabel(l10n, status),
                style: AppText.meta(c.ink2, size: 11.5),
              ),
            ],
          ),
      ],
    );
  }
}

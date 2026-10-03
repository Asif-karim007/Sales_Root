import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's `.calgrid`: a Saturday-first month with today filled,
/// the chosen day tinted, Fridays muted and a dot under busy days.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.isBusy,
    required this.onSelect,
    required this.onShift,
  });

  final DateTime month;
  final DateTime selected;
  final bool Function(DateTime day) isBusy;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset =
        (DateTime(month.year, month.month).weekday - DateTime.saturday) % 7;
    final today = AppDateUtils.dateOnly(DateTime.now());
    final weekdays = [
      l10n.tasksDowSat,
      l10n.tasksDowSun,
      l10n.tasksDowMon,
      l10n.tasksDowTue,
      l10n.tasksDowWed,
      l10n.tasksDowThu,
      l10n.tasksDowFri,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.fmt.monthYear(month),
                style: AppText.sectionTitle(c.ink),
              ),
            ),
            SrIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: l10n.tasksPrevMonth,
              compact: true,
              onTap: () => onShift(-1),
            ),
            SrIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: l10n.tasksNextMonth,
              compact: true,
              onTap: () => onShift(1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.15,
          children: [
            for (final weekday in weekdays)
              Center(
                child: Text(weekday, style: AppText.caption(c.ink3, size: 11)),
              ),
            for (var i = 0; i < offset; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              _DayCell(
                day: DateTime(month.year, month.month, d),
                today: today,
                selected: selected,
                busy: isBusy(DateTime(month.year, month.month, d)),
                onTap: onSelect,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final DateTime selected;
  final bool busy;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final isToday = AppDateUtils.isSameDay(day, today);
    final isSelected = AppDateUtils.isSameDay(day, selected);
    final ink = isToday
        ? c.onAccent
        : isSelected
        ? c.accent
        : day.weekday == DateTime.friday
        ? c.ink3
        : c.ink;
    return Semantics(
      button: true,
      selected: isSelected,
      label: context.fmt.weekdayDate(day),
      child: GestureDetector(
        onTap: () => onTap(day),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isToday
                ? c.accent
                : isSelected
                ? c.tint
                : Colors.transparent,
            borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
            border: isToday && isSelected
                ? Border.all(color: c.deep, width: 2)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                context.fmt.number(day.day),
                style: isToday || isSelected
                    ? AppText.rowTitle(ink, size: 13)
                    : AppText.meta(ink, size: 13),
              ),
              if (busy)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? c.onAccent : c.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

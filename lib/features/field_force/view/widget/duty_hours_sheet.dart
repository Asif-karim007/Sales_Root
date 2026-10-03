import 'package:flutter/material.dart';

import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

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

/// "Sat–Thu" for a run of days, or the days listed.
String workDaysLabel(BuildContext context, List<int> days) {
  final l10n = context.l10n;
  final ordered = [
    for (final day in weekOrder)
      if (days.contains(day)) day,
  ];
  if (ordered.isEmpty) return '—';
  final first = weekOrder.indexOf(ordered.first);
  final contiguous =
      ordered.length > 2 &&
      ordered.length == weekOrder.indexOf(ordered.last) - first + 1;
  if (contiguous) {
    return '${weekdayShort(l10n, ordered.first)}–'
        '${weekdayShort(l10n, ordered.last)}';
  }
  return ordered.map((d) => weekdayShort(l10n, d)).join(', ');
}

Future<TrackingSettings?> showDutyHoursSheet(
  BuildContext context,
  TrackingSettings settings,
) => showSrSheet<TrackingSettings>(
  context: context,
  builder: (_) => _DutyHoursSheet(settings: settings),
);

class _DutyHoursSheet extends StatefulWidget {
  const _DutyHoursSheet({required this.settings});

  final TrackingSettings settings;

  @override
  State<_DutyHoursSheet> createState() => _DutyHoursSheetState();
}

class _DutyHoursSheetState extends State<_DutyHoursSheet> {
  late String _start = widget.settings.dutyStart;
  late String _end = widget.settings.dutyEnd;
  late final Set<int> _days = {...widget.settings.workDays};

  static final _slots = [
    for (var m = 6 * 60; m <= 23 * 60 + 30; m += 30)
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}',
  ];

  Future<String?> _pickTime(String title, String current) =>
      showSrSheet<String>(
        context: context,
        builder: (_) => SrOptionSheet<String>(
          title: title,
          options: _slots,
          labelOf: context.ffWallClock,
          isSelected: (slot) => slot == current,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = _days.isNotEmpty && _start.compareTo(_end) < 0;

    return SrSheet(
      title: l10n.ffDutyHours,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SrDropdownField(
                    label: l10n.ffDutyStart,
                    value: context.ffWallClock(_start),
                    onTap: () async {
                      final picked = await _pickTime(l10n.ffDutyStart, _start);
                      if (picked != null) setState(() => _start = picked);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrDropdownField(
                    label: l10n.ffDutyEnd,
                    value: context.ffWallClock(_end),
                    error: _start.compareTo(_end) < 0
                        ? null
                        : l10n.ffDutyEndAfterStart,
                    onTap: () async {
                      final picked = await _pickTime(l10n.ffDutyEnd, _end);
                      if (picked != null) setState(() => _end = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SrFieldLabel(l10n.ffDutyDays),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final day in weekOrder)
                  SrChip(
                    label: weekdayShort(l10n, day),
                    selected: _days.contains(day),
                    onTap: () => setState(
                      () => _days.contains(day)
                          ? _days.remove(day)
                          : _days.add(day),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SrButton(
              label: l10n.commonDone,
              expand: true,
              onPressed: valid
                  ? () => Navigator.of(context).pop(
                      widget.settings.copyWith(
                        dutyStart: _start,
                        dutyEnd: _end,
                        workDays: [
                          for (final day in weekOrder)
                            if (_days.contains(day)) day,
                        ],
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

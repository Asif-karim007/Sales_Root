import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

/// Picks a day, and with [withTime] a time on it, in the Root skin.
Future<DateTime?> showSrDatePicker({
  required BuildContext context,
  required DateTime initial,
  bool withTime = false,
  DateTime? first,
  DateTime? last,
}) async {
  final theme = _pickerTheme(context);
  final day = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(2015),
    lastDate: last ?? DateTime(2101),
    builder: (_, child) => Theme(data: theme, child: child ?? const SizedBox()),
  );
  if (day == null || !withTime || !context.mounted) return day;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    builder: (_, child) => Theme(data: theme, child: child ?? const SizedBox()),
  );
  final picked = time ?? TimeOfDay.fromDateTime(initial);
  return DateTime(day.year, day.month, day.day, picked.hour, picked.minute);
}

ThemeData _pickerTheme(BuildContext context) {
  final c = SrColors.of(context);
  final theme = Theme.of(context);
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(SrMetrics.radiusSheet)),
  );

  return theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.surface,
      onSurface: c.ink,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.surface,
      headerBackgroundColor: c.deep,
      headerForegroundColor: c.onDeep,
      surfaceTintColor: Colors.transparent,
      todayBorder: BorderSide(color: c.accent),
      dayStyle: AppText.rowTitle(c.ink, size: 13),
      shape: shape,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: c.surface,
      dialBackgroundColor: c.tint,
      dialHandColor: c.accent,
      hourMinuteColor: c.tint,
      hourMinuteTextColor: c.ink,
      entryModeIconColor: c.ink2,
      shape: shape,
    ),
  );
}

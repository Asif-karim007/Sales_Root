import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

const reminderChoices = [10, 15, 30, 60, 120, 1440];

/// "30 minutes before", "1 hour before"…
String reminderLabel(BuildContext context, int minutes) {
  final l10n = context.l10n;
  final fmt = context.fmt;
  if (minutes == 1440) return l10n.tasksRemindDay;
  if (minutes == 60) return l10n.tasksRemindHour;
  if (minutes % 60 == 0) {
    return l10n.tasksRemindHours(fmt.number(minutes ~/ 60));
  }
  return l10n.tasksRemindMinutes(fmt.number(minutes));
}

Future<int?> pickReminder(BuildContext context, int? current) =>
    showSrSheet<int>(
      context: context,
      builder: (sheetContext) => SrOptionSheet<int>(
        title: context.l10n.tasksRemindTitle,
        options: reminderChoices,
        labelOf: (minutes) => reminderLabel(sheetContext, minutes),
        isSelected: (minutes) => minutes == current,
      ),
    );

import 'package:flutter/widgets.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/translations/translations.dart';

class TaskSection {
  const TaskSection(this.title, this.tasks);

  final String title;
  final List<Task> tasks;
}

/// Groups tasks, already in order, under Overdue, Today, Tomorrow, Yesterday
/// or their date.
List<TaskSection> taskSections(BuildContext context, List<Task> tasks) {
  final l10n = context.l10n;
  final fmt = context.fmt;
  final sections = <TaskSection>[];
  for (final task in tasks) {
    final due = task.dueDate;
    final title = switch (task.daysUntilDue) {
      _ when task.isOverdue => l10n.tasksSectionOverdue,
      0 => l10n.tasksSectionToday,
      1 => l10n.tasksSectionTomorrow,
      -1 => l10n.commonYesterday,
      _ => due == null ? '' : fmt.weekdayDate(due),
    };
    if (sections.isNotEmpty && sections.last.title == title) {
      sections.last.tasks.add(task);
    } else {
      sections.add(TaskSection(title, [task]));
    }
  }
  return sections;
}

import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/view/widget/task_type_style.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The lead when the title does not already name it, then "Quotation ·
/// ৳ 5.8 lakh", "৳ 50,000 · 2nd instalment" or the description.
String taskSubtitle(
  BuildContext context,
  Task task, {
  bool withAssignee = false,
}) {
  final l10n = context.l10n;
  final fmt = context.fmt;
  final amount = task.amount;
  final description = task.description;
  final type = task.type.label(l10n);
  final lead = task.lead?.name?.split(' — ').first;
  final parts = <String>[
    if (lead != null && !task.title.contains(lead)) lead,
    if (amount != null && task.type == TaskType.quotation) ...[
      type,
      fmt.moneyCompact(amount),
    ] else if (amount != null) ...[
      fmt.moneyCompact(amount),
      description ?? type,
    ] else
      description ?? type,
    if (withAssignee && !task.assignedToMe)
      ?task.assignedTo?.label(fmt.isBangla),
  ];
  return parts.join(' · ');
}

/// "Today 11:00", "Tomorrow 10:00", "Yesterday 15:00" or "2 Oct 11:00", from
/// the server's day count.
String taskDueText(BuildContext context, Task task) {
  final due = task.dueDate;
  if (due == null) return '';
  final l10n = context.l10n;
  final fmt = context.fmt;
  final day = switch (task.daysUntilDue) {
    0 => l10n.commonToday,
    1 => l10n.commonTomorrow,
    -1 => l10n.commonYesterday,
    _ => fmt.dayMonth(due),
  };
  return '$day ${fmt.time(due)}';
}

/// The time for a task due today or later, or how late an overdue one is.
String taskWhenLabel(BuildContext context, Task task, {bool timeOnly = false}) {
  final due = task.dueDate;
  final days = task.daysUntilDue ?? 0;
  if (task.isOverdue && !timeOnly) {
    return days == -1
        ? context.l10n.commonYesterday
        : context.l10n.tasksDaysLate(context.fmt.number(-days));
  }
  return due == null ? '' : context.fmt.time(due);
}

/// One task in a list: the done circle, the type icon, title and subtitle,
/// and the time. Swiping either way ticks it off or back on.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    this.withAssignee = false,
    this.timeOnly = false,
  });

  final Task task;
  final VoidCallback onTap;

  /// Null when the user may not change the task.
  final VoidCallback? onToggle;
  final bool withAssignee;

  /// Shows the due time even when the task is late, as the calendar does.
  final bool timeOnly;

  @override
  Widget build(BuildContext context) {
    final onToggle = this.onToggle;
    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SrMetrics.rowMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                _Leading(task: task, onToggle: onToggle),
                const SizedBox(width: 12),
                Expanded(
                  child: _Titles(task: task, withAssignee: withAssignee),
                ),
                const SizedBox(width: 12),
                _When(task: task, timeOnly: timeOnly),
              ],
            ),
          ),
        ),
      ),
    );
    if (onToggle == null) return row;
    return Dismissible(
      key: ValueKey('task-${task.id}'),
      confirmDismiss: (_) async {
        onToggle();
        return false;
      },
      background: _SwipeBackground(done: task.isDone, start: true),
      secondaryBackground: _SwipeBackground(done: task.isDone, start: false),
      child: row,
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.task, required this.onToggle});

  final Task task;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final done = task.isDone;
    final tone = switch (task) {
      Task(isOverdue: true) => SrAvatarTone.danger,
      Task(type: TaskType.collection) => SrAvatarTone.gold,
      Task(daysUntilDue: 0) => SrAvatarTone.accent,
      _ => SrAvatarTone.neutral,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          checked: done,
          label: done ? context.l10n.tasksReopen : context.l10n.tasksMarkDone,
          child: GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.accent : Colors.transparent,
                border: Border.all(color: done ? c.accent : c.ink3, width: 2),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: 16, color: c.onAccent)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SrAvatar(icon: task.type.icon, tone: tone),
      ],
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.task, required this.withAssignee});

  final Task task;
  final bool withAssignee;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final done = task.isDone;
    final title = AppText.rowTitle(done ? c.ink3 : c.ink);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: done
              ? title.copyWith(decoration: TextDecoration.lineThrough)
              : title,
        ),
        const SizedBox(height: 1),
        Text(
          taskSubtitle(context, task, withAssignee: withAssignee),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.meta(c.ink2),
        ),
      ],
    );
  }
}

class _When extends StatelessWidget {
  const _When({required this.task, required this.timeOnly});

  final Task task;
  final bool timeOnly;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SizedBox(
      width: 52,
      child: Text(
        taskWhenLabel(context, task, timeOnly: timeOnly),
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.rowTitle(task.isOverdue ? c.danger : c.ink, size: 13),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.done, required this.start});

  final bool done;
  final bool start;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return Container(
      color: done ? c.warningTint : c.tint,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: start ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.undo_rounded : Icons.check_circle_rounded,
            color: done ? c.warning : c.accent,
          ),
          const SizedBox(width: 8),
          Text(
            done ? l10n.tasksSwipeReopen : l10n.tasksSwipeDone,
            style: AppText.rowTitle(done ? c.warning : c.accent, size: 13),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/tasks/models/calendar_event.dart';
import 'package:salesroot/features/tasks/providers/calendar_providers.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/features/tasks/view/widget/month_grid.dart';
import 'package:salesroot/features/tasks/view/widget/task_feedback.dart';
import 'package:salesroot/features/tasks/view/widget/task_row.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Where the private-event form opens: new on [day], or editing [id].
String eventFormLocation({int? id, DateTime? day}) => Uri(
  path: Routes.calendarEventNew,
  queryParameters: {
    'id': ?id?.toString(),
    'date': ?(day == null ? null : AppDateUtils.toApiDateOnly(day)),
  },
).toString();

/// #37 `calendar`: the month, then the chosen day's (or week's) tasks and
/// private events.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cursor = ref.watch(calendarCursorProvider);
    final canAddTask = ref.watch(moduleAccessProvider(AppModule.task)).canAdd;
    final canAddEvent = ref
        .watch(moduleAccessProvider(AppModule.calendar))
        .canAdd;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.tasksCalendarTitle,
        actions: [
          const TasksLanguageToggle(),
          if (canAddTask || canAddEvent)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.tasksAddTitle,
              onTap: () => _add(
                context,
                cursor.selected,
                task: canAddTask,
                event: canAddEvent,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(calendarAgendaProvider);
          await ref.read(
            calendarAgendaProvider(cursor.month, cursor.monthEnd).future,
          );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            16,
            SrMetrics.gutter,
            32,
          ),
          children: [
            const _Month(),
            const SizedBox(height: 18),
            SrSectionHeader(
              title: cursor.week
                  ? l10n.tasksWeekRange(
                      context.fmt.dayMonth(cursor.weekStart),
                      context.fmt.dayMonth(
                        cursor.weekEnd.subtract(const Duration(days: 1)),
                      ),
                    )
                  : context.fmt.weekdayDate(cursor.selected),
              actionLabel: cursor.week ? l10n.tasksDay : l10n.tasksWeek,
              onAction: () => ref
                  .read(calendarCursorProvider.notifier)
                  .showWeek(!cursor.week),
            ),
            const SizedBox(height: 8),
            if (cursor.week) const _WeekAgenda() else const _DayAgenda(),
          ],
        ),
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    DateTime day, {
    required bool task,
    required bool event,
  }) async {
    final taskLocation = Uri(
      path: Routes.taskNew,
      queryParameters: {'date': AppDateUtils.toApiDateOnly(day)},
    ).toString();
    if (!event) {
      context.push(taskLocation);
      return;
    }
    if (!task) {
      context.push(eventFormLocation(day: day));
      return;
    }
    final location = await showSrSheet<String>(
      context: context,
      builder: (sheetContext) => _AddSheet(
        taskLocation: taskLocation,
        eventLocation: eventFormLocation(day: day),
      ),
    );
    if (location != null && context.mounted) context.push(location);
  }
}

class _AddSheet extends StatelessWidget {
  const _AddSheet({required this.taskLocation, required this.eventLocation});

  final String taskLocation;
  final String eventLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    return SrSheet(
      title: l10n.tasksAddTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SrListRow(
            title: l10n.tasksAddTask,
            subtitle: l10n.tasksAddTaskSub,
            leading: const SrAvatar(
              icon: Icons.task_alt_rounded,
              tone: SrAvatarTone.accent,
            ),
            chevron: true,
            onTap: () => navigator.pop(taskLocation),
          ),
          SrListRow(
            title: l10n.tasksAddEvent,
            subtitle: l10n.tasksAddEventSub,
            leading: const SrAvatar(
              icon: Icons.lock_outline_rounded,
              tone: SrAvatarTone.gold,
            ),
            chevron: true,
            onTap: () => navigator.pop(eventLocation),
          ),
        ],
      ),
    );
  }
}

class _Month extends ConsumerWidget {
  const _Month();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursor = ref.watch(calendarCursorProvider);
    final notifier = ref.read(calendarCursorProvider.notifier);
    final agenda = ref
        .watch(calendarAgendaProvider(cursor.month, cursor.monthEnd))
        .value;
    return SrCard(
      child: MonthGrid(
        month: cursor.month,
        selected: cursor.selected,
        isBusy: (day) => agenda?.hasItems(day) ?? false,
        onSelect: notifier.select,
        onShift: notifier.shiftMonth,
      ),
    );
  }
}

class _DayAgenda extends ConsumerWidget {
  const _DayAgenda();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursor = ref.watch(calendarCursorProvider);
    final provider = calendarAgendaProvider(cursor.month, cursor.monthEnd);
    return SrAsyncView<CalendarAgenda>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      loading: (_) => const SrSkeletonList(
        count: 3,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
      isEmpty: (agenda) => agenda.on(cursor.selected).isEmpty,
      empty: (_) => SrEmptyState(
        icon: Icons.event_available_outlined,
        title: context.l10n.tasksAgendaEmpty,
        message: context.l10n.tasksAgendaEmptyBody,
      ),
      data: (context, agenda) => _AgendaCard(items: agenda.on(cursor.selected)),
    );
  }
}

class _WeekAgenda extends ConsumerWidget {
  const _WeekAgenda();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursor = ref.watch(calendarCursorProvider);
    final provider = calendarAgendaProvider(cursor.weekStart, cursor.weekEnd);
    final start = cursor.weekStart;
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    return SrAsyncView<CalendarAgenda>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      loading: (_) => const SrSkeletonList(
        count: 4,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
      isEmpty: (agenda) => days.every((day) => agenda.on(day).isEmpty),
      empty: (_) => SrEmptyState(
        icon: Icons.event_available_outlined,
        title: context.l10n.tasksAgendaEmpty,
      ),
      data: (context, agenda) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final day in days)
            if (agenda.on(day).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Text(
                  context.fmt.weekdayDate(day),
                  style: AppText.label(SrColors.of(context).ink2),
                ),
              ),
              _AgendaCard(items: agenda.on(day)),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _AgendaCard extends ConsumerWidget {
  const _AgendaCard({required this.items});

  final List<AgendaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(moduleAccessProvider(AppModule.task)).canEdit;
    final editor = ref.read(taskEditorProvider.notifier);
    return SrRowGroup(
      dividerIndent: 64,
      rows: [
        for (final item in items)
          switch (item) {
            TaskAgendaItem(:final task) => TaskRow(
              task: task,
              timeOnly: true,
              onTap: () => context.push(Routes.taskFor(task.id)),
              onToggle: canEdit && task.canEdit
                  ? () => toggleTaskDone(
                      context,
                      task: task,
                      change: (done) => editor.setDone(task.id, done: done),
                    )
                  : null,
            ),
            EventAgendaItem(:final event) => _EventRow(event: event),
          },
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final location = event.location;
    return SrListRow(
      title: event.title,
      subtitle: [
        if (event.isPrivate) l10n.tasksPrivateSub else l10n.tasksAddEvent,
        ?location,
      ].join(' · '),
      onTap: () => context.push(eventFormLocation(id: event.id)),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.line, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          const SrAvatar(
            icon: Icons.lock_outline_rounded,
            tone: SrAvatarTone.gold,
          ),
        ],
      ),
      trailing: Text(
        event.allDay ? l10n.tasksAllDay : context.fmt.time(event.start),
        style: AppText.rowTitle(c.ink, size: 13),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/features/tasks/view/widget/task_feedback.dart';
import 'package:salesroot/features/tasks/view/widget/task_filter_sheet.dart';
import 'package:salesroot/features/tasks/view/widget/task_row.dart';
import 'package:salesroot/features/tasks/view/widget/task_sections.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #34 `tasks`: the task list with Today / Overdue / This week / All / Done.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SrScaffold(appBar: _Header(), body: _Body());
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final counts = ref.watch(taskCountsProvider).value;
    final bucket = ref.watch(taskBucketProvider);
    final narrowed = ref.watch(taskFilterProvider.select((f) => f.isNarrowed));
    final calendar = ref.watch(moduleAccessProvider(AppModule.calendar));
    final team = ref.watch(currentRoleProvider) != WorkspaceRole.member;

    return SrHeader(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tasksTitle,
                    style: AppText.pageTitle(c.ink, size: 22),
                  ),
                  if (counts != null)
                    Text(
                      l10n.tasksSubtitle(
                        fmt.number(counts.today),
                        fmt.number(counts.overdue),
                      ),
                      style: AppText.meta(c.ink2),
                    ),
                ],
              ),
            ),
            const TasksLanguageToggle(),
            if (calendar.visible) ...[
              const SizedBox(width: 6),
              SrIconButton(
                icon: Icons.calendar_month_outlined,
                tooltip: l10n.tasksOpenCalendar,
                onTap: () => context.push(Routes.calendar),
              ),
            ],
            if (team) ...[
              const SizedBox(width: 6),
              SrIconButton(
                icon: Icons.tune_rounded,
                tooltip: l10n.commonFilter,
                badge: narrowed,
                onTap: () => showTaskFilterSheet(context),
              ),
            ],
          ],
        ),
        SrChipRow(
          padding: EdgeInsets.zero,
          index: bucket.index,
          onChanged: (i) =>
              ref.read(taskBucketProvider.notifier).show(TaskBucket.values[i]),
          chips: [
            for (final b in TaskBucket.values)
              SrChipItem(
                _bucketLabel(l10n, b),
                count: counts?.of(b),
                tone: b == TaskBucket.overdue ? SrTone.err : SrTone.neutral,
              ),
          ],
        ),
      ],
    );
  }

  static String _bucketLabel(AppLocalizations l10n, TaskBucket bucket) =>
      switch (bucket) {
        TaskBucket.today => l10n.tasksTabToday,
        TaskBucket.overdue => l10n.tasksTabOverdue,
        TaskBucket.week => l10n.tasksTabWeek,
        TaskBucket.all => l10n.tasksTabAll,
        TaskBucket.done => l10n.tasksTabDone,
      };
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SrAsyncView<Paged<Task>>(
      value: ref.watch(taskListProvider),
      onRetry: () => ref.read(taskListProvider.notifier).refresh(),
      loading: (_) => const SrSkeletonList(count: 7),
      isEmpty: (paged) => paged.isEmpty,
      empty: (_) => const _Empty(),
      data: (context, paged) => _TaskList(paged: paged),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bucket = ref.watch(taskBucketProvider);
    final canAdd = ref.watch(moduleAccessProvider(AppModule.task)).canAdd;
    final (icon, title, message) = switch (bucket) {
      TaskBucket.today => (
        Icons.wb_sunny_outlined,
        l10n.tasksEmptyTodayTitle,
        l10n.tasksEmptyTodayBody,
      ),
      TaskBucket.overdue => (
        Icons.verified_outlined,
        l10n.tasksEmptyOverdueTitle,
        l10n.tasksEmptyOverdueBody,
      ),
      TaskBucket.week => (
        Icons.date_range_outlined,
        l10n.tasksEmptyWeekTitle,
        l10n.tasksEmptyBody,
      ),
      TaskBucket.all => (
        Icons.task_alt_rounded,
        l10n.tasksEmptyAllTitle,
        l10n.tasksEmptyBody,
      ),
      TaskBucket.done => (
        Icons.check_circle_outline_rounded,
        l10n.tasksEmptyDoneTitle,
        l10n.tasksEmptyBody,
      ),
    };
    return RefreshIndicator(
      onRefresh: () => ref.read(taskListProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SrEmptyState(
            icon: icon,
            title: title,
            message: message,
            actionLabel: canAdd ? l10n.tasksNewTask : null,
            onAction: () => context.push(Routes.taskNew),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.paged});

  final Paged<Task> paged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskListProvider.notifier);
    final canEdit = ref.watch(moduleAccessProvider(AppModule.task)).canEdit;
    final everyone = ref.watch(
      taskFilterProvider.select((f) => f.who != TaskWho.mine),
    );
    final sections = taskSections(context, paged.items);
    final loadMoreError = paged.loadMoreError;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) notifier.loadMore();
        return false;
      },
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            16,
            SrMetrics.gutter,
            32,
          ),
          children: [
            for (final section in sections) ...[
              SrRowGroup(
                title: section.title,
                dividerIndent: 64,
                rows: [
                  for (final task in section.tasks)
                    TaskRow(
                      task: task,
                      withAssignee: everyone,
                      onTap: () => context.push(Routes.taskFor(task.id)),
                      onToggle: canEdit && !task.isDone
                          ? () => completeTask(
                              context,
                              complete: () => notifier.complete(task),
                            )
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            if (paged.isLoadingMore)
              const SrSkeletonList(
                count: 2,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
              ),
            if (loadMoreError != null)
              SrErrorState(
                error: loadMoreError,
                compact: true,
                onRetry: notifier.loadMore,
              ),
          ],
        ),
      ),
    );
  }
}

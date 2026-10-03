import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_lookups.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/features/tasks/view/widget/task_feedback.dart';
import 'package:salesroot/features/tasks/view/widget/task_pickers.dart';
import 'package:salesroot/features/tasks/view/widget/task_row.dart';
import 'package:salesroot/features/tasks/view/widget/task_type_style.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The edit form under a task's own path.
String taskEditLocation(int id) => '${Routes.taskFor(id)}/edit';

/// #36 `taskdetail`: complete, reschedule, reassign, edit, delete, open lead.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(taskProvider(id));
    final access = ref.watch(moduleAccessProvider(AppModule.task));
    final task = value.value;
    final canChange = task != null && access.canEdit && task.canEdit;
    final canDelete = task != null && access.canDelete && task.canDelete;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.tasksDetailTitle,
        actions: [
          const TasksLanguageToggle(),
          if (task != null && (canChange || canDelete))
            SrIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: l10n.commonMore,
              onTap: () => _openMenu(
                context,
                ref,
                task: task,
                canEdit: canChange,
                canDelete: canDelete,
              ),
            ),
        ],
      ),
      footer: task == null || !canChange
          ? null
          : SrButton(
              label: task.isDone ? l10n.tasksReopen : l10n.tasksMarkDone,
              icon: task.isDone ? Icons.undo_rounded : Icons.check_rounded,
              variant: task.isDone
                  ? SrButtonVariant.secondary
                  : SrButtonVariant.primary,
              expand: true,
              onPressed: () => toggleTaskDone(
                context,
                task: task,
                change: (done) => ref
                    .read(taskEditorProvider.notifier)
                    .setDone(task.id, done: done),
              ),
            ),
      body: SrAsyncView<Task>(
        value: value,
        onRetry: () => ref.invalidate(taskProvider(id)),
        loading: (_) => const SrSkeletonList(count: 3, cards: true),
        data: (context, task) => _Detail(task: task, canChange: canChange),
      ),
    );
  }

  Future<void> _openMenu(
    BuildContext context,
    WidgetRef ref, {
    required Task task,
    required bool canEdit,
    required bool canDelete,
  }) async {
    final action = await showSrSheet<_MenuAction>(
      context: context,
      builder: (_) =>
          _TaskMenu(title: task.title, canEdit: canEdit, canDelete: canDelete),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _MenuAction.edit:
        context.push(taskEditLocation(task.id));
      case _MenuAction.delete:
        await _delete(context, ref, task);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Task task) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.tasksDeleteTitle,
      message: l10n.tasksDeleteBody,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.tasksDeleteKeep,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await showSrLoader(
        context,
        ref.read(taskEditorProvider.notifier).delete(task.id),
      );
    } on ApiFailure catch (failure) {
      if (context.mounted) showSrError(context, failureText(context, failure));
      return;
    }
    if (!context.mounted) return;
    showSrSuccess(context, l10n.tasksDeleted);
    context.pop();
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.task, required this.canChange});

  final Task task;
  final bool canChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final team = ref.watch(currentRoleProvider) != WorkspaceRole.member;
    final lead = task.lead;
    final notes = task.notes?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        _Summary(task: task),
        if (lead != null) ...[
          const SizedBox(height: 12),
          _LeadCard(task: task, lead: lead),
        ],
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          SrCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tasksNote, style: AppText.label(c.ink2)),
                const SizedBox(height: 4),
                Text(notes, style: AppText.body(c.ink, size: 14)),
              ],
            ),
          ),
        ],
        if (canChange && !task.isDone) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SrButton(
                  label: l10n.tasksReschedule,
                  icon: Icons.event_repeat_rounded,
                  variant: SrButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _reschedule(context, ref),
                ),
              ),
              if (team) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l10n.tasksReassign,
                    icon: Icons.swap_horiz_rounded,
                    variant: SrButtonVariant.secondary,
                    expand: true,
                    onPressed: () => _reassign(context, ref),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final due = task.dueDate ?? DateTime.now();
    final picked = await showSrDatePicker(
      context: context,
      initial: due,
      withTime: true,
    );
    if (picked == null || !context.mounted) return;
    final when =
        '${context.fmt.weekdayDate(picked)} ${context.fmt.time(picked)}';
    final message = context.l10n.tasksRescheduled(when);
    await _run(
      context,
      ref.read(taskEditorProvider.notifier).reschedule(task.id, picked),
      message,
    );
  }

  Future<void> _reassign(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final List<MemberOption> members;
    try {
      members = await showSrLoader(
        context,
        ref.read(taskMembersProvider.future),
      );
    } on ApiFailure catch (failure) {
      if (context.mounted) showSrError(context, failureText(context, failure));
      return;
    }
    if (!context.mounted) return;
    final picked = await pickMember(
      context,
      members,
      title: l10n.tasksReassign,
      currentId: task.assignedTo?.id,
    );
    if (picked == null || !context.mounted) return;
    await _run(
      context,
      ref.read(taskEditorProvider.notifier).reassign(task.id, picked.id),
      l10n.tasksReassigned(picked.name.of(context.fmt.isBangla)),
    );
  }

  static Future<void> _run(
    BuildContext context,
    Future<Task> work,
    String success,
  ) async {
    try {
      await showSrLoader(context, work);
      if (context.mounted) showSrSuccess(context, success);
    } on ApiFailure catch (failure) {
      if (context.mounted) showSrError(context, failureText(context, failure));
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final who = task.assignedToMe
        ? l10n.tasksMe
        : task.assignedTo?.label(fmt.isBangla);
    final creator = task.createdBy;
    final assignedBy = creator != null && creator.id != task.assignedTo?.id
        ? l10n.tasksAssignedBy(creator.label(fmt.isBangla))
        : null;
    final completed = task.completedOn;
    final meta = [
      taskDueText(context, task),
      task.type.label(l10n),
      ?who,
    ].where((part) => part.isNotEmpty).join(' · ');

    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SrAvatar(
            icon: task.type.icon,
            size: 44,
            tone: task.isOverdue ? SrAvatarTone.danger : SrAvatarTone.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppText.sectionTitle(c.ink, size: 17)),
                const SizedBox(height: 4),
                Text(meta, style: AppText.meta(c.ink2, size: 13)),
                Text(
                  taskSubtitle(context, task),
                  style: AppText.meta(c.ink2, size: 13),
                ),
                if (assignedBy != null)
                  Text(assignedBy, style: AppText.meta(c.ink3)),
                if (completed != null)
                  Text(
                    l10n.tasksCompletedOn(
                      '${fmt.dayMonth(completed)} ${fmt.time(completed)}',
                    ),
                    style: AppText.meta(c.accent),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (task.isDone)
                      SrTag(
                        l10n.tasksTagDone,
                        tone: SrTone.ok,
                        icon: Icons.check_rounded,
                      )
                    else if (task.isOverdue)
                      SrTag(l10n.tasksTagOverdue, tone: SrTone.err)
                    else if (task.daysUntilDue == 0)
                      SrTag(l10n.commonToday, tone: SrTone.accent),
                    if (task.lead != null) SrTag(l10n.tasksTagLead),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends ConsumerWidget {
  const _LeadCard({required this.task, required this.lead});

  final Task task;
  final TaskLeadRef lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final leads = ref.watch(moduleAccessProvider(AppModule.lead));
    final id = lead.id;
    final name = lead.name ?? '';
    final phone = lead.contactPhone;
    final subtitle = [
      ?lead.stage?.of(fmt.isBangla),
      ?lead.contactName,
      if (phone != null) fmt.phone(phone),
    ].join(' · ');
    final logCall =
        id != null &&
        leads.canAdd &&
        task.type == TaskType.call &&
        !task.isDone;

    return SrCard(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SrListRow(
        title: name,
        subtitle: subtitle,
        leading: SrAvatar(name: name),
        chevron: id != null && leads.canView,
        trailing: logCall
            ? SrIconButton(
                icon: Icons.phone_callback_outlined,
                tooltip: l10n.tasksLogCall,
                compact: true,
                onTap: () =>
                    context.push('${Routes.leadActivityFor(id)}?type=call'),
              )
            : null,
        onTap: id == null || !leads.canView
            ? null
            : () => context.push(Routes.leadFor(id)),
      ),
    );
  }
}

enum _MenuAction { edit, delete }

class _TaskMenu extends StatelessWidget {
  const _TaskMenu({
    required this.title,
    required this.canEdit,
    required this.canDelete,
  });

  final String title;
  final bool canEdit;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final navigator = Navigator.of(context);
    return SrSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canEdit)
            SrListRow(
              title: l10n.commonEdit,
              leading: Icon(Icons.edit_outlined, color: c.ink2),
              onTap: () => navigator.pop(_MenuAction.edit),
            ),
          if (canDelete)
            SrListRow(
              title: l10n.commonDelete,
              leading: Icon(Icons.delete_outline_rounded, color: c.danger),
              onTap: () => navigator.pop(_MenuAction.delete),
            ),
        ],
      ),
    );
  }
}

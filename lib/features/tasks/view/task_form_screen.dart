import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_draft.dart';
import 'package:salesroot/features/tasks/models/task_lookups.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';
import 'package:salesroot/features/tasks/view/widget/dictation_button.dart';
import 'package:salesroot/features/tasks/view/widget/reminder_options.dart';
import 'package:salesroot/features/tasks/view/widget/task_feedback.dart';
import 'package:salesroot/features/tasks/view/widget/task_pickers.dart';
import 'package:salesroot/features/tasks/view/widget/task_type_style.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/features/tasks/view/widget/toggle_row.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #35 `newtask`, also the edit form when [taskId] is set. Accepts
/// `?leadId=&title=&date=` to start linked to a lead or on a day.
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({
    super.key,
    this.taskId,
    this.leadId,
    this.title,
    this.day,
  });

  final int? taskId;
  final int? leadId;
  final String? title;
  final DateTime? day;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _seeded = false;
  String _suggested = '';
  bool _listening = false;

  TaskFormNotifierProvider get _provider => taskFormProvider(
    taskId: widget.taskId,
    leadId: widget.leadId,
    title: widget.title,
    day: widget.day,
  );

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seed(TaskDraft draft) {
    if (_seeded) return;
    _seeded = true;
    _notes.text = draft.notes;
    if (draft.title.isNotEmpty) {
      _title.text = draft.title;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _suggest(draft));
  }

  /// Fills the title from the type and lead until the user writes their own.
  void _suggest(TaskDraft draft) {
    if (!mounted) return;
    final lead = draft.lead;
    final current = _title.text.trim();
    if (lead == null || (current.isNotEmpty && current != _suggested)) return;
    final suggestion = draft.type.suggestedTitle(context.l10n, lead.shortName);
    if (suggestion == null) return;
    _suggested = suggestion;
    _title.text = suggestion;
    ref.read(_provider.notifier).setTitle(suggestion);
  }

  void _onSaved(TaskDraft? previous, TaskDraft next) {
    final saved = next.saved;
    if (saved == null || previous?.saved != null) return;
    showSrSuccess(
      context,
      next.isEdit ? context.l10n.tasksSaved : context.l10n.tasksCreated,
    );
    context.pop(saved);
  }

  void _onFailure(TaskDraft? previous, TaskDraft next) {
    final failure = next.failure;
    if (failure == null || identical(failure, previous?.failure)) return;
    if (failure.isValidation && failure.fieldErrors.isNotEmpty) return;
    showSrError(context, failureText(context, failure));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = ref.watch(_provider);
    ref.listen(_provider, (previous, next) {
      final draft = next.value;
      if (draft == null) return;
      _onSaved(previous?.value, draft);
      _onFailure(previous?.value, draft);
    });
    final draft = form.value;
    if (draft != null) _seed(draft);

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: widget.taskId == null
              ? l10n.tasksNewTask
              : l10n.tasksEditTitle,
          actions: const [TasksLanguageToggle()],
        ),
        footer: draft == null
            ? null
            : SrButton(
                label: l10n.commonSave,
                expand: true,
                loading: draft.saving,
                onPressed: () => ref.read(_provider.notifier).save(),
              ),
        body: SrAsyncView<TaskDraft>(
          value: form,
          onRetry: () => ref.invalidate(_provider),
          loading: (_) => const SrSkeletonList(count: 5, cards: true),
          data: (context, draft) => _Form(
            draft: draft,
            notifier: ref.read(_provider.notifier),
            title: _title,
            notes: _notes,
            listening: _listening,
            onListening: (on) => setState(() => _listening = on),
            onSuggest: _suggest,
          ),
        ),
      ),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({
    required this.draft,
    required this.notifier,
    required this.title,
    required this.notes,
    required this.listening,
    required this.onListening,
    required this.onSuggest,
  });

  final TaskDraft draft;
  final TaskFormNotifier notifier;
  final TextEditingController title;
  final TextEditingController notes;
  final bool listening;
  final ValueChanged<bool> onListening;
  final ValueChanged<TaskDraft> onSuggest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final team = ref.watch(currentRoleProvider) != WorkspaceRole.member;
    final titleError = draft.failure?.fieldError('Title');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        _TypePicker(
          selected: draft.type,
          tiles: easy,
          onChanged: (type) {
            notifier.setType(type);
            onSuggest(draft.copyWith(type: type));
          },
        ),
        const SizedBox(height: 16),
        SrTextField(
          controller: title,
          label: l10n.tasksFieldWhat,
          hint: l10n.tasksFieldWhatHint,
          prefixIcon: draft.type.icon,
          textCapitalization: TextCapitalization.sentences,
          error: titleError == null ? null : l10n.commonRequired,
          onChanged: notifier.setTitle,
        ),
        const SizedBox(height: 14),
        _LeadField(
          draft: draft,
          onChanged: (lead) {
            notifier.setLead(lead);
            onSuggest(draft.copyWith(lead: lead));
          },
        ),
        const SizedBox(height: 14),
        _DueFields(draft: draft, onChanged: notifier.setDue),
        if (team && !easy) ...[
          const SizedBox(height: 14),
          _AssigneeField(draft: draft, onChanged: notifier.setAssignee),
        ],
        if (!easy)
          ToggleRow(
            title: l10n.tasksRemind,
            subtitle: _reminderText(context),
            value: draft.reminderMinutes != null,
            onChanged: (on) => notifier.setReminder(on ? 30 : null),
            onSubtitleTap: draft.reminderMinutes == null
                ? null
                : () async {
                    final picked = await pickReminder(
                      context,
                      draft.reminderMinutes,
                    );
                    if (picked != null) notifier.setReminder(picked);
                  },
          ),
        const SizedBox(height: 8),
        SrTextField(
          controller: notes,
          label: l10n.tasksFieldNotes,
          optional: true,
          hint: l10n.tasksFieldNotesHint,
          helper: listening ? l10n.tasksDictateListening : null,
          multiline: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: notifier.setNotes,
          suffix: DictationButton(
            controller: notes,
            onChanged: notifier.setNotes,
            onListening: onListening,
          ),
        ),
      ],
    );
  }

  String _reminderText(BuildContext context) {
    final minutes = draft.reminderMinutes;
    return minutes == null
        ? context.l10n.tasksRemindOff
        : reminderLabel(context, minutes);
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({
    required this.selected,
    required this.tiles,
    required this.onChanged,
  });

  final TaskType selected;
  final bool tiles;
  final ValueChanged<TaskType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!tiles) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final type in TaskType.values)
            SrChip(
              label: type.label(l10n),
              icon: type.icon,
              selected: type == selected,
              onTap: () => onChanged(type),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrFieldLabel(l10n.tasksFieldType),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            for (final type in TaskType.values)
              _TypeTile(
                type: type,
                selected: type == selected,
                onTap: () => onChanged(type),
              ),
          ],
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final TaskType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      tone: selected ? SrCardTone.tint : SrCardTone.plain,
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type.icon, size: 26, color: selected ? c.accent : c.ink2),
          const SizedBox(height: 6),
          Text(
            type.label(context.l10n),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppText.caption(selected ? c.accent : c.ink, size: 12.5),
          ),
        ],
      ),
    );
  }
}

class _LeadField extends ConsumerWidget {
  const _LeadField({required this.draft, required this.onChanged});

  final TaskDraft draft;
  final ValueChanged<LeadOption?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lead = draft.lead;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: SrDropdownField(
            label: l10n.tasksFieldLinked,
            optional: true,
            placeholder: l10n.tasksFieldLinkedHint,
            value: lead == null ? null : l10n.tasksLeadSuffix(lead.shortName),
            icon: Icons.person_search_outlined,
            error: draft.failure?.fieldError('LeadId'),
            onTap: () async {
              final picked = await pickLead(context, ref, currentId: lead?.id);
              if (picked != null) onChanged(picked);
            },
          ),
        ),
        if (lead != null) ...[
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: SrIconButton(
              icon: Icons.close_rounded,
              tooltip: l10n.tasksLeadClear,
              onTap: () => onChanged(null),
            ),
          ),
        ],
      ],
    );
  }
}

class _DueFields extends StatelessWidget {
  const _DueFields({required this.draft, required this.onChanged});

  final TaskDraft draft;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final due = draft.due;
    final today = AppDateUtils.dateOnly(DateTime.now());
    DateTime onDay(int days) => DateTime(
      today.year,
      today.month,
      today.day + days,
      due.hour,
      due.minute,
    );
    final quick = [
      (l10n.commonToday, 0),
      (l10n.commonTomorrow, 1),
      (l10n.tasksInDays(fmt.number(3)), 3),
      (l10n.tasksNextWeek, 7),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SrDropdownField(
                label: l10n.tasksFieldWhen,
                icon: Icons.event_outlined,
                value: _dayLabel(context, due, today),
                onTap: () async {
                  final picked = await showSrDatePicker(
                    context: context,
                    initial: due,
                    first: today.subtract(const Duration(days: 365)),
                  );
                  if (picked == null) return;
                  onChanged(
                    DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      due.hour,
                      due.minute,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrDropdownField(
                label: l10n.tasksFieldTime,
                icon: Icons.schedule_rounded,
                value: fmt.time(due),
                onTap: () async {
                  final picked = await showSrDatePicker(
                    context: context,
                    initial: due,
                    withTime: true,
                    first: today.subtract(const Duration(days: 365)),
                  );
                  if (picked != null) onChanged(picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (label, days) in quick)
              SrChip(
                label: label,
                selected: AppDateUtils.isSameDay(due, onDay(days)),
                onTap: () => onChanged(onDay(days)),
              ),
          ],
        ),
      ],
    );
  }

  static String _dayLabel(BuildContext context, DateTime due, DateTime today) {
    if (AppDateUtils.isSameDay(due, today)) return context.l10n.commonToday;
    if (AppDateUtils.isSameDay(due, today.add(const Duration(days: 1)))) {
      return context.l10n.commonTomorrow;
    }
    return context.fmt.weekdayDate(due);
  }
}

class _AssigneeField extends ConsumerWidget {
  const _AssigneeField({required this.draft, required this.onChanged});

  final TaskDraft draft;
  final ValueChanged<MemberOption?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final assignee = draft.assignee;
    final members = ref.watch(taskMembersProvider);
    return SrDropdownField(
      label: l10n.tasksFieldAssign,
      icon: Icons.person_outline_rounded,
      value: assignee == null
          ? l10n.tasksMe
          : assignee.name.of(context.fmt.isBangla),
      error:
          draft.failure?.fieldError('AssignedToEmployeeId') ??
          (members.hasError ? l10n.errorGeneric : null),
      onTap: () async {
        final list = members.value;
        if (list == null) {
          ref.invalidate(taskMembersProvider);
          return;
        }
        final picked = await pickMember(
          context,
          list,
          title: l10n.tasksFieldAssign,
          currentId: assignee?.id,
        );
        if (picked == null) return;
        onChanged(picked.isMe ? null : picked);
      },
    );
  }
}

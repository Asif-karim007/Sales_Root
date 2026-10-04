import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/tasks/models/event_draft.dart';
import 'package:salesroot/features/tasks/providers/calendar_providers.dart';
import 'package:salesroot/features/tasks/view/widget/reminder_options.dart';
import 'package:salesroot/features/tasks/view/widget/task_feedback.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/features/tasks/view/widget/toggle_row.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #38 `privateevent`: a private event on the user's own calendar. Opens on
/// `?date=` for a new one or `?id=` to edit.
class PrivateEventScreen extends ConsumerStatefulWidget {
  const PrivateEventScreen({super.key, this.eventId, this.day});

  final int? eventId;
  final DateTime? day;

  @override
  ConsumerState<PrivateEventScreen> createState() => _PrivateEventScreenState();
}

class _PrivateEventScreenState extends ConsumerState<PrivateEventScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  bool _seeded = false;

  EventFormNotifierProvider get _provider =>
      eventFormProvider(eventId: widget.eventId, day: widget.day);

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  void _seed(EventDraft draft) {
    if (_seeded) return;
    _seeded = true;
    _title.text = draft.title;
    _location.text = draft.location;
  }

  void _onChange(EventDraft? previous, EventDraft next) {
    final l10n = context.l10n;
    final outcome = next.outcome;
    if (outcome != null && previous?.outcome == null) {
      showSrSuccess(
        context,
        outcome == EventOutcome.deleted
            ? l10n.tasksEventDeleted
            : l10n.tasksEventSaved,
      );
      context.pop();
      return;
    }
    final failure = next.failure;
    if (failure == null || identical(failure, previous?.failure)) return;
    if (failure.isValidation && failure.fieldErrors.isNotEmpty) return;
    showSrError(context, failureText(context, failure));
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.tasksEventDeleteTitle,
      message: l10n.tasksEventDeleteBody,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed) await ref.read(_provider.notifier).delete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = ref.watch(_provider);
    final access = ref.watch(moduleAccessProvider(AppModule.calendar));
    ref.listen(_provider, (previous, next) {
      final draft = next.value;
      if (draft != null) _onChange(previous?.value, draft);
    });
    final draft = form.value;
    if (draft != null) _seed(draft);
    final edit = widget.eventId != null;

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: edit ? l10n.tasksEventEditTitle : l10n.tasksEventTitle,
          actions: [
            const TasksLanguageToggle(),
            if (edit && access.canDelete && draft != null)
              SrIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: l10n.commonDelete,
                onTap: draft.saving ? null : _delete,
              ),
          ],
        ),
        footer: draft == null || (edit && !access.canEdit)
            ? null
            : SrButton(
                label: l10n.commonSave,
                expand: true,
                loading: draft.saving,
                onPressed: () => ref.read(_provider.notifier).save(),
              ),
        body: SrAsyncView<EventDraft>(
          value: form,
          onRetry: () => ref.invalidate(_provider),
          loading: (_) => const SrSkeletonList(count: 4, cards: true),
          data: (context, draft) => _EventForm(
            draft: draft,
            notifier: ref.read(_provider.notifier),
            title: _title,
            location: _location,
          ),
        ),
      ),
    );
  }
}

class _EventForm extends StatelessWidget {
  const _EventForm({
    required this.draft,
    required this.notifier,
    required this.title,
    required this.location,
  });

  final EventDraft draft;
  final EventFormNotifier notifier;
  final TextEditingController title;
  final TextEditingController location;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final start = draft.start;
    final reminder = draft.reminderMinutes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        SrTextField(
          controller: title,
          label: l10n.tasksEventFieldTitle,
          hint: l10n.tasksEventFieldTitleHint,
          textCapitalization: TextCapitalization.sentences,
          error: draft.failure?.fieldError('Title') == null
              ? null
              : l10n.commonRequired,
          onChanged: notifier.setTitle,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SrDropdownField(
                label: l10n.tasksEventDate,
                icon: Icons.event_outlined,
                value: fmt.dayMonth(start),
                onTap: () async {
                  final picked = await showSrDatePicker(
                    context: context,
                    initial: start,
                  );
                  if (picked == null) return;
                  notifier.setStart(
                    DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      start.hour,
                      start.minute,
                    ),
                  );
                },
              ),
            ),
            if (!draft.allDay) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SrDropdownField(
                  label: l10n.tasksFieldTime,
                  icon: Icons.schedule_rounded,
                  value: fmt.time(start),
                  onTap: () async {
                    final picked = await showSrDatePicker(
                      context: context,
                      initial: start,
                      withTime: true,
                    );
                    if (picked != null) notifier.setStart(picked);
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        SrTextField(
          controller: location,
          label: l10n.tasksEventLocation,
          optional: true,
          hint: l10n.tasksEventLocationHint,
          prefixIcon: Icons.place_outlined,
          onChanged: notifier.setLocation,
        ),
        const SizedBox(height: 14),
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ToggleRow(
                title: l10n.tasksEventPrivate,
                subtitle: draft.isPrivate
                    ? l10n.tasksEventPrivateSub
                    : l10n.tasksEventSharedSub,
                value: draft.isPrivate,
                onChanged: notifier.setPrivate,
              ),
              Divider(height: 1, color: SrColors.of(context).line),
              ToggleRow(
                title: l10n.tasksAllDay,
                value: draft.allDay,
                onChanged: notifier.setAllDay,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ToggleRow(
          title: l10n.tasksRemind,
          subtitle: reminder == null
              ? l10n.tasksRemindOff
              : reminderLabel(context, reminder),
          value: reminder != null,
          onChanged: (on) => notifier.setReminder(on ? 60 : null),
          onSubtitleTap: reminder == null
              ? null
              : () async {
                  final picked = await pickReminder(context, reminder);
                  if (picked != null) notifier.setReminder(picked);
                },
        ),
      ],
    );
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/tasks/data/calendar_repository.dart';
import 'package:salesroot/features/tasks/data/fake_calendar_repository.dart';
import 'package:salesroot/features/tasks/models/calendar_event.dart';
import 'package:salesroot/features/tasks/models/event_draft.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';

part 'calendar_providers.g.dart';

@Riverpod(keepAlive: true)
CalendarRepository calendarRepository(Ref ref) =>
    FakeCalendarRepository(ref.watch(fakeBackendProvider));

/// The month on screen, the chosen day and whether the agenda shows that
/// day's whole week. Weeks run Saturday to Friday.
class CalendarCursor {
  const CalendarCursor({
    required this.month,
    required this.selected,
    this.week = false,
  });

  final DateTime month;
  final DateTime selected;
  final bool week;

  DateTime get monthEnd => DateTime(month.year, month.month + 1);

  DateTime get weekStart => DateTime(
    selected.year,
    selected.month,
    selected.day - (selected.weekday - DateTime.saturday) % 7,
  );

  DateTime get weekEnd =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
}

@riverpod
class CalendarCursorNotifier extends _$CalendarCursorNotifier {
  @override
  CalendarCursor build() {
    final today = AppDateUtils.dateOnly(DateTime.now());
    return CalendarCursor(
      month: DateTime(today.year, today.month),
      selected: today,
    );
  }

  void select(DateTime day) => state = CalendarCursor(
    month: DateTime(day.year, day.month),
    selected: AppDateUtils.dateOnly(day),
    week: state.week,
  );

  /// Moves a month, keeping the chosen day of the month where it exists.
  void shiftMonth(int months) {
    final month = DateTime(state.month.year, state.month.month + months);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final day = state.selected.day.clamp(1, lastDay);
    select(DateTime(month.year, month.month, day));
  }

  void showWeek(bool week) => state = CalendarCursor(
    month: state.month,
    selected: state.selected,
    week: week,
  );
}

/// The user's tasks and private events in [from]..[to), merged.
@riverpod
Future<CalendarAgenda> calendarAgenda(
  Ref ref,
  DateTime from,
  DateTime to,
) async {
  final results = await Future.wait<List<Object>>([
    ref.watch(taskRepositoryProvider).between(from, to),
    ref.watch(calendarRepositoryProvider).between(from, to),
  ]);
  return CalendarAgenda(
    from: from,
    to: to,
    tasks: results[0].cast<Task>(),
    events: results[1].cast<CalendarEvent>(),
  );
}

/// The private-event form: new on [day], or editing [eventId].
@riverpod
class EventFormNotifier extends _$EventFormNotifier {
  @override
  Future<EventDraft> build({int? eventId, DateTime? day}) async {
    if (eventId != null) {
      return EventDraft.fromEvent(
        await ref.read(calendarRepositoryProvider).get(eventId),
      );
    }
    final now = DateTime.now();
    final on = day ?? now;
    return EventDraft(start: DateTime(on.year, on.month, on.day, now.hour + 1));
  }

  void _edit(EventDraft Function(EventDraft draft) change) {
    final draft = state.value;
    if (draft == null || draft.saving) return;
    state = AsyncData(change(draft));
  }

  void setTitle(String title) => _edit((d) => d.copyWith(title: title));

  void setLocation(String location) =>
      _edit((d) => d.copyWith(location: location));

  void setStart(DateTime start) => _edit((d) => d.copyWith(start: start));

  void setAllDay(bool allDay) => _edit((d) => d.copyWith(allDay: allDay));

  void setPrivate(bool private) => _edit((d) => d.copyWith(isPrivate: private));

  void setReminder(int? minutes) =>
      _edit((d) => d.copyWith(reminderMinutes: minutes));

  Future<void> save() => _submit(EventOutcome.saved, (repository, draft) async {
    final id = draft.eventId;
    if (id == null) {
      await repository.create(draft.toInput());
    } else {
      await repository.save(id, draft.toInput());
    }
  });

  Future<void> delete() =>
      _submit(EventOutcome.deleted, (repository, draft) async {
        final id = draft.eventId;
        if (id != null) await repository.delete(id);
      });

  Future<void> _submit(
    EventOutcome outcome,
    Future<void> Function(CalendarRepository repository, EventDraft draft) work,
  ) async {
    final draft = state.value;
    if (draft == null || draft.saving) return;
    state = AsyncData(draft.copyWith(saving: true, failure: null));
    try {
      await work(ref.read(calendarRepositoryProvider), draft);
      if (!ref.mounted) return;
      ref.invalidate(calendarAgendaProvider);
      state = AsyncData(draft.copyWith(saving: false, outcome: outcome));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(draft.copyWith(saving: false, failure: failure));
    }
  }
}

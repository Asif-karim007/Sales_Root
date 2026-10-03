import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/tasks/models/calendar_event.dart';

enum EventOutcome { saved, deleted }

/// The private-event form (#38) as it is being filled.
class EventDraft {
  const EventDraft({
    required this.start,
    this.eventId,
    this.title = '',
    this.location = '',
    this.allDay = false,
    this.isPrivate = true,
    this.reminderMinutes = 60,
    this.saving = false,
    this.outcome,
    this.failure,
  });

  factory EventDraft.fromEvent(CalendarEvent event) => EventDraft(
    eventId: event.id,
    start: event.start,
    title: event.title,
    location: event.location ?? '',
    allDay: event.allDay,
    isPrivate: event.isPrivate,
    reminderMinutes: event.reminderMinutes,
  );

  static const _keep = Object();

  final int? eventId;
  final DateTime start;
  final String title;
  final String location;
  final bool allDay;
  final bool isPrivate;

  /// Null turns the reminder off.
  final int? reminderMinutes;
  final bool saving;

  /// Set once the event is saved or deleted; the screen then closes.
  final EventOutcome? outcome;
  final ApiFailure? failure;

  bool get isEdit => eventId != null;

  CalendarEventInput toInput() => CalendarEventInput(
    title: title,
    start: start,
    location: location,
    allDay: allDay,
    isPrivate: isPrivate,
    reminderMinutes: reminderMinutes,
  );

  EventDraft copyWith({
    DateTime? start,
    String? title,
    String? location,
    bool? allDay,
    bool? isPrivate,
    Object? reminderMinutes = _keep,
    bool? saving,
    EventOutcome? outcome,
    Object? failure = _keep,
  }) => EventDraft(
    eventId: eventId,
    start: start ?? this.start,
    title: title ?? this.title,
    location: location ?? this.location,
    allDay: allDay ?? this.allDay,
    isPrivate: isPrivate ?? this.isPrivate,
    reminderMinutes: identical(reminderMinutes, _keep)
        ? this.reminderMinutes
        : reminderMinutes as int?,
    saving: saving ?? this.saving,
    outcome: outcome ?? this.outcome,
    failure: identical(failure, _keep) ? this.failure : failure as ApiFailure?,
  );
}

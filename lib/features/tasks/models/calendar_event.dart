import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/tasks/models/task.dart';

/// A private event on the user's own calendar (#38). Teammates only ever see
/// it as "busy".
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    this.location,
    this.allDay = false,
    this.isPrivate = true,
    this.reminderMinutes,
  });

  final int id;
  final String title;
  final DateTime start;
  final String? location;
  final bool allDay;
  final bool isPrivate;
  final int? reminderMinutes;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: jsonInt(json['Id']) ?? 0,
    title: json['Title'] as String? ?? '',
    start: jsonDate(json['Start']) ?? DateTime(2000),
    location: json['Location'] as String?,
    allDay: jsonBool(json['AllDay']),
    isPrivate: json['IsPrivate'] != false,
    reminderMinutes: jsonInt(json['ReminderMinutes']),
  );
}

class CalendarEventInput {
  const CalendarEventInput({
    required this.title,
    required this.start,
    this.location,
    this.allDay = false,
    this.isPrivate = true,
    this.reminderMinutes,
  });

  final String title;
  final DateTime start;
  final String? location;
  final bool allDay;
  final bool isPrivate;
  final int? reminderMinutes;

  Map<String, dynamic> toJson() {
    final location = this.location?.trim() ?? '';
    return {
      'Title': title.trim(),
      'Start': jsonUtc(allDay ? AppDateUtils.dateOnly(start) : start),
      'Location': location.isEmpty ? null : location,
      'AllDay': allDay,
      'IsPrivate': isPrivate,
      'ReminderMinutes': reminderMinutes,
    }..removeWhere((_, value) => value == null);
  }
}

/// One line of the day agenda: a task or a private event.
sealed class AgendaItem {
  const AgendaItem();

  DateTime get at;
}

class TaskAgendaItem extends AgendaItem {
  const TaskAgendaItem(this.task);

  final Task task;

  @override
  DateTime get at => task.dueDate ?? DateTime(2000);
}

class EventAgendaItem extends AgendaItem {
  const EventAgendaItem(this.event);

  final CalendarEvent event;

  @override
  DateTime get at => event.start;
}

/// Tasks and private events in [from]..[to), grouped by day and sorted by
/// time.
class CalendarAgenda {
  CalendarAgenda({
    required this.from,
    required this.to,
    required List<Task> tasks,
    required List<CalendarEvent> events,
  }) : _days = _group(tasks, events);

  final DateTime from;
  final DateTime to;
  final Map<DateTime, List<AgendaItem>> _days;

  List<AgendaItem> on(DateTime day) =>
      _days[AppDateUtils.dateOnly(day)] ?? const [];

  bool hasItems(DateTime day) => on(day).isNotEmpty;

  static Map<DateTime, List<AgendaItem>> _group(
    List<Task> tasks,
    List<CalendarEvent> events,
  ) {
    final days = <DateTime, List<AgendaItem>>{};
    final items = <AgendaItem>[
      for (final task in tasks)
        if (task.dueDate != null) TaskAgendaItem(task),
      for (final event in events) EventAgendaItem(event),
    ]..sort((a, b) => a.at.compareTo(b.at));
    for (final item in items) {
      days.putIfAbsent(AppDateUtils.dateOnly(item.at), () => []).add(item);
    }
    return days;
  }
}

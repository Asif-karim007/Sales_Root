import 'package:salesroot/features/tasks/models/calendar_event.dart';

abstract interface class CalendarRepository {
  /// The user's private events starting in [from]..[to).
  Future<List<CalendarEvent>> between(DateTime from, DateTime to);

  Future<CalendarEvent> get(int id);

  Future<CalendarEvent> create(CalendarEventInput input);

  Future<CalendarEvent> save(int id, CalendarEventInput input);

  Future<void> delete(int id);
}

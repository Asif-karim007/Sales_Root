import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/tasks/data/calendar_fixtures.dart';
import 'package:salesroot/features/tasks/data/calendar_repository.dart';
import 'package:salesroot/features/tasks/models/calendar_event.dart';

class FakeCalendarRepository implements CalendarRepository {
  FakeCalendarRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _table => _backend.table('calendar_events', calendarFixtures);

  @override
  Future<List<CalendarEvent>> between(DateTime from, DateTime to) =>
      _backend.run('Calendar events', () {
        return [
          for (final row in _table.rows)
            if (_mine(row) && _inRange(row, from, to))
              CalendarEvent.fromJson(row),
        ];
      }, module: AppModule.calendar);

  @override
  Future<CalendarEvent> get(String id) => _backend.run(
    'Calendar event $id',
    () => CalendarEvent.fromJson(_own(id)),
    module: AppModule.calendar,
  );

  @override
  Future<CalendarEvent> create(CalendarEventInput input) => _backend.run(
    'Calendar event create',
    () {
      final body = input.toJson();
      fakeRequire(body, ['Title', 'Start']);
      final saved = _table.insert({...body, 'OwnerId': _backend.meId});
      return CalendarEvent.fromJson(saved);
    },
    module: AppModule.calendar,
    right: ModuleRight.add,
  );

  @override
  Future<CalendarEvent> save(String id, CalendarEventInput input) =>
      _backend.run(
        'Calendar event save $id',
        () {
          final row = _own(id);
          final body = input.toJson();
          fakeRequire(body, ['Title', 'Start']);
          row
            ..remove('Location')
            ..remove('ReminderMinutes');
          return CalendarEvent.fromJson(_table.update(_key(id), body));
        },
        module: AppModule.calendar,
        right: ModuleRight.edit,
      );

  @override
  Future<void> delete(String id) => _backend.run(
    'Calendar event delete $id',
    () {
      _own(id);
      _table.delete(_key(id));
    },
    module: AppModule.calendar,
    right: ModuleRight.delete,
  );

  bool _mine(Map<String, dynamic> row) =>
      jsonInt(row['OwnerId']) == _backend.meId;

  Map<String, dynamic> _own(String id) {
    final row = _table.byId(_key(id));
    if (!_mine(row)) throw const ApiFailure(404, 'Record not found');
    return row;
  }

  static int _key(String id) => int.tryParse(id) ?? 0;

  static bool _inRange(Map<String, dynamic> row, DateTime from, DateTime to) {
    final start = jsonDate(row['Start']);
    return start != null && !start.isBefore(from) && start.isBefore(to);
  }
}

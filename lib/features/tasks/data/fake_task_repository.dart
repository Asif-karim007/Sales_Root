import 'package:collection/collection.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/tasks/data/task_fixtures.dart';
import 'package:salesroot/features/tasks/data/task_repository.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _table => _backend.table('tasks', taskFixtures);

  bool get _isMember => _backend.role == WorkspaceRole.member;

  @override
  Future<PageResult<Task>> list(TaskQuery query) =>
      _backend.run('Task list ${query.bucket.wire} p${query.page}', () {
        final now = DateTime.now();
        final rows =
            _visible(
                query.filter,
              ).where((row) => _inBucket(row, query.bucket, now)).toList()
              ..sort(_order(query.bucket));
        final page = fakePage(rows, page: query.page, pageSize: query.pageSize);
        return PageResult.fromJson({
          ...page,
          'Items': [
            for (final row in page['Items'] as List<Map<String, dynamic>>)
              _present(row, now),
          ],
        }, Task.fromJson);
      }, module: AppModule.task);

  @override
  Future<TaskCounts> counts(TaskFilter filter) =>
      _backend.run('Task counts', () {
        final now = DateTime.now();
        final rows = _visible(filter).toList();
        int count(bool Function(Map<String, dynamic> row) test) =>
            rows.where(test).length;
        return TaskCounts.fromJson({
          'Today': count((r) => !_done(r) && _daysUntil(r, now) == 0),
          for (final bucket in TaskBucket.values.skip(1))
            bucket.wire: count((r) => _inBucket(r, bucket, now)),
        });
      }, module: AppModule.task);

  @override
  Future<List<Task>> between(DateTime from, DateTime to) =>
      _backend.run('Tasks between', () {
        final now = DateTime.now();
        return [
          for (final row in _table.rows)
            if (_assigneeId(row) == _backend.meId &&
                !_due(row).isBefore(from) &&
                _due(row).isBefore(to))
              Task.fromJson(_present(row, now)),
        ];
      }, module: AppModule.task);

  @override
  Future<Task> get(int id) => _backend.run(
    'Task $id',
    () => Task.fromJson(_present(_visibleRow(id), DateTime.now())),
    module: AppModule.task,
  );

  @override
  Future<Task> create(TaskInput input) => _backend.run(
    'Task create',
    () {
      final body = input.toJson();
      fakeRequire(body, ['Title', 'TypeId', 'DueDate']);
      final me = _backend.graph.me;
      final saved = _table.insert({
        ..._fields(body),
        'Status': _status(false),
        'AssignedTo': _person(_assignee(body) ?? me),
        'CreatedBy': _person(me),
        'CreatedOn': jsonUtc(DateTime.now()),
      });
      return Task.fromJson(_present(saved, DateTime.now()));
    },
    module: AppModule.task,
    right: ModuleRight.add,
  );

  @override
  Future<Task> save(int id, TaskInput input) => _backend.run(
    'Task save $id',
    () {
      final row = _editable(id);
      final body = input.toJson();
      fakeRequire(body, ['Title', 'TypeId', 'DueDate']);
      final assignee = _assignee(body);
      final fields = _fields(body);
      for (final key in _clearable) {
        row.remove(key);
      }
      _table.update(id, {
        ...fields,
        'AssignedTo': ?(assignee == null ? null : _person(assignee)),
      });
      return Task.fromJson(_present(row, DateTime.now()));
    },
    module: AppModule.task,
    right: ModuleRight.edit,
  );

  @override
  Future<Task> setDone(int id, {required bool done}) => _backend.run(
    done ? 'Task done $id' : 'Task reopen $id',
    () {
      _editable(id);
      final row = _table.update(id, {
        'Status': _status(done),
        'CompletedOn': done ? jsonUtc(DateTime.now()) : null,
      });
      return Task.fromJson(_present(row, DateTime.now()));
    },
    module: AppModule.task,
    right: ModuleRight.edit,
  );

  @override
  Future<Task> reschedule(int id, DateTime due) => _backend.run(
    'Task reschedule $id',
    () {
      _editable(id);
      final row = _table.update(id, {'DueDate': jsonUtc(due)});
      return Task.fromJson(_present(row, DateTime.now()));
    },
    module: AppModule.task,
    right: ModuleRight.edit,
  );

  @override
  Future<Task> reassign(int id, int memberId) => _backend.run(
    'Task reassign $id',
    () {
      if (_isMember) throw _forbidden;
      _editable(id);
      final member = _member(memberId);
      final row = _table.update(id, {'AssignedTo': _person(member)});
      return Task.fromJson(_present(row, DateTime.now()));
    },
    module: AppModule.task,
    right: ModuleRight.edit,
  );

  @override
  Future<void> delete(int id) => _backend.run(
    'Task delete $id',
    () {
      if (!_canDelete(_visibleRow(id))) throw _forbidden;
      _table.delete(id);
    },
    module: AppModule.task,
    right: ModuleRight.delete,
  );

  /// Optional fields an edit replaces, so leaving one out clears it.
  static const _clearable = [
    'Description',
    'Notes',
    'Lead',
    'Amount',
    'ReminderMinutes',
  ];

  static const _forbidden = ApiFailure(
    403,
    'You do not have permission to do that.',
  );

  Iterable<Map<String, dynamic>> _visible(TaskFilter filter) =>
      _table.rows.where(
        (row) =>
            _canSee(row) &&
            switch (filter.who) {
              TaskWho.mine => _assigneeId(row) == _backend.meId,
              TaskWho.everyone => true,
              TaskWho.member => _assigneeId(row) == filter.memberId,
            } &&
            (filter.type == null || jsonInt(row['TypeId']) == filter.type?.id),
      );

  bool _canSee(Map<String, dynamic> row) =>
      !_isMember ||
      _assigneeId(row) == _backend.meId ||
      _creatorId(row) == _backend.meId;

  Map<String, dynamic> _visibleRow(int id) {
    final row = _table.byId(id);
    if (!_canSee(row)) throw const ApiFailure(404, 'Record not found');
    return row;
  }

  Map<String, dynamic> _editable(int id) {
    final row = _visibleRow(id);
    if (!_canEdit(row)) throw _forbidden;
    return row;
  }

  bool _canEdit(Map<String, dynamic> row) =>
      !_isMember ||
      _assigneeId(row) == _backend.meId ||
      _creatorId(row) == _backend.meId;

  bool _canDelete(Map<String, dynamic> row) =>
      !_isMember || _creatorId(row) == _backend.meId;

  SeedMember? _assignee(Map<String, dynamic> body) {
    final id = jsonInt(body['AssignedToEmployeeId']);
    if (id == null) return null;
    if (_isMember && id != _backend.meId) throw _forbidden;
    return _member(id);
  }

  SeedMember _member(int id) =>
      _backend.graph.members.firstWhereOrNull((m) => m.id == id) ??
      (throw const ApiFailure(
        400,
        'Choose a teammate',
        fieldErrors: {'AssignedToEmployeeId': 'Choose a teammate'},
      ));

  Map<String, dynamic> _fields(Map<String, dynamic> body) {
    final leadId = jsonInt(body['LeadId']);
    final lead = leadId == null
        ? null
        : _backend.graph.leads.firstWhereOrNull((l) => l.id == leadId);
    if (leadId != null && lead == null) {
      throw const ApiFailure(
        400,
        'This lead no longer exists',
        fieldErrors: {'LeadId': 'This lead no longer exists'},
      );
    }
    return {
      'Title': body['Title'],
      'TypeId': body['TypeId'],
      'DueDate': body['DueDate'],
      'Description': ?body['Description'],
      'Notes': ?body['Notes'],
      'Amount': ?body['Amount'],
      'ReminderMinutes': ?body['ReminderMinutes'],
      'Lead': ?(lead == null ? null : {'Id': lead.id, 'Name': lead.title}),
    };
  }

  Map<String, dynamic> _present(Map<String, dynamic> row, DateTime now) {
    final days = _daysUntil(row, now);
    return {
      ...row,
      'IsOverdue': !_done(row) && days < 0,
      'DaysUntilDue': days,
      'AssignedToMe': _assigneeId(row) == _backend.meId,
      'CanEdit': _canEdit(row),
      'CanDelete': _canDelete(row),
      'Lead': ?_leadDetail(row['Lead']),
    };
  }

  Map<String, dynamic>? _leadDetail(Object? link) {
    if (link is! Map<String, dynamic>) return null;
    final graph = _backend.graph;
    final lead = graph.leads.firstWhereOrNull((l) => l.id == link['Id']);
    if (lead == null) return link;
    final stage = SeedGraph.stages.firstWhereOrNull(
      (s) => s.$1 == lead.stageId,
    );
    final contact = graph.contacts.firstWhereOrNull(
      (c) => c.id == lead.contactId,
    );
    return {
      ...link,
      'StageName': ?stage?.$2,
      'StageNameBn': ?stage?.$3,
      'ContactName': ?contact?.name,
      'ContactPhone': ?contact?.phone,
    };
  }

  static Map<String, dynamic> _person(SeedMember member) => {
    'Id': member.id,
    'Name': member.name,
    'NameBn': member.nameBn,
  };

  static Map<String, dynamic> _status(bool done) => {
    'Id': done ? TaskStatusRef.doneId : TaskStatusRef.openId,
    'Name': done ? 'Done' : 'To do',
    'IsDone': done,
  };

  static bool _done(Map<String, dynamic> row) =>
      jsonBool((row['Status'] as Map<String, dynamic>?)?['IsDone']);

  static int? _assigneeId(Map<String, dynamic> row) =>
      jsonInt((row['AssignedTo'] as Map<String, dynamic>?)?['Id']);

  static int? _creatorId(Map<String, dynamic> row) =>
      jsonInt((row['CreatedBy'] as Map<String, dynamic>?)?['Id']);

  static DateTime _due(Map<String, dynamic> row) =>
      jsonDate(row['DueDate']) ?? DateTime(2000);

  static DateTime _completed(Map<String, dynamic> row) =>
      jsonDate(row['CompletedOn']) ?? _due(row);

  static int _daysUntil(Map<String, dynamic> row, DateTime now) {
    final due = _due(row);
    return DateTime.utc(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  static bool _inBucket(
    Map<String, dynamic> row,
    TaskBucket bucket,
    DateTime now,
  ) {
    final done = _done(row);
    final days = _daysUntil(row, now);
    return switch (bucket) {
      TaskBucket.today => (!done && days < 0) || days == 0 || days == 1,
      TaskBucket.overdue => !done && days < 0,
      TaskBucket.week => !done && days >= 0 && days < 7,
      TaskBucket.all => !done,
      TaskBucket.done => done,
    };
  }

  static int Function(Map<String, dynamic>, Map<String, dynamic>) _order(
    TaskBucket bucket,
  ) => bucket == TaskBucket.done
      ? (a, b) => _completed(b).compareTo(_completed(a))
      : (a, b) => _due(a).compareTo(_due(b));
}

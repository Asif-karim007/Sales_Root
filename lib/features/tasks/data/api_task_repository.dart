import 'package:collection/collection.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/tasks/data/task_api.dart';
import 'package:salesroot/features/tasks/data/task_repository.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';

/// Tasks over `/tasks`. The API has no single-task read, so [get] answers
/// from the rows already seen, or looks through the list.
class ApiTaskRepository implements TaskRepository {
  ApiTaskRepository(this._api, {this.me, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _scanSize = 100;
  static const _scanPages = 20;

  final TaskApi _api;

  /// The user's membership id in the current workspace.
  final String? me;
  final DateTime Function() _clock;
  final _seen = <String, Task>{};

  @override
  Future<PageResult<Task>> list(TaskQuery query) =>
      _page('Task list', query.toQuery(me: me, today: _clock()));

  @override
  Future<TaskCounts> counts(TaskFilter filter) async {
    const buckets = TaskBucket.values;
    final totals = await Future.wait([
      for (final bucket in buckets)
        list(
          TaskQuery(bucket: bucket, filter: filter, size: 1),
        ).then((page) => page.totalCount),
    ]);
    int of(TaskBucket bucket) => totals[buckets.indexOf(bucket)];
    return TaskCounts(
      today: of(TaskBucket.today),
      overdue: of(TaskBucket.overdue),
      week: of(TaskBucket.week),
      all: of(TaskBucket.all),
      done: of(TaskBucket.done),
    );
  }

  @override
  Future<List<Task>> between(DateTime from, DateTime to) async {
    final last = DateTime(to.year, to.month, to.day - 1);
    final tasks = <Task>[];
    await _scan(
      'Tasks between',
      {
        'from': AppDateUtils.toApiDateOnly(from),
        'to': AppDateUtils.toApiDateOnly(last),
        'assignee': me,
      },
      (page) {
        tasks.addAll(page.items);
        return false;
      },
    );
    return tasks;
  }

  @override
  Future<Task> get(String id) async {
    final seen = _seen[id];
    if (seen != null) return seen;
    Task? found;
    await _scan('Task $id', const {}, (page) {
      found = page.items.firstWhereOrNull((task) => task.id == id);
      return found != null;
    });
    return found ?? (throw const ApiFailure(404, 'Record not found'));
  }

  @override
  Future<Task> create(TaskInput input) =>
      _one('Task create', () => _api.create(input.toJson()));

  @override
  Future<Task> save(String id, TaskInput input) async {
    final saved = await _one(
      'Task save',
      () => _api.edit(id, input.toUpdateJson()),
    );
    final assignee = input.assigneeId;
    if (assignee == null || assignee == saved.assignedTo?.id) return saved;
    return reassign(id, assignee);
  }

  @override
  Future<Task> complete(String id) =>
      _one('Task done', () => _api.done(id, const {}));

  @override
  Future<Task> reschedule(String id, DateTime due) =>
      _one('Task move', () => _api.move(id, {'dueAt': jsonUtc(due)}));

  @override
  Future<Task> reassign(String id, String memberId) =>
      _one('Task assign', () => _api.assign(id, {'membershipId': memberId}));

  @override
  Future<void> delete(String id) async {
    await apiRequest('Task delete', () => _api.delete(id));
    _seen.remove(id);
  }

  Future<PageResult<Task>> _page(
    String label,
    Map<String, dynamic> query,
  ) async {
    final json = await apiRequest(label, () => _api.list(query));
    return PageResult.fromJson(jsonMap(json), _task);
  }

  /// Pages through `/tasks` with [query] until [stop] says so or the list
  /// ends.
  Future<void> _scan(
    String label,
    Map<String, dynamic> query,
    bool Function(PageResult<Task> page) stop,
  ) async {
    for (var page = 1; page <= _scanPages; page++) {
      final result = await _page(label, {
        ...query,
        ...pageQuery(page, size: _scanSize),
      });
      if (stop(result) || result.items.isEmpty) return;
      if (page * _scanSize >= result.totalCount) return;
    }
  }

  Future<Task> _one(String label, Future<dynamic> Function() request) async =>
      _task(jsonMap(await apiRequest(label, request)));

  Task _task(Map<String, dynamic> json) {
    final task = Task.fromJson(json, me: me, now: _clock());
    _seen[task.id] = task;
    return task;
  }
}

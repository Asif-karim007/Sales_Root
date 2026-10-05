import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';

abstract interface class TaskRepository {
  Future<PageResult<Task>> list(TaskQuery query);

  Future<TaskCounts> counts(TaskFilter filter);

  /// The user's own tasks due in [from]..[to), for the calendar.
  Future<List<Task>> between(DateTime from, DateTime to);

  Future<Task> get(String id);

  Future<Task> create(TaskInput input);

  Future<Task> save(String id, TaskInput input);

  Future<Task> complete(String id);

  Future<Task> reschedule(String id, DateTime due);

  Future<Task> reassign(String id, String memberId);

  Future<void> delete(String id);
}

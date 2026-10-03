import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';

abstract interface class TaskRepository {
  Future<PageResult<Task>> list(TaskQuery query);

  Future<TaskCounts> counts(TaskFilter filter);

  /// The user's own tasks due in [from]..[to), for the calendar.
  Future<List<Task>> between(DateTime from, DateTime to);

  Future<Task> get(int id);

  Future<Task> create(TaskInput input);

  Future<Task> save(int id, TaskInput input);

  Future<Task> setDone(int id, {required bool done});

  Future<Task> reschedule(int id, DateTime due);

  Future<Task> reassign(int id, int memberId);

  Future<void> delete(int id);
}

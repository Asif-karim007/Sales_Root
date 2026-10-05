import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/tasks/data/api_task_lookup_repository.dart';
import 'package:salesroot/features/tasks/data/api_task_repository.dart';
import 'package:salesroot/features/tasks/data/task_api.dart';
import 'package:salesroot/features/tasks/data/task_lookup_repository.dart';
import 'package:salesroot/features/tasks/data/task_repository.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_draft.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';
import 'package:salesroot/features/tasks/models/task_lookups.dart';
import 'package:salesroot/features/tasks/providers/calendar_providers.dart';

part 'task_providers.g.dart';

@Riverpod(keepAlive: true)
TaskApi taskApi(Ref ref) => TaskApi(ref.watch(dioProvider));

/// The user's membership id, rebuilding each repository on a workspace
/// switch.
String? _member(Ref ref) => ref
    .watch(currentWorkspaceProvider.select((w) => (w?.id, w?.membershipId)))
    .$2;

@Riverpod(keepAlive: true)
TaskRepository taskRepository(Ref ref) =>
    ApiTaskRepository(ref.watch(taskApiProvider), me: _member(ref));

@Riverpod(keepAlive: true)
TaskLookupRepository taskLookupRepository(Ref ref) =>
    ApiTaskLookupRepository(ref.watch(taskApiProvider), me: _member(ref));

@riverpod
class TaskBucketNotifier extends _$TaskBucketNotifier {
  @override
  TaskBucket build() => TaskBucket.today;

  void show(TaskBucket bucket) => state = bucket;
}

@riverpod
class TaskFilterNotifier extends _$TaskFilterNotifier {
  @override
  TaskFilter build() => const TaskFilter();

  void apply(TaskFilter filter) => state = filter;
}

@riverpod
Future<TaskCounts> taskCounts(Ref ref) =>
    ref.watch(taskRepositoryProvider).counts(ref.watch(taskFilterProvider));

@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<Paged<Task>> build() async {
    final query = TaskQuery(
      bucket: ref.watch(taskBucketProvider),
      filter: ref.watch(taskFilterProvider),
    );
    _query = query;
    return Paged.first(await ref.watch(taskRepositoryProvider).list(query));
  }

  TaskQuery? _query;

  Future<void> loadMore() async {
    final current = state.value;
    final query = _query;
    if (current == null ||
        query == null ||
        state.isLoading ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(taskRepositoryProvider)
          .list(query.atPage(current.page + 1));
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref.invalidate(taskCountsProvider);
    ref.invalidateSelf();
    await future;
  }

  /// Ticks [task] off in place before the server answers. On a failure the
  /// row goes back and the failure is rethrown.
  Future<Task> complete(Task task) async {
    _replace(task.asDone());
    try {
      final saved = await ref.read(taskRepositoryProvider).complete(task.id);
      if (!ref.mounted) return saved;
      _replace(saved);
      ref.invalidate(taskCountsProvider);
      ref.invalidate(taskProvider(task.id));
      ref.invalidate(calendarAgendaProvider);
      return saved;
    } on ApiFailure {
      if (ref.mounted) _replace(task);
      rethrow;
    }
  }

  void _replace(Task task) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.map((t) => t.id == task.id ? task : t));
  }
}

@riverpod
Future<Task> task(Ref ref, String id) =>
    ref.watch(taskRepositoryProvider).get(id);

@riverpod
Future<List<MemberOption>> taskMembers(Ref ref) =>
    ref.watch(taskLookupRepositoryProvider).members();

/// Task actions outside the list and the form. Each one refreshes every view
/// of tasks.
@Riverpod(keepAlive: true)
class TaskEditor extends _$TaskEditor {
  @override
  void build() {}

  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  Future<Task> create(TaskInput input) async {
    final saved = await _repository.create(input);
    if (!ref.mounted) return saved;
    _refreshLists();
    return saved;
  }

  Future<Task> complete(String id) => _apply(id, _repository.complete(id));

  Future<Task> reschedule(String id, DateTime due) =>
      _apply(id, _repository.reschedule(id, due));

  Future<Task> reassign(String id, String memberId) =>
      _apply(id, _repository.reassign(id, memberId));

  Future<void> delete(String id) async {
    await _repository.delete(id);
    if (!ref.mounted) return;
    _refreshLists();
  }

  Future<Task> _apply(String id, Future<Task> change) async {
    final saved = await change;
    if (!ref.mounted) return saved;
    ref.invalidate(taskProvider(id));
    _refreshLists();
    return saved;
  }

  void _refreshLists() {
    ref.invalidate(taskListProvider);
    ref.invalidate(taskCountsProvider);
    ref.invalidate(calendarAgendaProvider);
  }
}

/// The new-task form, prefilled from `?leadId=&title=&date=`, or the edit
/// form for [taskId]. A new task is due at 10:00 on [day], tomorrow by
/// default.
@riverpod
class TaskFormNotifier extends _$TaskFormNotifier {
  @override
  Future<TaskDraft> build({
    String? taskId,
    String? leadId,
    String? title,
    DateTime? day,
  }) async {
    if (taskId != null) {
      return TaskDraft.fromTask(
        await ref.read(taskRepositoryProvider).get(taskId),
      );
    }
    final now = DateTime.now();
    final on = day ?? DateTime(now.year, now.month, now.day + 1);
    return TaskDraft(
      type: TaskType.call,
      due: DateTime(on.year, on.month, on.day, 10),
      title: title ?? '',
      lead: leadId == null ? null : await _lead(leadId),
    );
  }

  Future<LeadOption?> _lead(String id) async {
    try {
      return await ref.read(taskLookupRepositoryProvider).lead(id);
    } on ApiFailure catch (failure) {
      if (failure.isNotFound) return null;
      rethrow;
    }
  }

  /// The server's answer to a blank title, which an edit does not get.
  static const _titleMissing = ApiFailure(
    422,
    'Please fill this in',
    fieldErrors: {'title': 'Please fill this in'},
  );

  void _edit(TaskDraft Function(TaskDraft draft) change) {
    final draft = state.value;
    if (draft == null || draft.saving) return;
    state = AsyncData(change(draft));
  }

  void setType(TaskType type) => _edit((d) => d.copyWith(type: type));

  void setTitle(String title) => _edit((d) => d.copyWith(title: title));

  void setNotes(String notes) => _edit((d) => d.copyWith(notes: notes));

  void setLead(LeadOption? lead) => _edit((d) => d.copyWith(lead: lead));

  void setAssignee(MemberOption? member) =>
      _edit((d) => d.copyWith(assignee: member));

  void setDue(DateTime due) => _edit((d) => d.copyWith(due: due));

  void setReminder(int? minutes) =>
      _edit((d) => d.copyWith(reminderMinutes: minutes));

  Future<void> save() async {
    final draft = state.value;
    if (draft == null || draft.saving) return;
    if (draft.title.trim().isEmpty) {
      state = AsyncData(draft.copyWith(failure: _titleMissing));
      return;
    }
    state = AsyncData(draft.copyWith(saving: true, failure: null));
    final repository = ref.read(taskRepositoryProvider);
    final id = draft.taskId;
    try {
      final saved = id == null
          ? await repository.create(draft.toInput())
          : await repository.save(id, draft.toInput());
      if (!ref.mounted) return;
      if (id != null) ref.invalidate(taskProvider(id));
      ref.invalidate(taskListProvider);
      ref.invalidate(taskCountsProvider);
      ref.invalidate(calendarAgendaProvider);
      state = AsyncData(draft.copyWith(saving: false, saved: saved));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(draft.copyWith(saving: false, failure: failure));
    }
  }
}

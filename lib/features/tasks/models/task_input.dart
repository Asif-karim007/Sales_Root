import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/tasks/models/task.dart';

/// The create/edit body. A reminder of 0 minutes turns it off; the server
/// sets 15 when the key is missing.
class TaskInput {
  const TaskInput({
    required this.title,
    required this.type,
    required this.dueDate,
    this.notes,
    this.leadId,
    this.assigneeId,
    this.reminderMinutes,
  });

  final String title;
  final TaskType type;
  final DateTime dueDate;
  final String? notes;
  final String? leadId;
  final String? assigneeId;
  final int? reminderMinutes;

  /// `TaskCreate`. Null keys are left out.
  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'type': type.wire,
    'dueAt': jsonUtc(dueDate),
    'remindMin': reminderMinutes ?? 0,
    'note': _text(notes),
    'leadId': leadId,
    'assigneeMembershipId': assigneeId,
  }..removeWhere((_, value) => value == null);

  /// `TaskUpdate`. The server skips null keys, so an emptied note is sent
  /// as an empty string.
  Map<String, dynamic> toUpdateJson() => {
    'title': title.trim(),
    'type': type.wire,
    'dueAt': jsonUtc(dueDate),
    'remindMin': reminderMinutes ?? 0,
    'note': _text(notes) ?? '',
  };

  static String? _text(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

/// Whose tasks the list shows.
enum TaskWho { mine, everyone, member }

/// The filters the list sheet sets. [memberId] applies when [who] is
/// [TaskWho.member].
class TaskFilter {
  const TaskFilter({this.who = TaskWho.mine, this.memberId});

  final TaskWho who;
  final String? memberId;

  bool get isNarrowed => who != TaskWho.mine;

  @override
  bool operator ==(Object other) =>
      other is TaskFilter && other.who == who && other.memberId == memberId;

  @override
  int get hashCode => Object.hash(who, memberId);
}

/// Paging and filters for the task list.
class TaskQuery {
  const TaskQuery({
    required this.bucket,
    this.filter = const TaskFilter(),
    this.page = 1,
    this.size = pageSize,
  });

  final TaskBucket bucket;
  final TaskFilter filter;
  final int page;
  final int size;

  TaskQuery atPage(int page) =>
      TaskQuery(bucket: bucket, filter: filter, page: page, size: size);

  /// [me] is the user's membership id, [today] the phone's date.
  Map<String, dynamic> toQuery({String? me, required DateTime today}) => {
    ...pageQuery(page, size: size),
    'view': bucket.view,
    'to': bucket == TaskBucket.week
        ? AppDateUtils.toApiDateOnly(
            DateTime(today.year, today.month, today.day + 7),
          )
        : null,
    'assignee': switch (filter.who) {
      TaskWho.mine => me,
      TaskWho.everyone => null,
      TaskWho.member => filter.memberId,
    },
  }..removeWhere((_, value) => value == null);
}

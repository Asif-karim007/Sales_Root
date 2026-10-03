import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/tasks/models/task.dart';

/// The create/edit body. Null keys are left out; the server rejects them.
class TaskInput {
  const TaskInput({
    required this.title,
    required this.type,
    required this.dueDate,
    this.description,
    this.notes,
    this.leadId,
    this.assignedToId,
    this.reminderMinutes,
    this.amount,
  });

  final String title;
  final TaskType type;
  final DateTime dueDate;
  final String? description;
  final String? notes;
  final int? leadId;
  final int? assignedToId;
  final int? reminderMinutes;
  final int? amount;

  Map<String, dynamic> toJson() => {
    'Title': title.trim(),
    'TypeId': type.id,
    'DueDate': jsonUtc(dueDate),
    'Description': _text(description),
    'Notes': _text(notes),
    'LeadId': leadId,
    'AssignedToEmployeeId': assignedToId,
    'ReminderMinutes': reminderMinutes,
    'Amount': amount,
  }..removeWhere((_, value) => value == null);

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
  const TaskFilter({this.who = TaskWho.mine, this.memberId, this.type});

  final TaskWho who;
  final int? memberId;
  final TaskType? type;

  bool get isNarrowed => who != TaskWho.mine || type != null;

  @override
  bool operator ==(Object other) =>
      other is TaskFilter &&
      other.who == who &&
      other.memberId == memberId &&
      other.type == type;

  @override
  int get hashCode => Object.hash(who, memberId, type);
}

/// Paging and filters for the task list.
class TaskQuery {
  const TaskQuery({
    required this.bucket,
    this.filter = const TaskFilter(),
    this.page = 1,
    this.pageSize = 20,
  });

  final TaskBucket bucket;
  final TaskFilter filter;
  final int page;
  final int pageSize;

  TaskQuery atPage(int page) =>
      TaskQuery(bucket: bucket, filter: filter, page: page, pageSize: pageSize);

  Map<String, dynamic> toQuery() => {
    'page': page,
    'pageSize': pageSize,
    'bucket': bucket.wire,
    'operationType': filter.who == TaskWho.mine ? 'MyTask' : null,
    'assignedToEmployeeId': filter.who == TaskWho.member
        ? filter.memberId
        : null,
    'typeId': filter.type?.id,
  }..removeWhere((_, value) => value == null);
}

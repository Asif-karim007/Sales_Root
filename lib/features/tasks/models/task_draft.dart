import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/features/tasks/models/task_input.dart';
import 'package:salesroot/features/tasks/models/task_lookups.dart';

/// The new-task and edit-task form (#35) as it is being filled. A null
/// [assignee] means the user themself.
class TaskDraft {
  const TaskDraft({
    required this.type,
    required this.due,
    this.taskId,
    this.title = '',
    this.notes = '',
    this.lead,
    this.assignee,
    this.reminderMinutes = 30,
    this.saving = false,
    this.saved,
    this.failure,
  });

  factory TaskDraft.fromTask(Task task) {
    final lead = task.lead;
    final leadId = lead?.id;
    final assignee = task.assignedTo;
    final assigneeId = assignee?.id;
    return TaskDraft(
      taskId: task.id,
      type: task.type,
      due: task.dueDate ?? DateTime.now(),
      title: task.title,
      notes: task.notes ?? '',
      lead: lead == null || leadId == null
          ? null
          : LeadOption(
              id: leadId,
              title: lead.name ?? '',
              companyName: task.companyName,
            ),
      assignee: assigneeId == null
          ? null
          : MemberOption(
              id: assigneeId,
              name: LocalizedName(assignee?.name ?? '', ''),
              isMe: task.assignedToMe,
            ),
      reminderMinutes: task.reminderMinutes,
    );
  }

  static const _keep = Object();

  final String? taskId;
  final TaskType type;
  final DateTime due;
  final String title;
  final String notes;
  final LeadOption? lead;
  final MemberOption? assignee;

  /// Null turns the reminder off.
  final int? reminderMinutes;
  final bool saving;
  final Task? saved;
  final ApiFailure? failure;

  bool get isEdit => taskId != null;

  TaskInput toInput() => TaskInput(
    title: title,
    type: type,
    dueDate: due,
    notes: notes,
    leadId: lead?.id,
    assigneeId: assignee?.id,
    reminderMinutes: reminderMinutes,
  );

  TaskDraft copyWith({
    TaskType? type,
    DateTime? due,
    String? title,
    String? notes,
    Object? lead = _keep,
    Object? assignee = _keep,
    Object? reminderMinutes = _keep,
    bool? saving,
    Object? saved = _keep,
    Object? failure = _keep,
  }) => TaskDraft(
    taskId: taskId,
    type: type ?? this.type,
    due: due ?? this.due,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    lead: identical(lead, _keep) ? this.lead : lead as LeadOption?,
    assignee: identical(assignee, _keep)
        ? this.assignee
        : assignee as MemberOption?,
    reminderMinutes: identical(reminderMinutes, _keep)
        ? this.reminderMinutes
        : reminderMinutes as int?,
    saving: saving ?? this.saving,
    saved: identical(saved, _keep) ? this.saved : saved as Task?,
    failure: identical(failure, _keep) ? this.failure : failure as ApiFailure?,
  );
}

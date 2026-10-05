import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// What a task asks for, by the server's `type`.
enum TaskType {
  call('call'),
  visit('visit'),
  meeting('meeting'),
  collection('collect'),
  delivery('delivery'),
  own('todo');

  const TaskType(this.wire);

  final String wire;

  static TaskType fromWire(String? value) =>
      values.firstWhere((type) => type.wire == value, orElse: () => own);
}

class TaskPerson {
  const TaskPerson({this.id, this.name});

  final String? id;
  final String? name;
}

/// The lead a task belongs to, with what the detail screen shows about it.
class TaskLeadRef {
  const TaskLeadRef({this.id, this.name, this.phone});

  final String? id;
  final String? name;
  final String? phone;
}

/// One task. The API sends no overdue flag, so [isOverdue] and
/// [daysUntilDue] count calendar days from the phone's date at parse time.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.type,
    this.status = 'open',
    this.dueDate,
    this.isOverdue = false,
    this.daysUntilDue,
    this.assignedTo,
    this.assignedToMe = false,
    this.createdById,
    this.createdOn,
    this.completedOn,
    this.lead,
    this.companyId,
    this.companyName,
    this.contactId,
    this.contactName,
    this.contactPhone,
    this.notes,
    this.reminderMinutes,
  });

  final String id;
  final String title;
  final TaskType type;

  /// The server's status: `open` or `done`.
  final String status;
  final DateTime? dueDate;
  final bool isOverdue;
  final int? daysUntilDue;
  final TaskPerson? assignedTo;
  final bool assignedToMe;

  /// The user (not membership) who created the task.
  final String? createdById;
  final DateTime? createdOn;
  final DateTime? completedOn;
  final TaskLeadRef? lead;
  final String? companyId;
  final String? companyName;
  final String? contactId;
  final String? contactName;
  final String? contactPhone;
  final String? notes;

  /// Minutes before [dueDate]; null means no reminder.
  final int? reminderMinutes;

  bool get isDone => status == 'done';

  String? get leadId => lead?.id;

  /// Who the task is about when it has no lead: the company or the contact.
  String? get party => companyName ?? contactName;

  /// [me] is the user's membership id; [now] fixes "today" for the day
  /// count.
  factory Task.fromJson(
    Map<String, dynamic> json, {
    String? me,
    DateTime? now,
  }) {
    final due = jsonDate(json['dueAt']);
    final status = json['status'] as String? ?? 'open';
    final days = due == null ? null : _daysFrom(now ?? DateTime.now(), due);
    final assigneeId = jsonId(json['assigneeMembershipId']);
    final leadId = jsonId(json['leadId']);
    final remind = jsonInt(json['remindMin']);
    return Task(
      id: jsonId(json['id']) ?? '',
      title: json['title'] as String? ?? '',
      type: TaskType.fromWire(json['type'] as String?),
      status: status,
      dueDate: due,
      isOverdue: status != 'done' && days != null && days < 0,
      daysUntilDue: days,
      assignedTo: assigneeId == null
          ? null
          : TaskPerson(id: assigneeId, name: json['assigneeName'] as String?),
      assignedToMe: me != null && assigneeId == me,
      createdById: jsonId(json['createdBy']),
      createdOn: jsonDate(json['createdAt']),
      completedOn: jsonDate(json['doneAt']),
      lead: leadId == null
          ? null
          : TaskLeadRef(
              id: leadId,
              name: json['leadName'] as String?,
              phone: json['leadPhone'] as String?,
            ),
      companyId: jsonId(json['companyId']),
      companyName: json['companyName'] as String?,
      contactId: jsonId(json['contactId']),
      contactName: json['contactName'] as String?,
      contactPhone: json['contactPhone'] as String?,
      notes: json['note'] as String?,
      reminderMinutes: remind == null || remind <= 0 ? null : remind,
    );
  }

  static int _daysFrom(DateTime now, DateTime due) {
    final today = AppDateUtils.dateOnly(now);
    return DateTime.utc(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  }

  /// A copy marked done before the server confirms, for an instant tick in
  /// the list.
  Task asDone() => Task(
    id: id,
    title: title,
    type: type,
    status: 'done',
    dueDate: dueDate,
    daysUntilDue: daysUntilDue,
    assignedTo: assignedTo,
    assignedToMe: assignedToMe,
    createdById: createdById,
    createdOn: createdOn,
    completedOn: completedOn,
    lead: lead,
    companyId: companyId,
    companyName: companyName,
    contactId: contactId,
    contactName: contactName,
    contactPhone: contactPhone,
    notes: notes,
    reminderMinutes: reminderMinutes,
  );
}

/// The tabs of the task list (#34), by the server's `view`. This week is
/// the open tasks due in the seven days after today.
enum TaskBucket {
  today('today'),
  overdue('overdue'),
  week('upcoming'),
  all(null),
  done('done');

  const TaskBucket(this.view);

  final String? view;
}

/// How many tasks each tab holds.
class TaskCounts {
  const TaskCounts({
    this.today = 0,
    this.overdue = 0,
    this.week = 0,
    this.all = 0,
    this.done = 0,
  });

  final int today;
  final int overdue;
  final int week;
  final int all;
  final int done;

  int of(TaskBucket bucket) => switch (bucket) {
    TaskBucket.today => today,
    TaskBucket.overdue => overdue,
    TaskBucket.week => week,
    TaskBucket.all => all,
    TaskBucket.done => done,
  };
}

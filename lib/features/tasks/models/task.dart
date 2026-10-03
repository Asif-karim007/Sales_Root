import 'package:salesroot/core/utils/json_fields.dart';

/// What a task asks for. The ids are the server's `TypeId`s.
enum TaskType {
  call(1),
  visit(2),
  followUp(3),
  meeting(4),
  quotation(5),
  collection(6),
  own(7);

  const TaskType(this.id);

  final int id;

  static TaskType fromId(int? id) =>
      values.firstWhere((type) => type.id == id, orElse: () => own);
}

class TaskStatusRef {
  const TaskStatusRef({this.id, this.name, this.isDone = false});

  static const openId = 1;
  static const doneId = 2;

  final int? id;
  final String? name;
  final bool isDone;

  factory TaskStatusRef.fromJson(Map<String, dynamic> json) => TaskStatusRef(
    id: jsonInt(json['Id']),
    name: json['Name'] as String?,
    isDone: jsonBool(json['IsDone']),
  );

  Map<String, dynamic> toJson() => {'Id': id, 'Name': name, 'IsDone': isDone};
}

class TaskPerson {
  const TaskPerson({this.id, this.name, this.nameBn});

  final int? id;
  final String? name;
  final String? nameBn;

  String label(bool bangla) =>
      LocalizedName(name ?? '', nameBn ?? '').of(bangla);

  factory TaskPerson.fromJson(Map<String, dynamic> json) => TaskPerson(
    id: jsonInt(json['Id']),
    name: json['Name'] as String?,
    nameBn: json['NameBn'] as String?,
  );

  Map<String, dynamic> toJson() => {'Id': id, 'Name': name, 'NameBn': nameBn};
}

/// The lead a task belongs to, with what the detail screen shows about it.
class TaskLeadRef {
  const TaskLeadRef({
    this.id,
    this.name,
    this.stage,
    this.contactName,
    this.contactPhone,
  });

  final int? id;
  final String? name;
  final LocalizedName? stage;
  final String? contactName;
  final String? contactPhone;

  factory TaskLeadRef.fromJson(Map<String, dynamic> json) => TaskLeadRef(
    id: jsonInt(json['Id']),
    name: json['Name'] as String?,
    stage: json['StageName'] == null
        ? null
        : LocalizedName(
            json['StageName'] as String? ?? '',
            json['StageNameBn'] as String? ?? '',
          ),
    contactName: json['ContactName'] as String?,
    contactPhone: json['ContactPhone'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    'StageName': stage?.en,
    'StageNameBn': stage?.bn,
    'ContactName': contactName,
    'ContactPhone': contactPhone,
  }..removeWhere((_, value) => value == null);
}

/// One task. `IsOverdue` and `DaysUntilDue` come from the server, so the
/// screens never compare a due date with the phone's clock.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.status = const TaskStatusRef(),
    this.dueDate,
    this.isOverdue = false,
    this.daysUntilDue,
    this.assignedTo,
    this.assignedToMe = false,
    this.createdBy,
    this.createdOn,
    this.completedOn,
    this.lead,
    this.amount,
    this.notes,
    this.reminderMinutes,
    this.canEdit = false,
    this.canDelete = false,
  });

  final int id;
  final String title;
  final TaskType type;
  final String? description;
  final TaskStatusRef status;
  final DateTime? dueDate;
  final bool isOverdue;
  final int? daysUntilDue;
  final TaskPerson? assignedTo;
  final bool assignedToMe;
  final TaskPerson? createdBy;
  final DateTime? createdOn;
  final DateTime? completedOn;
  final TaskLeadRef? lead;
  final int? amount;
  final String? notes;

  /// Minutes before [dueDate]; null means no reminder.
  final int? reminderMinutes;
  final bool canEdit;
  final bool canDelete;

  bool get isDone => status.isDone;

  int? get leadId => lead?.id;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: jsonInt(json['Id']) ?? 0,
    title: json['Title'] as String? ?? '',
    type: TaskType.fromId(jsonInt(json['TypeId'])),
    description: json['Description'] as String?,
    status:
        jsonObject(json['Status'], TaskStatusRef.fromJson) ??
        const TaskStatusRef(),
    dueDate: jsonDate(json['DueDate']),
    isOverdue: jsonBool(json['IsOverdue']),
    daysUntilDue: jsonInt(json['DaysUntilDue']),
    assignedTo: jsonObject(json['AssignedTo'], TaskPerson.fromJson),
    assignedToMe: jsonBool(json['AssignedToMe']),
    createdBy: jsonObject(json['CreatedBy'], TaskPerson.fromJson),
    createdOn: jsonDate(json['CreatedOn']),
    completedOn: jsonDate(json['CompletedOn']),
    lead: jsonObject(json['Lead'], TaskLeadRef.fromJson),
    amount: jsonInt(json['Amount']),
    notes: json['Notes'] as String?,
    reminderMinutes: jsonInt(json['ReminderMinutes']),
    canEdit: jsonBool(json['CanEdit']),
    canDelete: jsonBool(json['CanDelete']),
  );

  /// A copy marked done or open before the server confirms, for an instant
  /// tick in the list.
  Task withDone(bool done) => Task(
    id: id,
    title: title,
    type: type,
    description: description,
    status: TaskStatusRef(
      id: done ? TaskStatusRef.doneId : TaskStatusRef.openId,
      name: status.name,
      isDone: done,
    ),
    dueDate: dueDate,
    isOverdue: !done && (daysUntilDue ?? 0) < 0,
    daysUntilDue: daysUntilDue,
    assignedTo: assignedTo,
    assignedToMe: assignedToMe,
    createdBy: createdBy,
    createdOn: createdOn,
    completedOn: done ? completedOn : null,
    lead: lead,
    amount: amount,
    notes: notes,
    reminderMinutes: reminderMinutes,
    canEdit: canEdit,
    canDelete: canDelete,
  );
}

/// The tabs of the task list (#34).
enum TaskBucket {
  today('Today'),
  overdue('Overdue'),
  week('Week'),
  all('All'),
  done('Done');

  const TaskBucket(this.wire);

  final String wire;
}

/// How many tasks each tab holds. [today] counts what is due today and still
/// open.
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

  factory TaskCounts.fromJson(Map<String, dynamic> json) => TaskCounts(
    today: jsonInt(json['Today']) ?? 0,
    overdue: jsonInt(json['Overdue']) ?? 0,
    week: jsonInt(json['Week']) ?? 0,
    all: jsonInt(json['All']) ?? 0,
    done: jsonInt(json['Done']) ?? 0,
  );
}

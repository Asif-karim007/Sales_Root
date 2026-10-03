import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';

enum LeadTemperature {
  hot('Hot'),
  warm('Warm'),
  cold('Cold');

  const LeadTemperature(this.wire);

  final String wire;

  static LeadTemperature? fromWire(String? value) {
    for (final temperature in values) {
      if (temperature.wire == value) return temperature;
    }
    return null;
  }
}

class LeadPersonRef {
  const LeadPersonRef({this.id, required this.name});

  final int? id;
  final LocalizedName name;

  factory LeadPersonRef.fromJson(Map<String, dynamic> json) => LeadPersonRef(
    id: jsonInt(json['Id']),
    name: LocalizedName.fromJson(json),
  );
}

class LeadCompany {
  const LeadCompany({
    this.id,
    required this.name,
    this.industry,
    this.area,
    this.contactCount = 0,
  });

  /// Null for a company typed on the lead that is not in the company list.
  final int? id;
  final String name;
  final String? industry;
  final LocalizedName? area;
  final int contactCount;

  factory LeadCompany.fromJson(Map<String, dynamic> json) => LeadCompany(
    id: jsonInt(json['Id']),
    name: json['Name'] as String? ?? '',
    industry: json['Industry'] as String?,
    area: jsonObject(json['Area'], LocalizedName.fromJson),
    contactCount: jsonInt(json['ContactCount']) ?? 0,
  );
}

/// A contact person on the lead. [id] is the contact record; it is null for
/// a person typed on the lead only.
class LeadContact {
  const LeadContact({
    this.id,
    required this.name,
    this.designation,
    this.mobile,
    this.email,
    this.isPrimary = false,
  });

  final int? id;
  final String name;
  final String? designation;
  final String? mobile;
  final String? email;
  final bool isPrimary;

  factory LeadContact.fromJson(Map<String, dynamic> json) => LeadContact(
    id: jsonInt(json['Id']),
    name: json['Name'] as String? ?? '',
    designation: json['Designation'] as String?,
    mobile: json['Mobile'] as String?,
    email: json['Email'] as String?,
    isPrimary: jsonBool(json['IsPrimary']),
  );
}

class LeadStageRef {
  const LeadStageRef({
    required this.id,
    required this.name,
    this.changedOn,
    this.isWon = false,
    this.isLost = false,
  });

  final int id;
  final LocalizedName name;
  final DateTime? changedOn;
  final bool isWon;
  final bool isLost;

  factory LeadStageRef.fromJson(Map<String, dynamic> json) => LeadStageRef(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    changedOn: jsonDate(json['ChangedOn']),
    isWon: jsonBool(json['IsWon']),
    isLost: jsonBool(json['IsLost']),
  );

  factory LeadStageRef.of(LeadStage stage) => LeadStageRef(
    id: stage.id,
    name: stage.name,
    isWon: stage.isWon,
    isLost: stage.isLost,
  );
}

class LeadQuotation {
  const LeadQuotation({this.id, this.code, this.amount, this.date});

  final int? id;
  final String? code;
  final double? amount;
  final DateTime? date;

  factory LeadQuotation.fromJson(Map<String, dynamic> json) => LeadQuotation(
    id: jsonInt(json['Id']),
    code: json['Code'] as String?,
    amount: jsonDouble(json['Amount']),
    date: jsonDate(json['Date']),
  );
}

class LeadWinLoss {
  const LeadWinLoss({this.causeId, this.cause, this.note});

  final int? causeId;
  final LocalizedName? cause;
  final String? note;

  factory LeadWinLoss.fromJson(Map<String, dynamic> json) => LeadWinLoss(
    causeId: jsonInt(json['CauseId']),
    cause: jsonObject(json['Cause'], LocalizedName.fromJson),
    note: json['Note'] as String?,
  );
}

/// One lead. List rows carry everything but [timeline], which only the
/// detail response fills. [isDueToday], [isOverdue], [isStalled],
/// [daysToClose] and [daysInStage] are worked out by the server.
class Lead {
  const Lead({
    required this.id,
    this.code,
    this.leadName = '',
    this.createdOn,
    this.updatedOn,
    this.company,
    this.stage,
    this.assignedTo,
    this.createdBy,
    this.sharedWith = const [],
    this.estimatedAmount,
    this.estimatedClosingDate,
    this.daysToClose,
    this.winProbability = 0,
    this.temperature,
    this.source,
    this.tags = const [],
    this.interests = const [],
    this.primaryContact,
    this.contacts = const [],
    this.lastQuotation,
    this.winLoss,
    this.nextTaskId,
    this.nextTaskTitle,
    this.nextTaskType,
    this.nextTaskAt,
    this.isDueToday = false,
    this.isOverdue = false,
    this.isStalled = false,
    this.daysInStage,
    this.lastActivityOn,
    this.comments,
    this.canEdit = false,
    this.canDelete = false,
    this.timeline = const [],
  });

  final int id;
  final String? code;
  final String leadName;
  final DateTime? createdOn;
  final DateTime? updatedOn;
  final LeadCompany? company;
  final LeadStageRef? stage;
  final LeadPersonRef? assignedTo;
  final LeadPersonRef? createdBy;
  final List<LeadPersonRef> sharedWith;
  final double? estimatedAmount;
  final DateTime? estimatedClosingDate;
  final int? daysToClose;
  final int winProbability;
  final LeadTemperature? temperature;
  final LeadOption? source;
  final List<LeadOption> tags;
  final List<LeadOption> interests;
  final LeadContact? primaryContact;
  final List<LeadContact> contacts;
  final LeadQuotation? lastQuotation;
  final LeadWinLoss? winLoss;
  final int? nextTaskId;
  final String? nextTaskTitle;
  final LeadActivityKind? nextTaskType;
  final DateTime? nextTaskAt;
  final bool isDueToday;
  final bool isOverdue;
  final bool isStalled;
  final int? daysInStage;
  final DateTime? lastActivityOn;
  final String? comments;
  final bool canEdit;
  final bool canDelete;
  final List<LeadActivity> timeline;

  bool get isWon => stage?.isWon ?? false;
  bool get isLost => stage?.isLost ?? false;
  bool get isOpen => !isWon && !isLost;
  bool get hasNextTask => nextTaskAt != null || nextTaskTitle != null;

  String? get phone {
    final mobile = primaryContact?.mobile?.trim() ?? '';
    return mobile.isEmpty ? null : mobile;
  }

  String? get email {
    final email = primaryContact?.email?.trim() ?? '';
    return email.isEmpty ? null : email;
  }

  /// The same lead in [stage], as the list shows it while the move is saved.
  Lead movedTo(LeadStage stage) => Lead(
    id: id,
    code: code,
    leadName: leadName,
    createdOn: createdOn,
    updatedOn: updatedOn,
    company: company,
    stage: LeadStageRef.of(stage),
    assignedTo: assignedTo,
    createdBy: createdBy,
    sharedWith: sharedWith,
    estimatedAmount: estimatedAmount,
    estimatedClosingDate: estimatedClosingDate,
    daysToClose: daysToClose,
    winProbability: stage.winProbability,
    temperature: temperature,
    source: source,
    tags: tags,
    interests: interests,
    primaryContact: primaryContact,
    contacts: contacts,
    lastQuotation: lastQuotation,
    winLoss: winLoss,
    nextTaskId: nextTaskId,
    nextTaskTitle: nextTaskTitle,
    nextTaskType: nextTaskType,
    nextTaskAt: nextTaskAt,
    isDueToday: isDueToday,
    isOverdue: isOverdue,
    isStalled: isStalled,
    daysInStage: 0,
    lastActivityOn: lastActivityOn,
    comments: comments,
    canEdit: canEdit,
    canDelete: canDelete,
    timeline: timeline,
  );

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
    id: jsonInt(json['Id']) ?? 0,
    code: json['Code'] as String?,
    leadName: json['LeadName'] as String? ?? '',
    createdOn: jsonDate(json['CreatedOn']),
    updatedOn: jsonDate(json['UpdatedOn']),
    company: jsonObject(json['Company'], LeadCompany.fromJson),
    stage: jsonObject(json['Stage'], LeadStageRef.fromJson),
    assignedTo: jsonObject(json['AssignedTo'], LeadPersonRef.fromJson),
    createdBy: jsonObject(json['CreatedBy'], LeadPersonRef.fromJson),
    sharedWith: jsonList(json['SharedWith'], LeadPersonRef.fromJson),
    estimatedAmount: jsonDouble(json['EstimatedAmount']),
    estimatedClosingDate: jsonDate(json['EstimatedClosingDate']),
    daysToClose: jsonInt(json['DaysToClose']),
    winProbability: jsonInt(json['WinProbability']) ?? 0,
    temperature: LeadTemperature.fromWire(json['Temperature'] as String?),
    source: jsonObject(json['Source'], LeadOption.fromJson),
    tags: jsonList(json['Tags'], LeadOption.fromJson),
    interests: jsonList(json['Interests'], LeadOption.fromJson),
    primaryContact: jsonObject(json['PrimaryContact'], LeadContact.fromJson),
    contacts: jsonList(json['Contacts'], LeadContact.fromJson),
    lastQuotation: jsonObject(json['LastQuotation'], LeadQuotation.fromJson),
    winLoss: jsonObject(json['WinLoss'], LeadWinLoss.fromJson),
    nextTaskId: jsonInt(json['NextTaskId']),
    nextTaskTitle: json['NextTaskTitle'] as String?,
    nextTaskType: LeadActivityKind.fromWire(json['NextTaskType'] as String?),
    nextTaskAt: jsonDate(json['NextTaskAt']),
    isDueToday: jsonBool(json['IsDueToday']),
    isOverdue: jsonBool(json['IsOverdue']),
    isStalled: jsonBool(json['IsStalled']),
    daysInStage: jsonInt(json['DaysInStage']),
    lastActivityOn: jsonDate(json['LastActivityOn']),
    comments: json['Comments'] as String?,
    canEdit: jsonBool(json['CanEdit']),
    canDelete: jsonBool(json['CanDelete']),
    timeline: jsonList(json['Timeline'], LeadActivity.fromJson),
  );
}

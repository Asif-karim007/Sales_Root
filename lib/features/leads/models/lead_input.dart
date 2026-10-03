import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';

/// A person typed on the lead rather than picked from the contact list.
class LeadNewContact {
  const LeadNewContact({
    required this.name,
    this.mobile,
    this.email,
    this.designation,
  });

  final String name;
  final String? mobile;
  final String? email;
  final String? designation;

  bool get isEmpty =>
      name.trim().isEmpty &&
      (mobile?.trim() ?? '').isEmpty &&
      (email?.trim() ?? '').isEmpty;

  Map<String, dynamic> toJson() => {
    'Name': name.trim(),
    'Mobile': _text(mobile),
    'Email': _text(email),
    'Designation': _text(designation),
  }..removeWhere((_, v) => v == null);
}

/// The next task to set when saving a lead or an activity.
class LeadFollowUp {
  const LeadFollowUp({required this.kind, required this.at, this.title});

  final LeadActivityKind kind;
  final DateTime at;
  final String? title;

  Map<String, dynamic> toJson() =>
      {'Type': kind.wire, 'At': jsonUtc(at), 'Title': _text(title)}
        ..removeWhere((_, v) => v == null);
}

/// The create and edit body. An edit sends every field, so it starts from
/// [LeadInput.fromLead].
class LeadInput {
  const LeadInput({
    required this.leadName,
    this.companyId,
    this.companyName,
    this.contactIds = const [],
    this.newContact,
    this.estimatedAmount,
    this.estimatedClosingDate,
    this.sourceId,
    this.stageId,
    this.assignedToEmployeeId,
    this.temperature,
    this.tagIds = const [],
    this.interestIds = const [],
    this.comments,
    this.followUp,
    this.allowDuplicate = false,
  });

  final String leadName;
  final int? companyId;

  /// A company that is not in the list yet.
  final String? companyName;
  final List<int> contactIds;
  final LeadNewContact? newContact;
  final double? estimatedAmount;
  final DateTime? estimatedClosingDate;
  final int? sourceId;
  final int? stageId;
  final int? assignedToEmployeeId;
  final LeadTemperature? temperature;
  final List<int> tagIds;
  final List<int> interestIds;
  final String? comments;
  final LeadFollowUp? followUp;

  /// Saves even though the phone or company matches another lead.
  final bool allowDuplicate;

  factory LeadInput.fromLead(Lead lead) {
    final typed = lead.primaryContact;
    return LeadInput(
      leadName: lead.leadName,
      companyId: lead.company?.id,
      companyName: lead.company?.id == null ? lead.company?.name : null,
      contactIds: [for (final contact in lead.contacts) ?contact.id],
      newContact: typed != null && typed.id == null
          ? LeadNewContact(
              name: typed.name,
              mobile: typed.mobile,
              email: typed.email,
              designation: typed.designation,
            )
          : null,
      estimatedAmount: lead.estimatedAmount,
      estimatedClosingDate: lead.estimatedClosingDate,
      sourceId: lead.source?.id,
      stageId: lead.stage?.id,
      assignedToEmployeeId: lead.assignedTo?.id,
      temperature: lead.temperature,
      tagIds: [for (final tag in lead.tags) tag.id],
      interestIds: [for (final interest in lead.interests) interest.id],
      comments: lead.comments,
    );
  }

  /// The same input moved to [company], dropping contacts of the old one.
  LeadInput withCompany(LeadLookupCompany company) => LeadInput(
    leadName: leadName,
    companyId: company.id,
    newContact: newContact,
    estimatedAmount: estimatedAmount,
    estimatedClosingDate: estimatedClosingDate,
    sourceId: sourceId,
    stageId: stageId,
    assignedToEmployeeId: assignedToEmployeeId,
    temperature: temperature,
    tagIds: tagIds,
    interestIds: interestIds,
    comments: comments,
  );

  LeadInput allowingDuplicate() => LeadInput(
    leadName: leadName,
    companyId: companyId,
    companyName: companyName,
    contactIds: contactIds,
    newContact: newContact,
    estimatedAmount: estimatedAmount,
    estimatedClosingDate: estimatedClosingDate,
    sourceId: sourceId,
    stageId: stageId,
    assignedToEmployeeId: assignedToEmployeeId,
    temperature: temperature,
    tagIds: tagIds,
    interestIds: interestIds,
    comments: comments,
    followUp: followUp,
    allowDuplicate: true,
  );

  Map<String, dynamic> toJson() {
    final contact = newContact;
    return {
      'LeadName': leadName.trim(),
      'CompanyId': companyId,
      'CompanyName': _text(companyName),
      'ContactIds': contactIds,
      'NewContact': contact == null || contact.isEmpty
          ? null
          : contact.toJson(),
      'EstimatedAmount': estimatedAmount,
      'EstimatedClosingDate': jsonUtc(estimatedClosingDate),
      'SourceId': sourceId,
      'StageId': stageId,
      'AssignedToEmployeeId': assignedToEmployeeId,
      'Temperature': temperature?.wire,
      'TagIds': tagIds,
      'InterestIds': interestIds,
      'Comments': _text(comments),
      'FollowUp': followUp?.toJson(),
      'AllowDuplicate': allowDuplicate ? true : null,
    }..removeWhere((_, v) => v == null);
  }
}

/// The body for logging a call, meeting, visit, note or message.
class LeadActivityInput {
  const LeadActivityInput({
    required this.kind,
    required this.occurredOn,
    this.durationMinutes,
    this.description,
    this.outcome,
    this.followUp,
    this.photoCount = 0,
  });

  final LeadActivityKind kind;
  final DateTime occurredOn;
  final int? durationMinutes;
  final String? description;
  final CallOutcome? outcome;
  final LeadFollowUp? followUp;
  final int photoCount;

  Map<String, dynamic> toJson() => {
    'Kind': kind.wire,
    'OccurredOn': jsonUtc(occurredOn),
    'DurationMinutes': durationMinutes,
    'Description': _text(description),
    'ActivityOutcome': outcome?.wire,
    'FollowUp': followUp?.toJson(),
    'PhotoCount': photoCount == 0 ? null : photoCount,
  }..removeWhere((_, v) => v == null);
}

class LeadStageInput {
  const LeadStageInput({required this.stageId, this.lostReasonId, this.note});

  final int stageId;
  final int? lostReasonId;
  final String? note;

  Map<String, dynamic> toJson() =>
      {'StageId': stageId, 'WinLossCauseId': lostReasonId, 'Note': _text(note)}
        ..removeWhere((_, v) => v == null);
}

/// A saved stage change. [moveId] undoes it.
class LeadStageMove {
  const LeadStageMove({
    required this.moveId,
    required this.fromStageId,
    required this.lead,
  });

  final int moveId;
  final int fromStageId;
  final Lead lead;

  factory LeadStageMove.fromJson(Map<String, dynamic> json) => LeadStageMove(
    moveId: jsonInt(json['MoveId']) ?? 0,
    fromStageId: jsonInt(json['FromStageId']) ?? 0,
    lead: Lead.fromJson(json['Lead'] as Map<String, dynamic>? ?? const {}),
  );
}

enum LeadDuplicateField { phone, company }

/// The 409 a create answers when the phone or company is already on a lead.
class LeadDuplicateFailure extends ApiFailure {
  const LeadDuplicateFailure({required this.existing, required this.field})
    : super(409, 'Possible duplicate');

  final Lead existing;
  final LeadDuplicateField field;
}

/// A Bangladeshi mobile number, local (01XXXXXXXXX) or with 880 in front.
bool isLeadMobile(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final local = digits.startsWith('880') ? digits.substring(2) : digits;
  return RegExp(r'^01[3-9]\d{8}$').hasMatch(local);
}

String? _text(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';

/// The next follow-up to set when saving a lead or an activity. [kind] is how
/// the user said they would follow up; the server keeps the time only.
class LeadFollowUp {
  const LeadFollowUp({required this.kind, required this.at});

  final LeadActivityKind kind;
  final DateTime at;
}

/// The create and edit body. An edit starts from [LeadInput.fromLead]; the
/// repository moves the stage and the owner with their own calls when they
/// change.
class LeadInput {
  const LeadInput({
    required this.leadName,
    this.phone,
    this.title,
    this.companyId,
    this.companyName,
    this.contactId,
    this.estimatedAmount,
    this.estimatedClosingDate,
    this.source,
    this.stageId,
    this.ownerId,
    this.temperature,
    this.tags = const [],
    this.custom = const {},
    this.note,
    this.followUp,
    this.allowDuplicate = false,
  });

  final String leadName;
  final String? phone;
  final String? title;
  final String? companyId;

  /// A company that is not in the list yet; it is created with the lead.
  final String? companyName;
  final String? contactId;
  final double? estimatedAmount;
  final DateTime? estimatedClosingDate;
  final String? source;
  final String? stageId;

  /// Another member to hand the lead to; null keeps the current owner.
  final String? ownerId;
  final LeadTemperature? temperature;
  final List<String> tags;
  final Map<String, String> custom;

  /// Saved as the first note on a new lead.
  final String? note;
  final LeadFollowUp? followUp;

  /// Saves even though the phone is already on another lead.
  final bool allowDuplicate;

  factory LeadInput.fromLead(Lead lead) => LeadInput(
    leadName: lead.leadName,
    phone: lead.phone,
    title: lead.title,
    companyId: lead.company?.id,
    contactId: lead.contact?.id,
    estimatedAmount: lead.estimatedAmount,
    estimatedClosingDate: lead.estimatedClosingDate,
    source: lead.source,
    stageId: lead.stage?.id,
    ownerId: lead.assignedTo?.id,
    temperature: lead.temperature,
    tags: lead.tags,
    custom: {
      for (final entry in lead.custom.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    },
  );

  LeadInput withCompany(String companyId) => _copy(companyId: companyId);

  LeadInput allowingDuplicate() => _copy(allowDuplicate: true);

  LeadInput _copy({String? companyId, bool? allowDuplicate}) => LeadInput(
    leadName: leadName,
    phone: phone,
    title: title,
    companyId: companyId ?? this.companyId,
    companyName: companyId == null ? companyName : null,
    contactId: companyId == null ? contactId : null,
    estimatedAmount: estimatedAmount,
    estimatedClosingDate: estimatedClosingDate,
    source: source,
    stageId: stageId,
    ownerId: ownerId,
    temperature: temperature,
    tags: tags,
    custom: custom,
    note: note,
    followUp: followUp,
    allowDuplicate: allowDuplicate ?? this.allowDuplicate,
  );

  Map<String, dynamic> _fields() => {
    'name': leadName.trim(),
    'phone': _text(phone),
    'title': _text(title),
    'companyId': companyId,
    'contactId': contactId,
    'amount': estimatedAmount,
    'temperature': temperature?.wire,
    'nextFollowUp': jsonUtc(followUp?.at),
    'expectedClose': _day(estimatedClosingDate),
    'custom': custom.isEmpty ? null : custom,
    'tags': tags,
  };

  /// `POST leads`; [companyId] is the company created for [companyName].
  Map<String, dynamic> toCreateJson({String? companyId}) => {
    ..._fields(),
    'companyId': companyId ?? this.companyId,
    'stageId': stageId,
    'source': _text(source),
    'allowDuplicate': allowDuplicate ? true : null,
  }..removeWhere((_, v) => v == null);

  /// `PATCH leads/{id}`.
  Map<String, dynamic> toUpdateJson() =>
      _fields()..removeWhere((_, v) => v == null);
}

/// The body for logging a call, visit, note or message.
class LeadActivityInput {
  const LeadActivityInput({
    required this.kind,
    required this.occurredOn,
    this.durationMinutes,
    this.description,
    this.outcome,
    this.followUpAt,
  });

  final LeadActivityKind kind;
  final DateTime occurredOn;
  final int? durationMinutes;
  final String? description;
  final CallOutcome? outcome;
  final DateTime? followUpAt;

  Map<String, dynamic> toJson(String leadId) {
    final minutes = durationMinutes;
    return {
      'type': kind.wire,
      'leadId': leadId,
      'occurredAt': jsonUtc(occurredOn),
      'durationSec': minutes == null ? null : minutes * 60,
      'body': _text(description),
      'outcome': outcome?.wire,
      'nextFollowUp': jsonUtc(followUpAt),
    }..removeWhere((_, v) => v == null);
  }
}

/// A stage move. [stage] decides the call: Lost takes a [lostReason], Won an
/// [amount], and a lead that is lost or won is reopened first. [amount] and
/// [custom] fill what the stage requires.
class LeadStageInput {
  const LeadStageInput({
    required this.stage,
    this.lostReason,
    this.note,
    this.amount,
    this.custom = const {},
  });

  final LeadStage stage;
  final String? lostReason;
  final String? note;
  final double? amount;
  final Map<String, String> custom;
}

/// A saved stage change: the lead [before] it, for undo, and [lead] after.
class LeadStageMove {
  const LeadStageMove({required this.before, required this.lead});

  final Lead before;
  final Lead lead;
}

/// The 422 a create answers when the phone is already on a lead.
class LeadDuplicateFailure extends ApiFailure {
  const LeadDuplicateFailure({required this.existing, required String message})
    : super(422, message, code: duplicateCode);

  static const duplicateCode = 'V-003';

  final Lead existing;
}

/// A Bangladeshi mobile number, local (01XXXXXXXXX) or with 880 in front.
bool isLeadMobile(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final local = digits.startsWith('880') ? digits.substring(2) : digits;
  return RegExp(r'^01[3-9]\d{8}$').hasMatch(local);
}

String? _day(DateTime? value) =>
    value == null ? null : AppDateUtils.toApiDateOnly(value);

String? _text(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}

import 'package:salesroot/core/utils/json_fields.dart';

enum InboxSource {
  facebook('Facebook'),
  website('Website'),
  whatsapp('WhatsApp'),
  messenger('Messenger'),
  sms('SMS'),
  call('Phone call');

  const InboxSource(this.wire);

  final String wire;

  static InboxSource fromWire(String? value) => values.firstWhere(
    (source) => source.wire == value,
    orElse: () => InboxSource.website,
  );
}

enum InboxStatus {
  fresh('New'),
  assigned('Assigned'),
  accepted('Accepted'),
  rejected('Rejected');

  const InboxStatus(this.wire);

  final String wire;

  static InboxStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => InboxStatus.fresh,
  );
}

enum RejectReason {
  spam('Spam'),
  wrongNumber('WrongNumber'),
  notInterested('NotInterested'),
  duplicate('Duplicate'),
  outOfArea('OutOfArea');

  const RejectReason(this.wire);

  final String wire;
}

/// A member's `<prefix>Name` / `<prefix>NameBn` pair, or null.
LocalizedName? jsonMemberName(Map<String, dynamic> json, String prefix) =>
    jsonLocalized(json, '${prefix}Name');

/// The `<key>` / `<key>Bn` pair, or null.
LocalizedName? jsonLocalized(Map<String, dynamic> json, String key) {
  final name = json[key];
  if (name is! String) return null;
  return LocalizedName(name, json['${key}Bn'] as String? ?? '');
}

/// A form answer, labelled in both languages.
class InboxAnswer {
  const InboxAnswer({required this.label, required this.value});

  final LocalizedName label;
  final String value;

  factory InboxAnswer.fromJson(Map<String, dynamic> json) => InboxAnswer(
    label: LocalizedName.fromJson(json),
    value: json['Value'] as String? ?? '',
  );
}

enum DuplicateKind {
  customer('Customer'),
  lead('Lead'),
  contact('Contact');

  const DuplicateKind(this.wire);

  final String wire;

  static DuplicateKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => DuplicateKind.contact,
  );
}

/// An existing record that already has this number.
class InboxDuplicate {
  const InboxDuplicate({
    required this.kind,
    required this.id,
    required this.name,
    this.companyId,
    this.companyName,
  });

  final DuplicateKind kind;
  final int id;
  final String name;
  final int? companyId;
  final String? companyName;

  factory InboxDuplicate.fromJson(Map<String, dynamic> json) => InboxDuplicate(
    kind: DuplicateKind.fromWire(json['Kind'] as String?),
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    companyId: jsonInt(json['CompanyId']),
    companyName: json['CompanyName'] as String?,
  );
}

/// A lead that arrived from a channel and waits to be accepted into the
/// main list.
class InboxLead {
  InboxLead({
    required this.id,
    required this.name,
    required this.phone,
    required this.source,
    required this.status,
    required this.waitingAtFetch,
    this.email,
    this.company,
    this.area,
    this.interest,
    this.formName,
    this.campaign,
    this.answers = const [],
    this.consentAt,
    this.externalId,
    this.receivedAt,
    this.assignedToId,
    this.assignedTo,
    this.assignedByRule,
    this.duplicate,
    this.slaMinutes = 15,
    this.canEdit = true,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? company;
  final LocalizedName? area;
  final InboxSource source;
  final InboxStatus status;

  /// What they asked about, in their words or the form's.
  final String? interest;
  final String? formName;
  final String? campaign;
  final List<InboxAnswer> answers;
  final DateTime? consentAt;
  final String? externalId;
  final DateTime? receivedAt;
  final int? assignedToId;
  final LocalizedName? assignedTo;
  final String? assignedByRule;
  final InboxDuplicate? duplicate;
  final int slaMinutes;
  final bool canEdit;

  /// How long it had waited when the server answered. The timer adds the
  /// time since [fetchedAt], so the server clock is never compared to ours.
  final Duration waitingAtFetch;
  final DateTime fetchedAt;

  bool get isOpen =>
      status == InboxStatus.fresh || status == InboxStatus.assigned;

  Duration waiting([DateTime? now]) =>
      waitingAtFetch + (now ?? DateTime.now()).difference(fetchedAt);

  bool isLate([DateTime? now]) =>
      status == InboxStatus.fresh && waiting(now).inMinutes >= slaMinutes;

  factory InboxLead.fromJson(Map<String, dynamic> json) => InboxLead(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    phone: json['Phone'] as String? ?? '',
    email: json['Email'] as String?,
    company: json['Company'] as String?,
    area: jsonLocalized(json, 'Area'),
    source: InboxSource.fromWire(json['Source'] as String?),
    status: InboxStatus.fromWire(json['Status'] as String?),
    interest: json['Interest'] as String?,
    formName: json['FormName'] as String?,
    campaign: json['Campaign'] as String?,
    answers: jsonList(json['Answers'], InboxAnswer.fromJson),
    consentAt: jsonDate(json['ConsentAt']),
    externalId: json['ExternalId'] as String?,
    receivedAt: jsonDate(json['ReceivedAt']),
    waitingAtFetch: Duration(seconds: jsonInt(json['WaitingSeconds']) ?? 0),
    assignedToId: jsonInt(json['AssignedToId']),
    assignedTo: jsonMemberName(json, 'AssignedTo'),
    assignedByRule: json['AssignedByRule'] as String?,
    duplicate: jsonObject(json['Duplicate'], InboxDuplicate.fromJson),
    slaMinutes: jsonInt(json['SlaMinutes']) ?? 15,
    canEdit: json['CanEdit'] != false,
  );
}

enum InboxFilter {
  all('All'),
  unassigned('Unassigned'),
  mine('Mine'),
  late('Late'),
  facebook('Facebook'),
  website('Website'),
  whatsapp('WhatsApp');

  const InboxFilter(this.wire);

  final String wire;
}

/// Where an inbox lead would go under the current distribution rules.
class AssigneeSuggestion {
  const AssigneeSuggestion({
    this.ruleId,
    this.ruleName,
    this.memberId,
    this.memberName,
  });

  final int? ruleId;
  final String? ruleName;
  final int? memberId;
  final LocalizedName? memberName;

  bool get toQueue => memberId == null;

  factory AssigneeSuggestion.fromJson(Map<String, dynamic> json) =>
      AssigneeSuggestion(
        ruleId: jsonInt(json['RuleId']),
        ruleName: json['RuleName'] as String?,
        memberId: jsonInt(json['MemberId']),
        memberName: jsonMemberName(json, 'Member'),
      );
}

class AcceptInput {
  const AcceptInput({
    required this.stageId,
    this.assignToId,
    this.contactId,
    this.followUp = true,
  });

  /// Null lets the distribution rules decide.
  final int? assignToId;
  final int stageId;

  /// Links the lead to an existing contact instead of creating one.
  final int? contactId;
  final bool followUp;

  Map<String, dynamic> toJson() => {
    'AssignToId': assignToId,
    'StageId': stageId,
    'ContactId': contactId,
    'FollowUp': followUp,
  }..removeWhere((_, value) => value == null);
}

/// A pipeline stage a lead can start in.
class LeadStage {
  const LeadStage({required this.id, required this.name});

  final int id;
  final LocalizedName name;

  factory LeadStage.fromJson(Map<String, dynamic> json) => LeadStage(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
  );
}

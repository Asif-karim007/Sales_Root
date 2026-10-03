import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

enum TicketStatus {
  open('Open'),
  inProgress('InProgress'),
  onHold('OnHold'),
  resolved('Resolved');

  const TicketStatus(this.wire);

  final String wire;

  static TicketStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => open);
}

enum TicketPriority {
  low('Low', slaHours: 72),
  medium('Medium', slaHours: 24),
  high('High', slaHours: 4),
  urgent('Urgent', slaHours: 2);

  const TicketPriority(this.wire, {required this.slaHours});

  final String wire;

  /// How soon the first fix is due.
  final int slaHours;

  static TicketPriority fromWire(String? value) =>
      values.firstWhere((p) => p.wire == value, orElse: () => medium);
}

enum TicketIssue {
  problem('Problem'),
  installation('Installation'),
  warranty('Warranty'),
  billing('Billing'),
  other('Other');

  const TicketIssue(this.wire);

  final String wire;

  static TicketIssue fromWire(String? value) =>
      values.firstWhere((i) => i.wire == value, orElse: () => other);
}

/// A company a ticket can be raised for.
class TicketCustomer {
  const TicketCustomer({
    required this.id,
    required this.name,
    this.area,
    this.phone,
    this.leadId,
  });

  final int id;
  final String name;
  final LocalizedName? area;
  final String? phone;

  /// The customer's lead, for planning a visit.
  final int? leadId;

  factory TicketCustomer.fromJson(Map<String, dynamic> json) => TicketCustomer(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    area: jsonLocalized(json['Area'], json['AreaBn']),
    phone: json['Phone'] as String?,
    leadId: jsonInt(json['LeadId']),
  );
}

/// A product a ticket can be about.
class TicketProduct {
  const TicketProduct({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  factory TicketProduct.fromJson(Map<String, dynamic> json) => TicketProduct(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    code: json['Code'] as String?,
  );
}

class TicketMessage {
  const TicketMessage({
    required this.text,
    required this.mine,
    this.authorName,
    this.at,
  });

  final String text;

  /// Written by our side rather than the customer.
  final bool mine;
  final String? authorName;
  final DateTime? at;

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    text: json['Text'] as String? ?? '',
    mine: jsonBool(json['FromTeam']),
    authorName: json['AuthorName'] as String?,
    at: jsonDate(json['At']),
  );
}

/// A customer support ticket.
class Ticket {
  const Ticket({
    required this.id,
    required this.code,
    required this.title,
    required this.customerId,
    required this.customerName,
    required this.issue,
    required this.priority,
    required this.status,
    this.slaMinutesLeft,
    this.productName,
    this.assigneeName,
    this.openedAt,
    this.source,
    this.leadId,
    this.photos = const [],
    this.messages = const [],
  });

  final int id;

  /// `T-0088`
  final String code;
  final String title;
  final int customerId;
  final String customerName;
  final TicketIssue issue;
  final TicketPriority priority;
  final TicketStatus status;

  /// Worked out by the server; negative once the SLA is breached, null once
  /// resolved.
  final int? slaMinutesLeft;
  final String? productName;
  final LocalizedName? assigneeName;
  final DateTime? openedAt;

  /// `FieldVisit`, `WhatsApp` or `Phone`.
  final String? source;
  final int? leadId;
  final List<String> photos;
  final List<TicketMessage> messages;

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: jsonInt(json['Id']) ?? 0,
    code: json['Code'] as String? ?? '',
    title: json['Title'] as String? ?? '',
    customerId: jsonInt(json['CustomerId']) ?? 0,
    customerName: json['CustomerName'] as String? ?? '',
    issue: TicketIssue.fromWire(json['IssueType'] as String?),
    priority: TicketPriority.fromWire(json['Priority'] as String?),
    status: TicketStatus.fromWire(json['Status'] as String?),
    slaMinutesLeft: jsonInt(json['SlaMinutesLeft']),
    productName: json['ProductName'] as String?,
    assigneeName: jsonLocalized(json['AssigneeName'], json['AssigneeNameBn']),
    openedAt: jsonDate(json['OpenedAt']),
    source: json['Source'] as String?,
    leadId: jsonInt(json['LeadId']),
    photos: jsonStrings(json['Photos']),
    messages: jsonList(json['Messages'], TicketMessage.fromJson),
  );
}

/// What the new-ticket form sends.
class TicketInput {
  const TicketInput({
    required this.customerId,
    required this.title,
    required this.issue,
    required this.priority,
    this.productId,
    this.description,
    this.photos = const [],
  });

  final int? customerId;
  final String? title;
  final TicketIssue? issue;
  final TicketPriority priority;
  final int? productId;
  final String? description;
  final List<String> photos;

  Map<String, dynamic> toJson() => {
    'CustomerId': customerId,
    'Title': trimmedOrNull(title),
    'IssueType': issue?.wire,
    'Priority': priority.wire,
    'ProductId': productId,
    'Description': trimmedOrNull(description),
    'Photos': photos.isEmpty ? null : photos,
  }..removeWhere((_, value) => value == null);
}

enum TicketField { customer, title, issue, description }

/// The new-ticket form while it is being filled in.
class TicketDraft {
  const TicketDraft({
    this.customer,
    this.title = '',
    this.issue,
    this.priority = TicketPriority.medium,
    this.productId,
    this.description = '',
    this.photos = const [],
  });

  final TicketCustomer? customer;
  final String title;
  final TicketIssue? issue;
  final TicketPriority priority;
  final int? productId;
  final String description;

  /// Local paths of the photos.
  final List<String> photos;

  Set<TicketField> get errors => {
    if (customer == null) TicketField.customer,
    if (title.trim().isEmpty) TicketField.title,
    if (issue == null) TicketField.issue,
    if (description.trim().isEmpty) TicketField.description,
  };

  TicketInput toInput() => TicketInput(
    customerId: customer?.id,
    title: title,
    issue: issue,
    priority: priority,
    productId: productId,
    description: description,
    photos: [for (final path in photos) path.split('/').last],
  );

  TicketDraft copyWith({
    TicketCustomer? customer,
    String? title,
    TicketIssue? issue,
    TicketPriority? priority,
    int? Function()? productId,
    String? description,
    List<String>? photos,
  }) => TicketDraft(
    customer: customer ?? this.customer,
    title: title ?? this.title,
    issue: issue ?? this.issue,
    priority: priority ?? this.priority,
    productId: productId != null ? productId() : this.productId,
    description: description ?? this.description,
    photos: photos ?? this.photos,
  );
}

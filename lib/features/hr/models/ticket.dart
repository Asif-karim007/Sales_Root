import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

enum TicketStatus {
  fresh('new'),
  open('open'),
  waiting('waiting'),
  resolved('resolved'),
  closed('closed');

  const TicketStatus(this.wire);

  final String wire;

  static TicketStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => fresh);
}

enum TicketPriority {
  low('low', slaHours: 72),
  medium('normal', slaHours: 8),
  high('high', slaHours: 4),
  urgent('urgent', slaHours: 2);

  const TicketPriority(this.wire, {required this.slaHours});

  final String wire;

  /// How soon the first response is due.
  final int slaHours;

  static TicketPriority fromWire(String? value) =>
      values.firstWhere((p) => p.wire == value, orElse: () => medium);
}

enum TicketIssue {
  problem('problem'),
  installation('installation'),
  warranty('warranty'),
  billing('billing'),
  other('other');

  const TicketIssue(this.wire);

  final String wire;

  static TicketIssue fromWire(String? value) =>
      values.firstWhere((i) => i.wire == value, orElse: () => other);
}

/// A company a ticket can be raised for.
class TicketCustomer {
  const TicketCustomer({required this.id, required this.name, this.area});

  final String id;
  final String name;
  final String? area;

  factory TicketCustomer.fromJson(Map<String, dynamic> json) => TicketCustomer(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? '',
    area: json['area'] as String?,
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

  /// Written by our team rather than the customer.
  final bool mine;
  final String? authorName;
  final DateTime? at;

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    text: json['body'] as String? ?? '',
    mine: json['authorMembershipId'] != null,
    authorName: json['authorName'] as String?,
    at: jsonDate(json['createdAt']),
  );
}

/// A customer support ticket.
class Ticket {
  const Ticket({
    required this.id,
    required this.code,
    required this.title,
    required this.issue,
    required this.priority,
    required this.status,
    this.customerId,
    this.customerName,
    this.slaHours,
    this.slaBreached = false,
    this.assigneeName,
    this.openedAt,
    this.source,
    this.messages = const [],
  });

  final String id;

  /// `TKT-2026-00002`
  final String code;
  final String title;
  final String? customerId;
  final String? customerName;
  final TicketIssue issue;
  final TicketPriority priority;
  final TicketStatus status;

  /// Hours from opening to the resolve deadline, as the server set it.
  final int? slaHours;
  final bool slaBreached;
  final String? assigneeName;
  final DateTime? openedAt;

  /// `field_visit`, `whatsapp` or `phone`.
  final String? source;
  final List<TicketMessage> messages;

  /// `{ticket, messages}` as `GET tickets/{id}` sends it.
  factory Ticket.fromJson(Map<String, dynamic> json) {
    final ticket = jsonMap(json['ticket']);
    final opened = jsonDate(ticket['createdAt']);
    final due = jsonDate(ticket['slaResolveDue']);
    return Ticket(
      id: jsonId(ticket['id']) ?? '',
      code: ticket['number'] as String? ?? '',
      title: ticket['subject'] as String? ?? '',
      customerId: jsonId(ticket['companyId']),
      customerName: ticket['companyName'] as String?,
      issue: TicketIssue.fromWire(ticket['type'] as String?),
      priority: TicketPriority.fromWire(ticket['priority'] as String?),
      status: TicketStatus.fromWire(ticket['status'] as String?),
      slaHours: opened == null || due == null
          ? null
          : due.difference(opened).inHours,
      slaBreached: jsonBool(ticket['slaBreach']),
      assigneeName: ticket['assigneeName'] as String?,
      openedAt: opened,
      source: ticket['source'] as String?,
      messages: [
        for (final message in jsonList(json['messages'], (m) => m))
          if (message['isInternal'] != true) TicketMessage.fromJson(message),
      ],
    );
  }
}

/// What the new-ticket form sends.
class TicketInput {
  const TicketInput({
    required this.customerId,
    required this.title,
    required this.issue,
    required this.priority,
    this.description,
    this.photos = const [],
  });

  final String? customerId;
  final String? title;
  final TicketIssue? issue;
  final TicketPriority priority;
  final String? description;

  /// Local paths, uploaded once the ticket exists.
  final List<String> photos;

  Map<String, dynamic> toJson() => {
    'subject': trimmedOrNull(title),
    'type': issue?.wire,
    'priority': priority.wire,
    'companyId': customerId,
    'body': trimmedOrNull(description),
    'source': ticketSourceFieldVisit,
  }..removeWhere((_, value) => value == null);
}

/// The source of a ticket a rep raises from the field.
const String ticketSourceFieldVisit = 'field_visit';

enum TicketField { customer, title, issue, description }

/// The new-ticket form while it is being filled in.
class TicketDraft {
  const TicketDraft({
    this.customer,
    this.title = '',
    this.issue,
    this.priority = TicketPriority.medium,
    this.description = '',
    this.photos = const [],
  });

  final TicketCustomer? customer;
  final String title;
  final TicketIssue? issue;
  final TicketPriority priority;
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
    description: description,
    photos: photos,
  );

  TicketDraft copyWith({
    TicketCustomer? customer,
    String? title,
    TicketIssue? issue,
    TicketPriority? priority,
    String? description,
    List<String>? photos,
  }) => TicketDraft(
    customer: customer ?? this.customer,
    title: title ?? this.title,
    issue: issue ?? this.issue,
    priority: priority ?? this.priority,
    description: description ?? this.description,
    photos: photos ?? this.photos,
  );
}

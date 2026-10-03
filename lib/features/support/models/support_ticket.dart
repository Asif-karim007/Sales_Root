import 'package:salesroot/core/utils/json_fields.dart';

enum TicketCategory {
  question('Question'),
  bug('Bug'),
  billing('Billing'),
  data('Data'),
  suggestion('Suggestion');

  const TicketCategory(this.wire);

  final String wire;

  static TicketCategory fromWire(String? value) => values.firstWhere(
    (category) => category.wire == value,
    orElse: () => TicketCategory.question,
  );
}

enum TicketStatus {
  open('Open'),
  replied('Replied'),
  resolved('Resolved');

  const TicketStatus(this.wire);

  final String wire;

  static TicketStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => TicketStatus.open,
  );
}

enum ReplyChannel {
  inApp('InApp'),
  inAppSms('InAppSms'),
  phone('Phone');

  const ReplyChannel(this.wire);

  final String wire;
}

enum AttachmentKind {
  image('Image'),
  video('Video');

  const AttachmentKind(this.wire);

  final String wire;

  static AttachmentKind fromWire(String? value) =>
      value == video.wire ? video : image;
}

class TicketAttachment {
  const TicketAttachment({required this.name, required this.kind});

  final String name;
  final AttachmentKind kind;

  factory TicketAttachment.fromJson(Map<String, dynamic> json) =>
      TicketAttachment(
        name: json['Name'] as String? ?? '',
        kind: AttachmentKind.fromWire(json['Kind'] as String?),
      );
}

class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.body,
    required this.fromAgent,
    this.authorName,
    this.sentAt,
    this.attachments = const [],
  });

  final int id;
  final String body;
  final bool fromAgent;
  final String? authorName;
  final DateTime? sentAt;
  final List<TicketAttachment> attachments;

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    id: jsonInt(json['Id']) ?? 0,
    body: json['Body'] as String? ?? '',
    fromAgent: jsonBool(json['FromAgent']),
    authorName: json['AuthorName'] as String?,
    sentAt: jsonDate(json['SentAt']),
    attachments: jsonList(json['Attachments'], TicketAttachment.fromJson),
  );
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.number,
    required this.subject,
    required this.category,
    required this.status,
    this.replyWithinHours = 8,
    this.agentName,
    this.updatedAt,
    this.messages = const [],
  });

  final int id;
  final String number;
  final String subject;
  final TicketCategory category;
  final TicketStatus status;
  final int replyWithinHours;
  final String? agentName;
  final DateTime? updatedAt;
  final List<TicketMessage> messages;

  bool get hasAgentReply => messages.any((m) => m.fromAgent);
  bool get isResolved => status == TicketStatus.resolved;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: jsonInt(json['Id']) ?? 0,
    number: json['Number'] as String? ?? '',
    subject: json['Subject'] as String? ?? '',
    category: TicketCategory.fromWire(json['Category'] as String?),
    status: TicketStatus.fromWire(json['Status'] as String?),
    replyWithinHours: jsonInt(json['ReplyWithinHours']) ?? 8,
    agentName: json['AgentName'] as String?,
    updatedAt: jsonDate(json['UpdatedAt']),
    messages: jsonList(json['Messages'], TicketMessage.fromJson),
  );
}

/// A file the user picked to send with a request or a reply.
class SupportAttachment {
  const SupportAttachment({
    required this.path,
    required this.name,
    required this.kind,
    this.size = 0,
  });

  final String path;
  final String name;
  final AttachmentKind kind;
  final int size;

  Map<String, dynamic> toJson() => {
    'Name': name,
    'Kind': kind.wire,
    'Size': size,
  };
}

class TicketInput {
  const TicketInput({
    required this.category,
    required this.description,
    required this.channel,
    this.attachments = const [],
    this.diagnostics = const {},
  });

  final TicketCategory category;
  final String description;
  final ReplyChannel channel;
  final List<SupportAttachment> attachments;

  /// Only the items the user agreed to send.
  final Map<String, String> diagnostics;

  Map<String, dynamic> toJson() => {
    'Category': category.wire,
    'Description': description.trim(),
    'ReplyChannel': channel.wire,
    'Attachments': [for (final a in attachments) a.toJson()],
    if (diagnostics.isNotEmpty) 'Diagnostics': diagnostics,
  };
}

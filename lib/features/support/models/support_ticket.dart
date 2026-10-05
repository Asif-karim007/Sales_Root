import 'package:salesroot/core/utils/json_fields.dart';

enum TicketCategory {
  question('question'),
  bug('bug'),
  billing('billing'),
  data('data'),
  suggestion('suggestion');

  const TicketCategory(this.wire);

  final String wire;

  static TicketCategory fromWire(String? value) => values.firstWhere(
    (category) => category.wire == value?.toLowerCase(),
    orElse: () => TicketCategory.question,
  );
}

enum TicketStatus {
  open,
  replied,
  resolved;

  /// The help desk's `new` and `open` wait on support, `waiting` on the
  /// user, and `resolved` and `closed` are done.
  static TicketStatus fromWire(String? value) => switch (value) {
    'waiting' => replied,
    'resolved' || 'closed' => resolved,
    _ => open,
  };
}

enum ReplyChannel {
  inApp('in_app'),
  inAppSms('in_app_sms'),
  phone('phone');

  const ReplyChannel(this.wire);

  final String wire;
}

enum AttachmentKind {
  image,
  video;

  static const _videoTypes = {'mp4', 'mov', 'm4v', '3gp', 'webm'};

  static AttachmentKind ofName(String name) =>
      _videoTypes.contains(name.split('.').last.toLowerCase()) ? video : image;
}

/// A file on a message, as its storage key.
class TicketAttachment {
  const TicketAttachment({required this.name, required this.kind});

  final String name;
  final AttachmentKind kind;

  factory TicketAttachment.fromKey(String key) {
    final name = key.split('/').last;
    return TicketAttachment(name: name, kind: AttachmentKind.ofName(name));
  }
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

  final String id;
  final String body;

  /// Written by the support team; the user's own messages carry no
  /// membership in the support desk.
  final bool fromAgent;
  final String? authorName;
  final DateTime? sentAt;
  final List<TicketAttachment> attachments;

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    id: jsonId(json['id']) ?? '',
    body: json['body'] as String? ?? '',
    fromAgent: json['authorMembershipId'] != null,
    authorName: json['authorName'] as String?,
    sentAt: jsonDate(json['createdAt']),
    attachments: [
      for (final key in jsonStrings(json['attachments']))
        TicketAttachment.fromKey(key),
    ],
  );
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.number,
    required this.subject,
    required this.category,
    required this.status,
    this.replyWithinHours,
    this.agentName,
    this.updatedAt,
    this.messages = const [],
  });

  final String id;
  final String number;
  final String subject;
  final TicketCategory category;
  final TicketStatus status;

  /// Hours from opening to the first-response deadline the desk set.
  final int? replyWithinHours;
  final String? agentName;
  final DateTime? updatedAt;
  final List<TicketMessage> messages;

  bool get hasAgentReply => messages.any((m) => m.fromAgent);
  bool get isResolved => status == TicketStatus.resolved;

  /// A list row, or `{ticket, messages}` as the detail comes.
  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final ticket = json['ticket'] is Map ? jsonMap(json['ticket']) : json;
    final created = jsonDate(ticket['createdAt']);
    final due = jsonDate(ticket['slaResponseDue']);
    return SupportTicket(
      id: jsonId(ticket['id']) ?? '',
      number: ticket['number'] as String? ?? '',
      subject: ticket['subject'] as String? ?? '',
      category: TicketCategory.fromWire(ticket['type'] as String?),
      status: TicketStatus.fromWire(ticket['status'] as String?),
      replyWithinHours: created == null || due == null
          ? null
          : due.difference(created).inHours,
      agentName: ticket['assigneeName'] as String?,
      updatedAt: jsonDate(ticket['updatedAt']) ?? created,
      messages: [
        for (final message in jsonList(json['messages'], (m) => m))
          if (message['isInternal'] != true) TicketMessage.fromJson(message),
      ],
    );
  }
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
}

class TicketInput {
  const TicketInput({
    required this.category,
    required this.description,
    required this.channel,
    this.attachments = const [],
    this.appVersion,
    this.diagnostics = const {},
  });

  final TicketCategory category;
  final String description;
  final ReplyChannel channel;
  final List<SupportAttachment> attachments;

  /// Sent only when the user agreed to share the device details.
  final String? appVersion;

  /// Only the items the user agreed to send.
  final Map<String, String> diagnostics;

  static const _subjectLength = 80;

  /// The first line of the description, cut to fit a subject.
  String get subject {
    final line = description.trim().split('\n').first.trim();
    return line.length <= _subjectLength
        ? line
        : '${line.substring(0, _subjectLength - 1)}…';
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'type': category.wire,
    'body': description.trim(),
    'source': 'app',
    'appVersion': ?appVersion,
    'tags': [
      'reply:${channel.wire}',
      for (final entry in diagnostics.entries) '${entry.key}:${entry.value}',
    ],
  };
}

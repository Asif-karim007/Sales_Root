import 'package:salesroot/core/utils/json_fields.dart';

enum ConversationChannel {
  whatsapp('whatsapp'),
  messenger('messenger'),
  sms('sms');

  const ConversationChannel(this.wire);

  final String wire;

  static ConversationChannel fromWire(String? value) => switch (value) {
    'messenger' || 'facebook' || 'instagram' => messenger,
    'sms' => sms,
    _ => whatsapp,
  };
}

/// The inbox views: `box` on `GET inbox`.
enum ConversationBox {
  all(null),
  unassigned('unassigned'),
  mine('mine');

  const ConversationBox(this.wire);

  final String? wire;
}

enum DeliveryStatus {
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  const DeliveryStatus(this.wire);

  final String wire;

  static DeliveryStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => DeliveryStatus.sent,
  );
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.text,
    required this.mine,
    this.at,
    this.status = DeliveryStatus.sent,
  });

  final String id;
  final String text;

  /// Sent by the team rather than the customer.
  final bool mine;
  final DateTime? at;
  final DeliveryStatus status;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        id: jsonId(json['id']) ?? '',
        text: json['text'] as String? ?? json['body'] as String? ?? '',
        mine: json['direction'] == 'out',
        at: jsonDate(json['createdAt']),
        status: DeliveryStatus.fromWire(json['status'] as String?),
      );
}

/// A customer conversation from WhatsApp or Messenger (`GET inbox`). New
/// enquiries wait here until someone takes them.
class Conversation {
  const Conversation({
    required this.id,
    required this.channel,
    required this.name,
    this.phone,
    this.open = true,
    this.assignedToId,
    this.assignedTo,
    this.leadId,
    this.companyId,
    this.lastMessage,
    this.lastMine = false,
    this.lastMessageAt,
    this.unread = 0,
    this.createdAt,
    this.messages = const [],
  });

  final String id;
  final ConversationChannel channel;
  final String name;
  final String? phone;
  final bool open;
  final String? assignedToId;
  final String? assignedTo;
  final String? leadId;
  final String? companyId;
  final String? lastMessage;
  final bool lastMine;
  final DateTime? lastMessageAt;
  final int unread;
  final DateTime? createdAt;

  /// Oldest first; only `GET inbox/{id}` sends them.
  final List<ConversationMessage> messages;

  bool get isUnassigned => assignedToId == null;

  bool isMine(String? membershipId) =>
      membershipId != null && assignedToId == membershipId;

  /// When something last happened in it.
  DateTime? get lastAt => lastMessageAt ?? createdAt;

  /// Reads a list row, or the detail with its `messages`, also when the
  /// detail comes wrapped as `{conversation, messages}`.
  factory Conversation.fromJson(Map<String, dynamic> json) {
    final row = jsonObject(json['conversation'], (c) => c) ?? json;
    final name = row['contactName'] as String? ?? row['name'] as String?;
    final phone = row['phone'] as String? ?? row['contactPhone'] as String?;
    return Conversation(
      id: jsonId(row['id']) ?? '',
      channel: ConversationChannel.fromWire(row['channel'] as String?),
      name: name ?? phone ?? '',
      phone: phone,
      open: row['status'] != 'closed',
      assignedToId: jsonId(row['assignedMembershipId']),
      assignedTo: row['assigneeName'] as String?,
      leadId: jsonId(row['leadId']),
      companyId: jsonId(row['companyId']),
      lastMessage: row['lastMessageText'] as String?,
      lastMine: row['lastDirection'] == 'out',
      lastMessageAt: jsonDate(row['lastMessageAt']),
      unread: jsonInt(row['unreadCount']) ?? 0,
      createdAt: jsonDate(row['createdAt']),
      messages: jsonList(
        json['messages'] ?? row['messages'],
        ConversationMessage.fromJson,
      ),
    );
  }
}

/// `ReplyRequest`: free text, or an approved template once WhatsApp's
/// 24-hour window has closed.
class ReplyInput {
  const ReplyInput({this.text, this.templateName, this.params = const []});

  final String? text;
  final String? templateName;
  final List<String> params;

  Map<String, dynamic> toJson() =>
      {'text': text?.trim(), 'templateName': templateName, 'params': params}
        ..removeWhere((_, value) => value == null);
}

/// A saved message for one channel (`GET templates`). WhatsApp templates
/// need Meta's approval before they can open a closed window.
class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.name,
    required this.body,
    this.status,
  });

  final String id;
  final String name;
  final String body;
  final String? status;

  bool get approved => status == 'approved';

  factory MessageTemplate.fromJson(Map<String, dynamic> json) =>
      MessageTemplate(
        id: jsonId(json['id']) ?? '',
        name: json['name'] as String? ?? '',
        body: json['body'] as String? ?? '',
        status: json['status'] as String?,
      );
}

/// `DraftAsk`: what the AI should write and about whom.
class DraftAsk {
  const DraftAsk({required this.purpose, this.leadId, this.companyId});

  final String purpose;
  final String? leadId;
  final String? companyId;

  /// A reply that moves the conversation on.
  static const followUp = 'followup';

  Map<String, dynamic> toJson() =>
      {'purpose': purpose, 'leadId': leadId, 'companyId': companyId}
        ..removeWhere((_, value) => value == null);
}

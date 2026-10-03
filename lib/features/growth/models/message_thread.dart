import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';

enum ThreadChannel {
  whatsapp('WhatsApp'),
  messenger('Messenger'),
  sms('SMS');

  const ThreadChannel(this.wire);

  final String wire;

  static ThreadChannel fromWire(String? value) => values.firstWhere(
    (channel) => channel.wire == value,
    orElse: () => ThreadChannel.whatsapp,
  );
}

enum ThreadPartyKind {
  customer('Customer'),
  lead('Lead'),
  unknown('Unknown');

  const ThreadPartyKind(this.wire);

  final String wire;

  static ThreadPartyKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => ThreadPartyKind.unknown,
  );
}

/// One conversation with a customer on a messaging channel.
class MessageThread {
  MessageThread({
    required this.id,
    required this.channel,
    required this.name,
    required this.kind,
    this.phone,
    this.companyId,
    this.leadId,
    this.lastMessage,
    this.lastMine = false,
    this.unread = 0,
    this.assignedToId,
    this.assignedTo,
    this.assignedToMe = false,
    this.reference,
    this.dueAmount,
    this.suggestedReply,
    this.lastAgoAtFetch = Duration.zero,
    this.windowAtFetch,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  final int id;
  final ThreadChannel channel;
  final String name;
  final ThreadPartyKind kind;
  final String? phone;
  final int? companyId;
  final int? leadId;
  final String? lastMessage;
  final bool lastMine;
  final int unread;
  final int? assignedToId;
  final LocalizedName? assignedTo;
  final bool assignedToMe;

  /// An order or invoice number the conversation is about.
  final String? reference;
  final int? dueAmount;
  final String? suggestedReply;
  final DateTime fetchedAt;

  /// How long ago the last message was, and how much of the reply window
  /// was left, when the server answered; the getters below add the time
  /// since [fetchedAt].
  final Duration lastAgoAtFetch;
  final Duration? windowAtFetch;

  Duration lastAgo([DateTime? now]) =>
      lastAgoAtFetch + (now ?? DateTime.now()).difference(fetchedAt);

  /// Time left in WhatsApp's 24-hour free-reply window; null when the
  /// channel has none.
  Duration? windowLeft([DateTime? now]) {
    final left = windowAtFetch;
    if (left == null) return null;
    final remaining = left - (now ?? DateTime.now()).difference(fetchedAt);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get needsTemplate =>
      windowAtFetch != null && windowLeft() == Duration.zero;

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    final window = jsonInt(json['WindowSecondsLeft']);
    return MessageThread(
      id: jsonInt(json['Id']) ?? 0,
      channel: ThreadChannel.fromWire(json['Channel'] as String?),
      name: json['Name'] as String? ?? '',
      kind: ThreadPartyKind.fromWire(json['Kind'] as String?),
      phone: json['Phone'] as String?,
      companyId: jsonInt(json['CompanyId']),
      leadId: jsonInt(json['LeadId']),
      lastMessage: json['LastMessage'] as String?,
      lastMine: jsonBool(json['LastMine']),
      unread: jsonInt(json['Unread']) ?? 0,
      assignedToId: jsonInt(json['AssignedToId']),
      assignedTo: jsonMemberName(json, 'AssignedTo'),
      assignedToMe: jsonBool(json['AssignedToMe']),
      reference: json['Reference'] as String?,
      dueAmount: jsonInt(json['DueAmount']),
      suggestedReply: json['SuggestedReply'] as String?,
      lastAgoAtFetch: Duration(seconds: jsonInt(json['LastAgoSeconds']) ?? 0),
      windowAtFetch: window == null ? null : Duration(seconds: window),
    );
  }
}

enum AttachmentKind {
  invoice('Invoice'),
  quotation('Quotation'),
  priceList('PriceList'),
  photo('Photo');

  const AttachmentKind(this.wire);

  final String wire;

  static AttachmentKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => AttachmentKind.priceList,
  );
}

class MessageAttachment {
  const MessageAttachment({
    required this.kind,
    required this.name,
    this.amount,
  });

  final AttachmentKind kind;
  final String name;
  final int? amount;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        kind: AttachmentKind.fromWire(json['Kind'] as String?),
        name: json['Name'] as String? ?? '',
        amount: jsonInt(json['Amount']),
      );

  Map<String, dynamic> toJson() =>
      {'Kind': kind.wire, 'Name': name, 'Amount': amount}
        ..removeWhere((_, value) => value == null);
}

enum DeliveryStatus {
  sent('Sent'),
  delivered('Delivered'),
  read('Read');

  const DeliveryStatus(this.wire);

  final String wire;

  static DeliveryStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => DeliveryStatus.sent,
  );
}

class ThreadMessage {
  const ThreadMessage({
    required this.id,
    required this.text,
    required this.mine,
    this.at,
    this.attachment,
    this.status = DeliveryStatus.sent,
  });

  final int id;
  final String text;
  final bool mine;
  final DateTime? at;
  final MessageAttachment? attachment;
  final DeliveryStatus status;

  factory ThreadMessage.fromJson(Map<String, dynamic> json) => ThreadMessage(
    id: jsonInt(json['Id']) ?? 0,
    text: json['Text'] as String? ?? '',
    mine: jsonBool(json['Mine']),
    at: jsonDate(json['At']),
    attachment: jsonObject(json['Attachment'], MessageAttachment.fromJson),
    status: DeliveryStatus.fromWire(json['Status'] as String?),
  );
}

/// An approved WhatsApp template (usable after the window closes) or a
/// quick reply.
class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.name,
    required this.body,
    this.approved = false,
  });

  final int id;
  final LocalizedName name;
  final LocalizedName body;
  final bool approved;

  factory MessageTemplate.fromJson(Map<String, dynamic> json) =>
      MessageTemplate(
        id: jsonInt(json['Id']) ?? 0,
        name: LocalizedName.fromJson(json),
        body: LocalizedName(
          json['Body'] as String? ?? '',
          json['BodyBn'] as String? ?? '',
        ),
        approved: jsonBool(json['Approved']),
      );
}

class SendMessageInput {
  const SendMessageInput({this.text = '', this.templateId, this.attachment});

  final String text;
  final int? templateId;
  final MessageAttachment? attachment;

  Map<String, dynamic> toJson() => {
    'Text': text.trim().isEmpty ? null : text.trim(),
    'TemplateId': templateId,
    'Attachment': attachment?.toJson(),
  }..removeWhere((_, value) => value == null);
}

enum ThreadFilter {
  all('All'),
  mine('Mine'),
  unassigned('Unassigned'),
  whatsapp('WhatsApp'),
  messenger('Messenger'),
  sms('SMS');

  const ThreadFilter(this.wire);

  final String wire;
}

class MessagingAccount {
  const MessagingAccount({required this.pageName, required this.number});

  final String pageName;
  final String number;
}

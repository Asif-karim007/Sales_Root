import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/team/models/member.dart';

enum ChatKind {
  group('Group'),
  direct('Direct'),
  lead('Lead');

  const ChatKind(this.wire);

  final String wire;

  static ChatKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => ChatKind.group,
  );
}

class ChatPerson {
  const ChatPerson({
    required this.id,
    required this.name,
    this.role = MemberRole.executive,
    this.isMe = false,
  });

  final String id;
  final LocalizedName name;
  final MemberRole role;

  /// This person is the signed-in user.
  final bool isMe;

  factory ChatPerson.fromJson(Map<String, dynamic> json) => ChatPerson(
    id: jsonId(json['Id']) ?? '',
    name: LocalizedName.fromJson(json),
    role: MemberRole.fromWire(json['Role'] as String?),
    isMe: jsonBool(json['IsMe']),
  );
}

/// The lead a lead discussion is about.
class ChatLead {
  const ChatLead({
    required this.id,
    required this.title,
    this.companyId,
    this.stage,
    this.value = 0,
    this.ownerName,
    this.contactPhone,
  });

  final String id;
  final String title;
  final String? companyId;
  final LocalizedName? stage;
  final int value;
  final LocalizedName? ownerName;
  final String? contactPhone;

  factory ChatLead.fromJson(Map<String, dynamic> json) => ChatLead(
    id: jsonId(json['Id']) ?? '',
    title: json['Title'] as String? ?? '',
    companyId: jsonId(json['CompanyId']),
    stage: json['Stage'] == null
        ? null
        : LocalizedName(
            json['Stage'] as String? ?? '',
            json['StageBn'] as String? ?? '',
          ),
    value: jsonInt(json['Value']) ?? 0,
    ownerName: json['OwnerName'] == null
        ? null
        : LocalizedName(
            json['OwnerName'] as String? ?? '',
            json['OwnerNameBn'] as String? ?? '',
          ),
    contactPhone: json['ContactPhone'] as String?,
  );
}

/// The newest message of a thread, for the list row.
class ChatPreview {
  const ChatPreview({
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.sentAt,
    this.isMine = false,
    this.attachment,
  });

  final String text;
  final String senderId;
  final LocalizedName senderName;
  final DateTime? sentAt;
  final bool isMine;
  final AttachmentKind? attachment;

  factory ChatPreview.fromJson(Map<String, dynamic> json) => ChatPreview(
    text: json['Text'] as String? ?? '',
    senderId: jsonId(json['SenderId']) ?? '',
    senderName: LocalizedName(
      json['SenderName'] as String? ?? '',
      json['SenderNameBn'] as String? ?? '',
    ),
    sentAt: jsonDate(json['SentAt']),
    isMine: jsonBool(json['IsMine']),
    attachment: AttachmentKind.fromWire(json['AttachmentKind'] as String?),
  );
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.kind,
    this.title = '',
    this.isEveryone = false,
    this.participants = const [],
    this.adminId,
    this.lead,
    this.lastMessage,
    this.unreadCount = 0,
    this.messagesToday = 0,
    this.lastActivityAt,
    this.createdAt,
    this.notifications = true,
    this.autoDownload = false,
    this.isParticipant = true,
    this.canLeave = false,
    this.canAddMembers = false,
  });

  final String id;
  final ChatKind kind;

  /// What the creator named a group; empty for direct and lead threads.
  final String title;

  /// The workspace-wide group everyone is in.
  final bool isEveryone;
  final List<ChatPerson> participants;
  final String? adminId;
  final ChatLead? lead;
  final ChatPreview? lastMessage;
  final int unreadCount;
  final int messagesToday;
  final DateTime? lastActivityAt;
  final DateTime? createdAt;
  final bool notifications;
  final bool autoDownload;

  /// False when the owner reads a thread through oversight.
  final bool isParticipant;
  final bool canLeave;
  final bool canAddMembers;

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
    id: jsonId(json['Id']) ?? '',
    kind: ChatKind.fromWire(json['Kind'] as String?),
    title: json['Title'] as String? ?? '',
    isEveryone: jsonBool(json['IsEveryone']),
    participants: jsonList(json['Participants'], ChatPerson.fromJson),
    adminId: jsonId(json['AdminId']),
    lead: jsonObject(json['Lead'], ChatLead.fromJson),
    lastMessage: jsonObject(json['LastMessage'], ChatPreview.fromJson),
    unreadCount: jsonInt(json['UnreadCount']) ?? 0,
    messagesToday: jsonInt(json['MessagesToday']) ?? 0,
    lastActivityAt: jsonDate(json['LastActivityAt']),
    createdAt: jsonDate(json['CreatedAt']),
    notifications: json['Notifications'] != false,
    autoDownload: jsonBool(json['AutoDownload']),
    isParticipant: json['IsParticipant'] != false,
    canLeave: jsonBool(json['CanLeave']),
    canAddMembers: jsonBool(json['CanAddMembers']),
  );
}

enum ChatScope {
  all('All'),
  group('Group'),
  direct('Direct'),
  lead('Lead');

  const ChatScope(this.wire);

  final String wire;
}

class ChatQuery {
  const ChatQuery({
    this.search = '',
    this.scope = ChatScope.all,
    this.page = 1,
  });

  final String search;
  final ChatScope scope;
  final int page;

  Map<String, dynamic> toQuery() => {
    'Search': search.trim().isEmpty ? null : search.trim(),
    'Kind': scope == ChatScope.all ? null : scope.wire,
    'Page': page,
    'PageSize': 20,
  }..removeWhere((_, value) => value == null);
}

enum AttachmentKind {
  photo('Photo'),
  file('File'),
  teamFile('TeamFile'),
  lead('Lead'),
  quotation('Quotation'),
  location('Location'),
  contact('Contact');

  const AttachmentKind(this.wire);

  final String wire;

  static AttachmentKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }

  /// Photos and files are stored in the team's space.
  bool get usesStorage =>
      this == AttachmentKind.photo || this == AttachmentKind.file;
}

class Attachment {
  const Attachment({
    required this.kind,
    this.title = '',
    this.subtitle,
    this.refId,
    this.leadId,
    this.lat,
    this.lng,
    this.sizeBytes,
    this.amount,
    this.localPath,
  });

  final AttachmentKind kind;
  final String title;
  final String? subtitle;

  /// The linked record: a team file, contact, quotation or lead.
  final String? refId;
  final String? leadId;
  final double? lat;
  final double? lng;
  final int? sizeBytes;

  /// A quotation's total.
  final int? amount;

  /// Where a photo or file sent from this phone still sits on disk.
  final String? localPath;

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    kind:
        AttachmentKind.fromWire(json['Kind'] as String?) ?? AttachmentKind.file,
    title: json['Title'] as String? ?? '',
    subtitle: json['Subtitle'] as String?,
    refId: jsonId(json['RefId']),
    leadId: jsonId(json['LeadId']),
    lat: jsonDouble(json['Lat']),
    lng: jsonDouble(json['Lng']),
    sizeBytes: jsonInt(json['SizeBytes']),
    amount: jsonInt(json['Amount']),
    localPath: json['LocalPath'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'Kind': kind.wire,
    'Title': title,
    'Subtitle': subtitle,
    'RefId': refId,
    'LeadId': leadId,
    'Lat': lat,
    'Lng': lng,
    'SizeBytes': sizeBytes,
    'Amount': amount,
    'LocalPath': localPath,
  }..removeWhere((_, value) => value == null);
}

enum MessageStatus {
  sending('Sending'),
  sent('Sent'),
  delivered('Delivered'),
  read('Read'),
  failed('Failed');

  const MessageStatus(this.wire);

  final String wire;

  static MessageStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => MessageStatus.sent,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.sentAt,
    this.attachment,
    this.status = MessageStatus.sent,
    this.isMine = false,
  });

  final int id;
  final String threadId;
  final String senderId;
  final LocalizedName senderName;
  final String text;
  final DateTime? sentAt;
  final Attachment? attachment;
  final MessageStatus status;
  final bool isMine;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: jsonInt(json['Id']) ?? 0,
    threadId: jsonId(json['ThreadId']) ?? '',
    senderId: jsonId(json['SenderId']) ?? '',
    senderName: LocalizedName(
      json['SenderName'] as String? ?? '',
      json['SenderNameBn'] as String? ?? '',
    ),
    text: json['Text'] as String? ?? '',
    sentAt: jsonDate(json['SentAt']),
    attachment: jsonObject(json['Attachment'], Attachment.fromJson),
    status: MessageStatus.fromWire(json['Status'] as String?),
    isMine: jsonBool(json['IsMine']),
  );

  ChatMessage withStatus(MessageStatus status) => ChatMessage(
    id: id,
    threadId: threadId,
    senderId: senderId,
    senderName: senderName,
    text: text,
    sentAt: sentAt,
    attachment: attachment,
    status: status,
    isMine: isMine,
  );
}

class MessageInput {
  const MessageInput({this.text = '', this.attachment});

  final String text;
  final Attachment? attachment;

  Map<String, dynamic> toJson() =>
      {'Text': text.trim(), 'Attachment': attachment?.toJson()}
        ..removeWhere((_, value) => value == null);
}

/// Something that happened in a thread after it was loaded.
sealed class ChatEvent {
  const ChatEvent(this.threadId);

  final String threadId;
}

class MessageAdded extends ChatEvent {
  const MessageAdded(super.threadId, this.message);

  final ChatMessage message;
}

class MessagesStatusChanged extends ChatEvent {
  const MessagesStatusChanged(super.threadId, this.upToId, this.status);

  /// Every message of mine up to this id now has [status].
  final int upToId;
  final MessageStatus status;
}

class TypingChanged extends ChatEvent {
  const TypingChanged(super.threadId, this.person, {required this.typing});

  final ChatPerson person;
  final bool typing;
}

/// A record that can be dropped into a chat: a lead, quotation or contact.
class ChatRef {
  const ChatRef({
    required this.id,
    required this.title,
    this.subtitle,
    this.leadId,
    this.amount,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? leadId;
  final int? amount;

  factory ChatRef.fromJson(Map<String, dynamic> json) => ChatRef(
    id: jsonId(json['Id']) ?? '',
    title: json['Title'] as String? ?? '',
    subtitle: json['Subtitle'] as String?,
    leadId: jsonId(json['LeadId']),
    amount: jsonInt(json['Amount']),
  );
}

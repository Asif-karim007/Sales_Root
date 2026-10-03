import 'package:salesroot/core/utils/json_fields.dart';

enum NoticeAudience {
  everyone('Everyone'),
  sales('Sales'),
  field('Field'),
  leads('TeamLeads');

  const NoticeAudience(this.wire);

  final String wire;

  static NoticeAudience fromWire(String? value) => values.firstWhere(
    (audience) => audience.wire == value,
    orElse: () => NoticeAudience.everyone,
  );
}

enum NoticeState {
  unread('Unread'),
  read('Read'),
  acknowledged('Acknowledged');

  const NoticeState(this.wire);

  final String wire;

  static NoticeState fromWire(String? value) => values.firstWhere(
    (state) => state.wire == value,
    orElse: () => NoticeState.unread,
  );
}

enum AuthorRole {
  owner('Owner'),
  admin('Admin'),
  teamLead('TeamLead');

  const AuthorRole(this.wire);

  final String wire;

  static AuthorRole fromWire(String? value) => values.firstWhere(
    (role) => role.wire == value,
    orElse: () => AuthorRole.admin,
  );
}

enum Presence {
  active('Active'),
  offline('Offline'),
  onLeave('OnLeave');

  const Presence(this.wire);

  final String wire;

  static Presence fromWire(String? value) => values.firstWhere(
    (presence) => presence.wire == value,
    orElse: () => Presence.active,
  );
}

class NoticeAttachment {
  const NoticeAttachment({
    required this.name,
    required this.sizeKb,
    this.photo = false,
  });

  final String name;
  final int sizeKb;
  final bool photo;

  factory NoticeAttachment.fromJson(Map<String, dynamic> json) =>
      NoticeAttachment(
        name: json['Name'] as String? ?? '',
        sizeKb: jsonInt(json['SizeKb']) ?? 0,
        photo: json['Kind'] == 'Photo',
      );

  Map<String, dynamic> toJson() => {
    'Name': name,
    'SizeKb': sizeKb,
    'Kind': photo ? 'Photo' : 'File',
  };
}

class NoticeRecipient {
  const NoticeRecipient({
    required this.memberId,
    required this.name,
    required this.nameBn,
    this.readAt,
    this.acknowledgedAt,
    this.presence = Presence.active,
    this.lastSeenDays = 0,
    this.remindedAt,
  });

  final int memberId;
  final String name;
  final String nameBn;
  final DateTime? readAt;
  final DateTime? acknowledgedAt;
  final Presence presence;
  final int lastSeenDays;
  final DateTime? remindedAt;

  bool get hasRead => readAt != null;
  bool get hasAcknowledged => acknowledgedAt != null;

  String nameOf(bool bangla) => bangla && nameBn.isNotEmpty ? nameBn : name;

  factory NoticeRecipient.fromJson(Map<String, dynamic> json) =>
      NoticeRecipient(
        memberId: jsonInt(json['MemberId']) ?? 0,
        name: json['Name'] as String? ?? '',
        nameBn: json['NameBn'] as String? ?? '',
        readAt: jsonDate(json['ReadAt']),
        acknowledgedAt: jsonDate(json['AcknowledgedAt']),
        presence: Presence.fromWire(json['Presence'] as String?),
        lastSeenDays: jsonInt(json['LastSeenDays']) ?? 0,
        remindedAt: jsonDate(json['RemindedAt']),
      );
}

class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorRole,
    required this.audience,
    required this.audienceCount,
    required this.myState,
    this.authorId,
    this.authorNameBn = '',
    this.postedAt,
    this.requiresAck = false,
    this.pinned = false,
    this.pinUntil,
    this.attachments = const [],
    this.readCount = 0,
    this.ackCount = 0,
    this.recipients = const [],
    this.canEdit = false,
    this.canDelete = false,
  });

  final int id;
  final String title;
  final String body;
  final int? authorId;
  final String authorName;
  final String authorNameBn;
  final AuthorRole authorRole;
  final DateTime? postedAt;
  final NoticeAudience audience;
  final int audienceCount;
  final bool requiresAck;
  final bool pinned;
  final DateTime? pinUntil;
  final List<NoticeAttachment> attachments;

  /// Where the signed-in user is with this notice.
  final NoticeState myState;
  final int readCount;
  final int ackCount;

  /// Only sent to people who may see who has read it.
  final List<NoticeRecipient> recipients;
  final bool canEdit;
  final bool canDelete;

  bool get needsMyAck => requiresAck && myState != NoticeState.acknowledged;

  int get unreadCount => audienceCount - readCount;

  String authorOf(bool bangla) =>
      bangla && authorNameBn.isNotEmpty ? authorNameBn : authorName;

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: jsonInt(json['Id']) ?? 0,
    title: json['Title'] as String? ?? '',
    body: json['Body'] as String? ?? '',
    authorId: jsonInt(json['AuthorId']),
    authorName: json['AuthorName'] as String? ?? '',
    authorNameBn: json['AuthorNameBn'] as String? ?? '',
    authorRole: AuthorRole.fromWire(json['AuthorRole'] as String?),
    postedAt: jsonDate(json['PostedAt']),
    audience: NoticeAudience.fromWire(json['Audience'] as String?),
    audienceCount: jsonInt(json['AudienceCount']) ?? 0,
    requiresAck: jsonBool(json['RequiresAck']),
    pinned: jsonBool(json['Pinned']),
    pinUntil: jsonDate(json['PinUntil']),
    attachments: jsonList(json['Attachments'], NoticeAttachment.fromJson),
    myState: NoticeState.fromWire(json['MyState'] as String?),
    readCount: jsonInt(json['ReadCount']) ?? 0,
    ackCount: jsonInt(json['AckCount']) ?? 0,
    recipients: jsonList(json['Recipients'], NoticeRecipient.fromJson),
    canEdit: jsonBool(json['CanEdit']),
    canDelete: jsonBool(json['CanDelete']),
  );
}

class NoticeInput {
  const NoticeInput({
    required this.title,
    required this.body,
    required this.audience,
    required this.requiresAck,
    required this.push,
    required this.sms,
    required this.pinDays,
    this.attachments = const [],
  });

  final String title;
  final String body;
  final NoticeAudience audience;
  final bool requiresAck;
  final bool push;
  final bool sms;

  /// Days to keep it pinned on Home; null doesn't pin.
  final int? pinDays;
  final List<NoticeAttachment> attachments;

  Map<String, dynamic> toJson() => {
    'Title': title.trim(),
    'Body': body.trim(),
    'Audience': audience.wire,
    'RequiresAck': requiresAck,
    'Push': push,
    'Sms': sms,
    'PinDays': pinDays,
    'Attachments': [for (final file in attachments) file.toJson()],
  }..removeWhere((_, value) => value == null);
}

/// The recipient tabs on a notice.
enum RecipientFilter { notRead, read, acknowledged }

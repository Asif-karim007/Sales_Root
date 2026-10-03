import 'package:salesroot/core/utils/json_fields.dart';

enum CampaignChannel {
  sms('SMS'),
  email('Email');

  const CampaignChannel(this.wire);

  final String wire;

  static CampaignChannel fromWire(String? value) => values.firstWhere(
    (channel) => channel.wire == value,
    orElse: () => CampaignChannel.sms,
  );
}

enum CampaignStatus {
  scheduled('Scheduled'),
  sending('Sending'),
  done('Done'),
  cancelled('Cancelled');

  const CampaignStatus(this.wire);

  final String wire;

  static CampaignStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => CampaignStatus.done,
  );
}

/// Who a campaign goes to. The server resolves each segment to people.
enum AudienceSegment {
  overdueCustomers('OverdueCustomers'),
  customers('Customers'),
  dealers('Dealers'),
  hotLeads('HotLeads'),
  interestedLeads('InterestedLeads'),
  openLeads('OpenLeads');

  const AudienceSegment(this.wire);

  final String wire;

  static AudienceSegment fromWire(String? value) => values.firstWhere(
    (segment) => segment.wire == value,
    orElse: () => AudienceSegment.customers,
  );
}

class Audience {
  const Audience({
    required this.segment,
    required this.count,
    this.doNotContact = 0,
  });

  final AudienceSegment segment;
  final int count;

  /// People in the segment who asked not to be messaged.
  final int doNotContact;

  int reach({required bool excludeDoNotContact}) =>
      excludeDoNotContact ? count - doNotContact : count;

  factory Audience.fromJson(Map<String, dynamic> json) => Audience(
    segment: AudienceSegment.fromWire(json['Segment'] as String?),
    count: jsonInt(json['Count']) ?? 0,
    doNotContact: jsonInt(json['DoNotContact']) ?? 0,
  );
}

class CampaignReply {
  const CampaignReply({
    required this.name,
    required this.text,
    required this.createdTask,
    this.leadId,
  });

  final String name;
  final String text;

  /// The reply became a task on an existing lead rather than a new lead.
  final bool createdTask;
  final int? leadId;

  factory CampaignReply.fromJson(Map<String, dynamic> json) => CampaignReply(
    name: json['Name'] as String? ?? '',
    text: json['Text'] as String? ?? '',
    createdTask: json['Outcome'] == 'Task',
    leadId: jsonInt(json['LeadId']),
  );
}

class Campaign {
  const Campaign({
    required this.id,
    required this.name,
    required this.channel,
    required this.status,
    required this.segment,
    required this.recipients,
    this.message,
    this.subject,
    this.scheduledAt,
    this.sentAt,
    this.sent = 0,
    this.delivered = 0,
    this.wrongNumber = 0,
    this.switchedOff = 0,
    this.replies = 0,
    this.opened = 0,
    this.clicked = 0,
    this.leadsCreated = 0,
    this.creditsUsed = 0,
    this.repliesByHour = const [],
    this.replyLeads = const [],
    this.canDelete = true,
  });

  final int id;
  final String name;
  final CampaignChannel channel;
  final CampaignStatus status;
  final AudienceSegment segment;
  final int recipients;
  final String? message;
  final String? subject;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int sent;
  final int delivered;
  final int wrongNumber;
  final int switchedOff;
  final int replies;
  final int opened;
  final int clicked;
  final int leadsCreated;
  final int creditsUsed;

  /// Replies in each hour after sending.
  final List<int> repliesByHour;
  final List<CampaignReply> replyLeads;
  final bool canDelete;

  int get failed => wrongNumber + switchedOff;

  bool get isSms => channel == CampaignChannel.sms;

  double get deliveredShare => sent == 0 ? 0 : delivered / sent;

  double get openedShare => sent == 0 ? 0 : opened / sent;

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    channel: CampaignChannel.fromWire(json['Channel'] as String?),
    status: CampaignStatus.fromWire(json['Status'] as String?),
    segment: AudienceSegment.fromWire(json['Segment'] as String?),
    recipients: jsonInt(json['Recipients']) ?? 0,
    message: json['Message'] as String?,
    subject: json['Subject'] as String?,
    scheduledAt: jsonDate(json['ScheduledAt']),
    sentAt: jsonDate(json['SentAt']),
    sent: jsonInt(json['Sent']) ?? 0,
    delivered: jsonInt(json['Delivered']) ?? 0,
    wrongNumber: jsonInt(json['WrongNumber']) ?? 0,
    switchedOff: jsonInt(json['SwitchedOff']) ?? 0,
    replies: jsonInt(json['Replies']) ?? 0,
    opened: jsonInt(json['Opened']) ?? 0,
    clicked: jsonInt(json['Clicked']) ?? 0,
    leadsCreated: jsonInt(json['LeadsCreated']) ?? 0,
    creditsUsed: jsonInt(json['CreditsUsed']) ?? 0,
    repliesByHour: jsonInts(json['RepliesByHour']),
    replyLeads: jsonList(json['ReplyLeads'], CampaignReply.fromJson),
    canDelete: json['CanDelete'] != false,
  );
}

class MessagingBalance {
  const MessagingBalance({
    required this.smsCredits,
    required this.smsUsedThisMonth,
    required this.averageSegments,
    required this.senderId,
    required this.emailUsed,
    required this.emailLimit,
    required this.fromEmail,
  });

  final int smsCredits;
  final int smsUsedThisMonth;
  final double averageSegments;
  final String senderId;
  final int emailUsed;
  final int emailLimit;
  final String fromEmail;

  factory MessagingBalance.fromJson(Map<String, dynamic> json) =>
      MessagingBalance(
        smsCredits: jsonInt(json['SmsCredits']) ?? 0,
        smsUsedThisMonth: jsonInt(json['SmsUsedThisMonth']) ?? 0,
        averageSegments: jsonDouble(json['AverageSegments']) ?? 1,
        senderId: json['SenderId'] as String? ?? '',
        emailUsed: jsonInt(json['EmailUsed']) ?? 0,
        emailLimit: jsonInt(json['EmailLimit']) ?? 0,
        fromEmail: json['FromEmail'] as String? ?? '',
      );
}

class CreditPack {
  const CreditPack({
    required this.id,
    required this.credits,
    required this.price,
    this.popular = false,
  });

  final int id;
  final int credits;
  final int price;
  final bool popular;

  double get unitPrice => credits == 0 ? 0 : price / credits;

  factory CreditPack.fromJson(Map<String, dynamic> json) => CreditPack(
    id: jsonInt(json['Id']) ?? 0,
    credits: jsonInt(json['Credits']) ?? 0,
    price: jsonInt(json['Price']) ?? 0,
    popular: jsonBool(json['Popular']),
  );
}

class SmsCampaignInput {
  const SmsCampaignInput({
    required this.name,
    required this.segment,
    required this.message,
    required this.excludeDoNotContact,
    this.scheduleAt,
  });

  final String name;
  final AudienceSegment segment;
  final String message;
  final bool excludeDoNotContact;

  /// Null sends now.
  final DateTime? scheduleAt;

  Map<String, dynamic> toJson() => {
    'Name': name,
    'Segment': segment.wire,
    'Message': message.trim(),
    'ExcludeDoNotContact': excludeDoNotContact,
    'ScheduleAt': jsonUtc(scheduleAt),
  }..removeWhere((_, value) => value == null);
}

class EmailCampaignInput {
  const EmailCampaignInput({
    required this.segment,
    required this.subject,
    required this.body,
    required this.trackOpens,
    this.attachmentName,
    this.buttonLabel,
  });

  final AudienceSegment segment;
  final String subject;
  final String body;
  final bool trackOpens;
  final String? attachmentName;
  final String? buttonLabel;

  Map<String, dynamic> toJson() => {
    'Segment': segment.wire,
    'Subject': subject.trim(),
    'Body': body.trim(),
    'TrackOpens': trackOpens,
    'AttachmentName': attachmentName,
    'ButtonLabel': buttonLabel,
  }..removeWhere((_, value) => value == null);
}

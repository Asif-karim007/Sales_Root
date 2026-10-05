import 'package:salesroot/core/utils/json_fields.dart';

enum CampaignChannel {
  sms('sms'),
  email('email');

  const CampaignChannel(this.wire);

  final String wire;

  static CampaignChannel fromWire(String? value) => values.firstWhere(
    (channel) => channel.wire == value,
    orElse: () => CampaignChannel.sms,
  );
}

enum CampaignStatus {
  scheduled('scheduled'),
  sending('sending'),
  done('sent'),
  cancelled('cancelled');

  const CampaignStatus(this.wire);

  final String wire;

  static CampaignStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => CampaignStatus.done,
  );
}

/// Who a campaign goes to: the lead filter the server resolves to people
/// with a phone number or email.
enum AudienceSegment {
  openLeads({'status': 'open'}),
  customers({'status': 'won'}),
  lostLeads({'status': 'lost'}),
  facebookLeads({'source': 'facebook', 'status': 'open'}),
  websiteLeads({'source': 'website', 'status': 'open'});

  const AudienceSegment(this.filter);

  final Map<String, String> filter;

  static AudienceSegment? fromFilter(Map<String, dynamic> audience) =>
      values.where((segment) {
        final filter = segment.filter;
        return filter.length == audience.length &&
            filter.entries.every((e) => audience[e.key] == e.value);
      }).firstOrNull;
}

/// How many people a segment reaches now (`POST campaigns/preview`).
class Audience {
  const Audience({
    required this.segment,
    required this.count,
    this.estimatedCost = 0,
  });

  final AudienceSegment segment;
  final int count;

  /// What the server expects the send to cost, in taka.
  final double estimatedCost;

  factory Audience.fromPreview(
    AudienceSegment segment,
    Map<String, dynamic> json,
  ) => Audience(
    segment: segment,
    count: jsonInt(json['count']) ?? 0,
    estimatedCost: jsonDouble(json['estimatedCost']) ?? 0,
  );
}

class Campaign {
  const Campaign({
    required this.id,
    required this.name,
    required this.channel,
    required this.status,
    this.segment,
    this.recipients = 0,
    this.message,
    this.scheduledAt,
    this.sentAt,
    this.sent = 0,
    this.delivered = 0,
    this.failed = 0,
    this.replies = 0,
  });

  final String id;
  final String name;
  final CampaignChannel channel;
  final CampaignStatus status;

  /// Null when the audience is not one of the app's segments.
  final AudienceSegment? segment;
  final int recipients;
  final String? message;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int sent;
  final int delivered;
  final int failed;
  final int replies;

  bool get isSms => channel == CampaignChannel.sms;

  double get deliveredShare => sent == 0 ? 0 : delivered / sent;

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? '',
    channel: CampaignChannel.fromWire(json['channel'] as String?),
    status: CampaignStatus.fromWire(json['status'] as String?),
    segment: AudienceSegment.fromFilter(jsonMap(json['audience'])),
    recipients: jsonInt(json['recipientCount']) ?? 0,
    message: json['body'] as String?,
    scheduledAt: jsonDate(json['scheduledAt']),
    sentAt: jsonDate(json['sentAt']),
    sent: jsonInt(json['sentCount']) ?? 0,
    delivered: jsonInt(json['deliveredCount']) ?? 0,
    failed: jsonInt(json['failedCount']) ?? 0,
    replies: jsonInt(json['replyCount']) ?? 0,
  );
}

/// `CampaignUpsert`, for a send and for its audience preview.
class CampaignInput {
  const CampaignInput({
    required this.name,
    required this.channel,
    required this.segment,
    this.body,
    this.templateId,
    this.scheduledAt,
  });

  final String name;
  final CampaignChannel channel;
  final AudienceSegment segment;
  final String? body;
  final String? templateId;

  /// Null sends now.
  final DateTime? scheduledAt;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'channel': channel.wire,
    'audience': segment.filter,
    'body': body?.trim(),
    'templateId': templateId,
    'scheduledAt': jsonUtc(scheduledAt),
  }..removeWhere((_, value) => value == null);
}

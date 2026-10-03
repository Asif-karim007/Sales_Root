import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';

enum FeedbackArea {
  addingLeads('AddingLeads'),
  scanning('Scanning'),
  chat('Chat'),
  reports('Reports'),
  payment('Payment'),
  nothing('Nothing');

  const FeedbackArea(this.wire);

  final String wire;
}

/// The five faces on the feedback form, worst first.
enum FeedbackRating {
  awful(1, '😞'),
  poor(2, '😕'),
  okay(3, '😐'),
  good(4, '🙂'),
  love(5, '😍');

  const FeedbackRating(this.score, this.emoji);

  final int score;
  final String emoji;
}

class FeedbackInput {
  const FeedbackInput({
    required this.rating,
    this.areas = const {},
    this.text = '',
    this.wantsReply = false,
    this.screenshot,
  });

  final FeedbackRating? rating;
  final Set<FeedbackArea> areas;
  final String text;
  final bool wantsReply;
  final SupportAttachment? screenshot;

  Map<String, dynamic> toJson() => {
    'Rating': rating?.score,
    'Areas': [for (final area in areas) area.wire],
    'Text': text.trim().isEmpty ? null : text.trim(),
    'WantsReply': wantsReply,
    'Screenshot': screenshot?.toJson(),
  }..removeWhere((_, value) => value == null);
}

class FeedbackReceipt {
  const FeedbackReceipt({required this.id, required this.number});

  final int id;
  final String number;

  factory FeedbackReceipt.fromJson(Map<String, dynamic> json) =>
      FeedbackReceipt(
        id: jsonInt(json['Id']) ?? 0,
        number: json['Number'] as String? ?? '',
      );
}

enum EnquiryKind {
  customSoftware('CustomSoftware'),
  website('Website'),
  erp('Erp'),
  demo('Demo');

  const EnquiryKind(this.wire);

  final String wire;

  static EnquiryKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire.toLowerCase() == value?.toLowerCase()) return kind;
    }
    return null;
  }
}

enum CallWindow {
  morning('Morning'),
  midday('Midday'),
  afternoon('Afternoon'),
  evening('Evening');

  const CallWindow(this.wire);

  final String wire;
}

class EnquiryInput {
  const EnquiryInput({
    required this.kind,
    required this.company,
    required this.name,
    required this.mobile,
    required this.details,
    required this.callWindow,
  });

  final EnquiryKind? kind;
  final String company;
  final String name;
  final String mobile;
  final String details;
  final CallWindow callWindow;

  Map<String, dynamic> toJson() => {
    'Kind': kind?.wire,
    'Company': company.trim(),
    'Name': name.trim(),
    'Mobile': mobile.trim(),
    'Details': details.trim(),
    'CallWindow': callWindow.wire,
  }..removeWhere((_, value) => value == null);
}

class EnquiryReceipt {
  const EnquiryReceipt({required this.id, required this.reference});

  final int id;
  final String reference;

  factory EnquiryReceipt.fromJson(Map<String, dynamic> json) => EnquiryReceipt(
    id: jsonInt(json['Id']) ?? 0,
    reference: json['Reference'] as String? ?? '',
  );
}

/// The three faces on the one-tap moment survey.
enum SurveyScore {
  hard(1, '😞'),
  okay(2, '😐'),
  easy(3, '😍');

  const SurveyScore(this.score, this.emoji);

  final int score;
  final String emoji;
}

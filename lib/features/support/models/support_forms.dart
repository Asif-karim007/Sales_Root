import 'package:flutter/foundation.dart';

import 'package:salesroot/features/support/models/support_ticket.dart';

/// What `help/feedback` stores: feedback, a moment survey or an enquiry.
enum FeedbackKind {
  feedback('feedback'),
  survey('survey'),
  enquiry('enquiry');

  const FeedbackKind(this.wire);

  final String wire;
}

/// A FeedbackCreate body; null fields are left out.
Map<String, dynamic> feedbackBody(
  FeedbackKind kind, {
  int? rating,
  String? body,
  String? screen,
  String? screenshotKey,
}) => {
  'kind': kind.wire,
  'rating': ?rating,
  'body': ?body,
  'screen': ?screen,
  'platform': defaultTargetPlatform.name,
  'screenshotKey': ?screenshotKey,
};

enum FeedbackArea {
  addingLeads('adding_leads'),
  scanning('scanning'),
  chat('chat'),
  reports('reports'),
  payment('payment'),
  nothing('nothing');

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

  /// The note, then the areas and the reply wish as tagged lines, since the
  /// server keeps one text.
  String get body => [
    if (text.trim().isNotEmpty) text.trim(),
    if (areas.isNotEmpty) 'areas: ${areas.map((a) => a.wire).join(', ')}',
    if (wantsReply) 'reply: yes',
  ].join('\n');

  Map<String, dynamic> toJson({String? screenshotKey}) => feedbackBody(
    FeedbackKind.feedback,
    rating: rating?.score,
    body: body.isEmpty ? null : body,
    screenshotKey: screenshotKey,
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

enum EnquiryField { kind, company, name, mobile, details }

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

  static final _phone = RegExp(r'^\+?(88)?01\d{9}$');

  Set<EnquiryField> get errors => {
    if (kind == null) EnquiryField.kind,
    if (company.trim().isEmpty) EnquiryField.company,
    if (name.trim().isEmpty) EnquiryField.name,
    if (!_phone.hasMatch(mobile.replaceAll(RegExp(r'[ \-]'), '')))
      EnquiryField.mobile,
    if (details.trim().isEmpty) EnquiryField.details,
  };

  /// The enquiry as one text for the support desk.
  Map<String, dynamic> toJson() => feedbackBody(
    FeedbackKind.enquiry,
    body: [
      'kind: ${kind?.wire}',
      'company: ${company.trim()}',
      'name: ${name.trim()}',
      'mobile: ${mobile.trim()}',
      'call: ${callWindow.wire}',
      details.trim(),
    ].join('\n'),
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

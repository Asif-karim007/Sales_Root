import 'package:salesroot/features/support/models/app_destination.dart';

/// A button under a guide answer that opens [destination] with [params].
class GuideAction {
  const GuideAction(this.destination, {this.params = const {}});

  final AppDestination destination;
  final Map<String, String> params;

  String get location => destination.location(params);
}

enum GuideAnswerKind {
  answer,

  /// Proposes a write; the user has to confirm before anything is created.
  confirm,

  /// Nothing matched; points to help and support.
  fallback,
}

class GuideAnswer {
  const GuideAnswer({
    required this.text,
    this.kind = GuideAnswerKind.answer,
    this.actions = const [],
    this.articleId,
    this.hasVideo = false,
  });

  final String text;
  final GuideAnswerKind kind;
  final List<GuideAction> actions;

  /// The help article the answer came from.
  final int? articleId;
  final bool hasVideo;
}

class GuideTurn {
  const GuideTurn({required this.text, required this.mine});

  final String text;
  final bool mine;
}

class GuideQuestion {
  const GuideQuestion({
    required this.text,
    required this.appInBangla,
    this.history = const [],
  });

  final String text;

  /// The app language, used when the question's own script doesn't decide.
  final bool appInBangla;
  final List<GuideTurn> history;
}

enum GuideMessageKind { greeting, mine, answer, declined }

class GuideMessage {
  const GuideMessage({
    required this.id,
    required this.kind,
    this.text = '',
    this.answer,
    this.settled = false,
  });

  final int id;
  final GuideMessageKind kind;
  final String text;
  final GuideAnswer? answer;

  /// A confirm answer the user already accepted or declined.
  final bool settled;

  GuideMessage settle() => GuideMessage(
    id: id,
    kind: kind,
    text: text,
    answer: answer,
    settled: true,
  );
}

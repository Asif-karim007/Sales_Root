import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/models/app_destination.dart';

/// A button under a guide answer that opens [destination] with [params].
class GuideAction {
  const GuideAction(this.destination, {this.params = const {}});

  final AppDestination destination;
  final Map<String, String> params;

  String get location => destination.location(params);

  /// The server's paths that name a section rather than a screen.
  static const _sections = {
    '/field': AppDestination.visits,
    '/hr': AppDestination.leave,
  };

  /// A `{type, route}` action; null for a route the app has no screen for.
  static GuideAction? fromJson(Map<String, dynamic> json) {
    final uri = Uri.tryParse(json['route'] as String? ?? '');
    if (uri == null) return null;
    final destination =
        _sections[uri.path] ??
        AppDestination.values.where((d) => d.path == uri.path).firstOrNull;
    if (destination == null) return null;
    return GuideAction(destination, params: uri.queryParameters);
  }
}

enum GuideAnswerKind {
  answer,

  /// Proposes a write; the user has to confirm before anything is created.
  confirm,
}

class GuideAnswer {
  const GuideAnswer({
    required this.text,
    this.kind = GuideAnswerKind.answer,
    this.actions = const [],
    this.conversationId,
  });

  final String text;
  final GuideAnswerKind kind;
  final List<GuideAction> actions;

  /// Sent with the next question so the guide keeps the thread.
  final String? conversationId;

  factory GuideAnswer.fromJson(Map<String, dynamic> json) {
    final rows = jsonList(json['actions'], (row) => row);
    return GuideAnswer(
      text: json['answer'] as String? ?? '',
      kind: rows.any((row) => row['type'] == 'confirm')
          ? GuideAnswerKind.confirm
          : GuideAnswerKind.answer,
      actions: [for (final row in rows) ?GuideAction.fromJson(row)],
      conversationId: jsonId(json['conversationId']),
    );
  }
}

/// Whether the AI model answers, or the built-in rules do, and how much of
/// the monthly allowance is used.
class GuideStatus {
  const GuideStatus({this.enabled = false, this.used = 0, this.limit = 0});

  final bool enabled;
  final int used;
  final int limit;

  factory GuideStatus.fromJson(Map<String, dynamic> json) => GuideStatus(
    enabled: jsonBool(json['enabled']),
    used: jsonInt(json['used']) ?? 0,
    limit: jsonInt(json['limit']) ?? 0,
  );
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

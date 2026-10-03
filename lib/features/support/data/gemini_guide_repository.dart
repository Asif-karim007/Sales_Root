import 'dart:convert';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/data/guide_gemini_api.dart';
import 'package:salesroot/features/support/data/guide_matcher.dart';
import 'package:salesroot/features/support/data/guide_repository.dart';
import 'package:salesroot/features/support/data/help_repository.dart';
import 'package:salesroot/features/support/models/app_destination.dart';
import 'package:salesroot/features/support/models/guide.dart';
import 'package:salesroot/features/support/models/help_article.dart';

/// Answers with Gemini, grounded in the help articles and limited to
/// suggesting app screens.
class GeminiGuideRepository implements GuideRepository {
  GeminiGuideRepository(this._api, this._help);

  static const _model = 'gemini-3.8-flash';

  /// False when the build was made without `secrets.json`.
  static bool get isAvailable => GuideGeminiApi.apiKey.isNotEmpty;

  final GuideGeminiApi _api;
  final HelpRepository _help;
  List<HelpArticle>? _articles;

  static const _schema = {
    'type': 'OBJECT',
    'properties': {
      'answer': {'type': 'STRING'},
      'destinations': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
      'articleId': {'type': 'INTEGER', 'nullable': true},
      'confirm': {'type': 'BOOLEAN'},
      'taskTitle': {'type': 'STRING', 'nullable': true},
    },
    'required': ['answer'],
  };

  @override
  Future<GuideAnswer> ask(GuideQuestion question) async {
    final bangla = answersInBangla(question);
    final articles = _articles ??= await _loadArticles();
    final response = await apiRequest(
      'Guide ask',
      () => _api.generateContent(_model, {
        'systemInstruction': {
          'parts': [
            {'text': _prompt(articles, bangla)},
          ],
        },
        'contents': [
          for (final turn in question.history)
            {
              'role': turn.mine ? 'user' : 'model',
              'parts': [
                {'text': turn.text},
              ],
            },
          {
            'role': 'user',
            'parts': [
              {'text': question.text},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.3,
          'responseMimeType': 'application/json',
          'responseSchema': _schema,
        },
      }),
    );
    return _parse(response, articles);
  }

  Future<List<HelpArticle>> _loadArticles() async {
    final all = <HelpArticle>[];
    for (var page = 1; ; page++) {
      final result = await _help.articles(const HelpQuery(), page: page);
      all.addAll(result.items);
      if (result.items.isEmpty || all.length >= result.totalCount) return all;
    }
  }

  GuideAnswer _parse(Map<String, dynamic> response, List<HelpArticle> known) {
    final candidates = jsonList(response['candidates'], (c) => c);
    final content = jsonObject(candidates.firstOrNull?['content'], (c) => c);
    final parts = jsonList(content?['parts'], (p) => p);
    final raw = parts.firstOrNull?['text'];
    final Object? decoded;
    try {
      decoded = raw is String ? jsonDecode(raw) : null;
    } on FormatException {
      throw const ApiFailure(502, 'The guide could not answer. Try again.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiFailure(502, 'The guide could not answer. Try again.');
    }
    final destinations = [
      for (final wire in jsonStrings(decoded['destinations']))
        ?AppDestination.fromWire(wire),
    ];
    final articleId = jsonInt(decoded['articleId']);
    final article = known.where((a) => a.id == articleId).firstOrNull;
    final taskTitle = decoded['taskTitle'] as String?;
    final confirm =
        jsonBool(decoded['confirm']) &&
        destinations.contains(AppDestination.newTask);
    return GuideAnswer(
      text: decoded['answer'] as String? ?? '',
      kind: confirm ? GuideAnswerKind.confirm : GuideAnswerKind.answer,
      actions: [
        for (final destination in destinations.take(2))
          GuideAction(
            destination,
            params: destination == AppDestination.newTask && taskTitle != null
                ? {'title': taskTitle}
                : const {},
          ),
      ],
      articleId: article?.id,
      hasVideo: article?.videoSeconds != null,
    );
  }

  static String _prompt(List<HelpArticle> articles, bool bangla) {
    final help = [
      for (final a in articles)
        '[${a.id}] ${a.title.of(bangla)} — ${a.summary.of(bangla)} '
            'Steps: ${[for (final s in a.steps) s.of(bangla)].join(' ')}',
    ].join('\n');
    final screens = [
      for (final d in AppDestination.values) '${d.wire}: ${d.path}',
    ].join('\n');
    return '''
You are the in-app guide of SalesRoot, a Bangla-first field-sales CRM for small Bangladeshi teams that sell solar panels, inverters, batteries and installation.
Answer only questions about using SalesRoot or about selling, in ${bangla ? 'Bangla' : 'English'}, in at most 120 words. Use numbered steps when the answer is a procedure.
You can read only what the user tells you. Never claim to have created, changed or sent anything; you can only suggest screens with "destinations".
When the user asks you to create a task (for example "call Karim Textiles tomorrow at ten"), restate it, ask them to confirm, set "confirm" to true, "taskTitle" to a short title and include "NewTask".
Put the id of the help article you used in "articleId". If you do not know, say so and suggest "Help" and "Support".

Help articles:
$help

Destinations:
$screens
''';
  }
}

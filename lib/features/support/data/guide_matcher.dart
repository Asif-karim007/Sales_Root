import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/digits.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/data/guide_knowledge.dart';
import 'package:salesroot/features/support/models/app_destination.dart';
import 'package:salesroot/features/support/models/guide.dart';
import 'package:salesroot/features/support/models/help_article.dart';
import 'package:salesroot/features/support/models/localized.dart';

/// Answers a question by keyword matching over the help articles and the
/// curated [guideTopics], in the language the question was asked in.
class GuideMatcher {
  const GuideMatcher({required this.articles, required this.graph});

  final List<Map<String, dynamic>> articles;
  final SeedGraph graph;

  static const _hours = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'এক': 1,
    'দুই': 2,
    'তিন': 3,
    'চার': 4,
    'পাঁচ': 5,
    'ছয়': 6,
    'সাত': 7,
    'আট': 8,
    'নয়': 9,
    'দশ': 10,
    'এগারো': 11,
    'বারো': 12,
  };

  GuideAnswer answer(GuideQuestion question) {
    final text = normalizeBangla(question.text.trim());
    final bangla = answersInBangla(question);
    final task = _taskIntent(text);
    if (task != null) return task;

    final tokens = guideTokens(text);
    if (tokens.length <= 4 && _score(tokens, guideThanks) > 0) {
      return GuideAnswer(
        text: bangla
            ? 'আপনাকেও ধন্যবাদ! SalesRoot নিয়ে আর কিছু জানতে চাইলে জিজ্ঞেস করুন।'
            : 'You are welcome! Ask me anything else about SalesRoot.',
      );
    }

    GuideTopic? topic;
    var topicScore = 0.0;
    for (final candidate in guideTopics) {
      final score = _score(tokens, candidate.keywords) + 0.5;
      if (score > topicScore && score > 0.5) {
        topic = candidate;
        topicScore = score;
      }
    }
    Map<String, dynamic>? article;
    var articleScore = 0.0;
    for (final row in articles) {
      final score = _score(tokens, jsonStrings(row['Keywords'])).toDouble();
      if (score > articleScore) {
        article = row;
        articleScore = score;
      }
    }

    if (topic != null && topicScore >= articleScore) {
      return GuideAnswer(
        text: bangla ? topic.bn : topic.en,
        actions: [for (final d in topic.actions) GuideAction(d)],
      );
    }
    if (article != null) return _fromArticle(article, bangla);
    return GuideAnswer(
      kind: GuideAnswerKind.fallback,
      text: bangla
          ? 'এ বিষয়ে SalesRoot সাহায্যে এখনো কিছু পাইনি। সাহায্যে খুঁজে দেখুন, অথবা সাপোর্ট টিমকে জিজ্ঞেস করুন — ৮ ঘণ্টার মধ্যে উত্তর দেয়।'
          : 'I could not find that in SalesRoot help yet. Try searching help, or ask our support team — they reply within 8 hours.',
      actions: const [
        GuideAction(AppDestination.help),
        GuideAction(AppDestination.support),
      ],
    );
  }

  GuideAnswer _fromArticle(Map<String, dynamic> row, bool bangla) {
    final article = HelpArticle.fromJson(row);
    final tip = article.tip;
    final action = article.action;
    final lines = [
      article.summary.of(bangla),
      '',
      for (final (i, step) in article.steps.indexed)
        '${localizeDigits('${i + 1}', bangla: bangla)}. ${step.of(bangla)}',
      if (tip != null) ...['', tip.of(bangla)],
    ];
    return GuideAnswer(
      text: lines.join('\n'),
      actions: [if (action != null) GuideAction(action)],
      articleId: article.id,
      hasVideo: article.videoSeconds != null,
    );
  }

  GuideAnswer? _taskIntent(String text) =>
      _englishTask(text) ?? _banglaTask(text);

  GuideAnswer? _englishTask(String text) {
    final match = RegExp(
      r'^(?:please\s+)?(?:remind me to\s+)?(call|phone|visit|meet|email)\s+(.+?)\s+(tomorrow|today)(?:\s+at\s+([a-z0-9:]+)\s*(am|pm)?)?\s*[.!?]*$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    final verb = match.group(1) ?? '';
    final name = match.group(2) ?? '';
    final day = (match.group(3) ?? '').toLowerCase();
    final time = _time(match.group(4), match.group(5));
    final title = '${verb[0].toUpperCase()}${verb.substring(1)} $name';
    final when = time == null ? day : '$day $time';
    return GuideAnswer(
      kind: GuideAnswerKind.confirm,
      text: 'Okay — I will create the task “$title” for $when. Confirm?',
      actions: [_taskAction(title, name)],
    );
  }

  GuideAnswer? _banglaTask(String text) {
    final match = RegExp(
      '^(.+?)\\s+(আজ|আগামীকাল|কাল)\\s*(?:(\\S+?)\\s*(?:টায়|টা)\\s*)?(কল|ফোন|ভিজিট)\\s*(?:করব|করো|করতে হবে|দিও|দিন)?[।.!?]*\$',
    ).firstMatch(text);
    if (match == null) return null;
    final rawName = (match.group(1) ?? '').trim();
    final name = rawName.endsWith('কে')
        ? rawName.substring(0, rawName.length - 2)
        : rawName;
    final day = match.group(2) == 'আজ' ? 'আজ' : 'কাল';
    final time = _time(match.group(3), null);
    final title = '$nameকে ${match.group(4)}';
    final when = time == null
        ? day
        : '$day ${localizeDigits(time, bangla: true)}-এ';
    return GuideAnswer(
      kind: GuideAnswerKind.confirm,
      text: 'ঠিক আছে — $when “$title” কাজটি বানাব। নিশ্চিত?',
      actions: [_taskAction(title, name)],
    );
  }

  GuideAction _taskAction(String title, String name) {
    final lower = name.toLowerCase();
    final company = graph.companies
        .where((c) => lower.contains(c.name.toLowerCase()))
        .firstOrNull;
    final lead = company == null
        ? null
        : graph.leads
              .where((l) => l.companyId == company.id && l.isOpen)
              .firstOrNull;
    return GuideAction(
      AppDestination.newTask,
      params: {'title': title, if (lead != null) 'leadId': '${lead.id}'},
    );
  }

  static String? _time(String? raw, String? meridiem) {
    if (raw == null) return null;
    final latin = raw.split('').map((ch) {
      final index = '০১২৩৪৫৬৭৮৯'.indexOf(ch);
      return index < 0 ? ch : '$index';
    }).join();
    final parts = latin.split(':');
    var hour = _hours[latin.toLowerCase()] ?? int.tryParse(parts.first);
    if (hour == null || hour > 23) return null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final pm = meridiem?.toLowerCase() == 'pm';
    if ((pm && hour < 12) || (meridiem == null && hour >= 1 && hour <= 6)) {
      hour += 12;
    }
    return '$hour:${minute.toString().padLeft(2, '0')}';
  }
}

/// Bangla when the question is in Bangla script, English when it has Latin
/// letters, otherwise the app language.
bool answersInBangla(GuideQuestion question) {
  if (hasBanglaScript(question.text)) return true;
  if (RegExp('[A-Za-z]').hasMatch(question.text)) return false;
  return question.appInBangla;
}

List<String> guideTokens(String text) => normalizeBangla(text)
    .toLowerCase()
    .split(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true))
    .where((token) => token.isNotEmpty)
    .toList();

/// The sum of the word counts of every keyword whose words all appear.
int _score(List<String> tokens, List<String> keywords) {
  var score = 0;
  for (final keyword in keywords) {
    final words = guideTokens(keyword);
    if (words.isNotEmpty && words.every((w) => _hasWord(tokens, w))) {
      score += words.length;
    }
  }
  return score;
}

bool _hasWord(List<String> tokens, String word) {
  final prefix = hasBanglaScript(word) || word.length >= 4;
  return tokens.any((t) => prefix ? t.startsWith(word) : t == word);
}

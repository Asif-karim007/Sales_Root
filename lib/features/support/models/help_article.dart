import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/models/app_destination.dart';
import 'package:salesroot/features/support/models/localized.dart';

enum HelpCategory {
  gettingStarted('GettingStarted'),
  leads('Leads'),
  tasks('Tasks'),
  fieldWork('FieldWork'),
  sales('Sales'),
  team('Team'),
  account('Account');

  const HelpCategory(this.wire);

  final String wire;

  static HelpCategory fromWire(String? value) => values.firstWhere(
    (category) => category.wire == value,
    orElse: () => HelpCategory.gettingStarted,
  );
}

class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    this.steps = const [],
    this.tip,
    this.readMinutes = 1,
    this.videoSeconds,
    this.videoUrl,
    this.popular = false,
    this.action,
    this.keywords = const [],
    this.helpfulCount = 0,
  });

  final String id;
  final HelpCategory category;
  final LocalizedName title;
  final LocalizedName summary;
  final List<LocalizedName> steps;
  final LocalizedName? tip;
  final int readMinutes;
  final int? videoSeconds;
  final String? videoUrl;
  final bool popular;

  /// Where the "try it" button goes.
  final AppDestination? action;

  /// Words in both languages the search and the guide match on.
  final List<String> keywords;
  final int helpfulCount;

  factory HelpArticle.fromJson(Map<String, dynamic> json) {
    final tip = localizedField(json, 'Tip');
    return HelpArticle(
      id: jsonId(json['Id']) ?? '',
      category: HelpCategory.fromWire(json['Category'] as String?),
      title: localizedField(json, 'Title'),
      summary: localizedField(json, 'Summary'),
      steps: localizedList(json['Steps'], 'Text'),
      tip: tip.en.isEmpty ? null : tip,
      readMinutes: jsonInt(json['ReadMinutes']) ?? 1,
      videoSeconds: jsonInt(json['VideoSeconds']),
      videoUrl: json['VideoUrl'] as String?,
      popular: jsonBool(json['Popular']),
      action: AppDestination.fromWire(json['Action'] as String?),
      keywords: jsonStrings(json['Keywords']),
      helpfulCount: jsonInt(json['HelpfulCount']) ?? 0,
    );
  }
}

class HelpQuery {
  const HelpQuery({this.term = '', this.category});

  final String term;
  final HelpCategory? category;

  bool get isBrowsing => term.trim().isEmpty && category == null;

  HelpQuery copyWith({String? term, HelpCategory? Function()? category}) =>
      HelpQuery(
        term: term ?? this.term,
        category: category != null ? category() : this.category,
      );

  Map<String, dynamic> toQuery(int page) => {
    'Search': term.trim().isEmpty ? null : term.trim(),
    'Category': category?.wire,
    'Page': page,
    'PageSize': 20,
  }..removeWhere((_, value) => value == null);

  @override
  bool operator ==(Object other) =>
      other is HelpQuery && other.term == term && other.category == category;

  @override
  int get hashCode => Object.hash(term, category);
}

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum SearchKind {
  lead('Leads'),
  contact('Contacts'),
  company('Companies'),
  task('Tasks');

  const SearchKind(this.wire);

  final String wire;
}

/// What the search box holds: the words and the scope chip.
class SearchQuery {
  const SearchQuery({this.term = '', this.kind});

  final String term;

  /// Null searches everything.
  final SearchKind? kind;

  bool get isEmpty => term.trim().isEmpty;

  SearchQuery copyWith({String? term, SearchKind? Function()? kind}) =>
      SearchQuery(
        term: term ?? this.term,
        kind: kind != null ? kind() : this.kind,
      );

  Map<String, dynamic> toQuery() =>
      {'Term': term.trim(), 'Kind': kind?.wire}
        ..removeWhere((_, value) => value == null);
}

class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle,
    this.stage,
    this.stageId,
    this.value,
    this.dueAt,
    this.isDone = false,
  });

  final SearchKind kind;
  final int id;
  final String title;
  final String? subtitle;
  final LocalizedName? stage;
  final int? stageId;
  final int? value;
  final DateTime? dueAt;
  final bool isDone;

  String get route => switch (kind) {
    SearchKind.lead => Routes.leadFor(id),
    SearchKind.contact => Routes.contactFor(id),
    SearchKind.company => Routes.companyFor(id),
    SearchKind.task => Routes.taskFor(id),
  };

  factory SearchHit.fromJson(SearchKind kind, Map<String, dynamic> json) =>
      SearchHit(
        kind: kind,
        id: jsonInt(json['Id']) ?? 0,
        title: json['Title'] as String? ?? '',
        subtitle: json['Subtitle'] as String?,
        stage: jsonObject(json['Stage'], LocalizedName.fromJson),
        stageId: jsonInt(json['StageId']),
        value: jsonInt(json['Value']),
        dueAt: jsonDate(json['DueAt']),
        isDone: jsonBool(json['IsDone']),
      );
}

/// One group of hits and how many matched in all.
class SearchGroup {
  const SearchGroup({
    required this.kind,
    this.items = const [],
    this.totalCount = 0,
  });

  final SearchKind kind;
  final List<SearchHit> items;
  final int totalCount;

  bool get hasMore => items.length < totalCount;

  factory SearchGroup.fromJson(SearchKind kind, Map<String, dynamic> json) =>
      SearchGroup(
        kind: kind,
        items: jsonList(json['Items'], (row) => SearchHit.fromJson(kind, row)),
        totalCount: jsonInt(json['TotalCount']) ?? 0,
      );
}

class SearchResults {
  const SearchResults(this.groups);

  final List<SearchGroup> groups;

  int get totalCount => groups.fold(0, (sum, g) => sum + g.totalCount);

  bool get isEmpty => totalCount == 0;

  SearchGroup? group(SearchKind kind) {
    for (final group in groups) {
      if (group.kind == kind) return group;
    }
    return null;
  }

  factory SearchResults.fromJson(Map<String, dynamic> json) => SearchResults([
    for (final kind in SearchKind.values)
      if (json[kind.wire] case final Map<String, dynamic> group)
        SearchGroup.fromJson(kind, group),
  ]);
}

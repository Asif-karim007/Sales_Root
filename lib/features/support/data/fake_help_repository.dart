import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/support/data/fake_page.dart';
import 'package:salesroot/features/support/data/help_fixtures.dart';
import 'package:salesroot/features/support/data/help_repository.dart';
import 'package:salesroot/features/support/models/help_article.dart';
import 'package:salesroot/features/support/models/localized.dart';

class FakeHelpRepository implements HelpRepository {
  FakeHelpRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _table => helpTable(_backend);

  @override
  Future<PageResult<HelpArticle>> articles(HelpQuery query, {int page = 1}) =>
      _backend.run('Help articles', () {
        final category = query.category?.wire;
        final rows = _table.rows
            .where((row) => category == null || row['Category'] == category)
            .where((row) => matchesHelpTerm(row, query.term))
            .toList();
        return PageResult.fromJson(
          fakeApiPage(rows, page),
          HelpArticle.fromJson,
        );
      });

  @override
  Future<List<HelpArticle>> popular() => _backend.run(
    'Help popular',
    () => [
      for (final row in _table.rows)
        if (row['Popular'] == true) HelpArticle.fromJson(row),
    ],
  );

  @override
  Future<HelpArticle> article(String id) => _backend.run(
    'Help article $id',
    () => HelpArticle.fromJson(_table.byId(_rowId(id))),
  );

  @override
  Future<void> rate(String id, {required bool helpful}) =>
      _backend.run('Help rate $id', () {
        final row = _table.byId(_rowId(id));
        if (!helpful) return;
        _table.update(_rowId(id), {
          'HelpfulCount': (row['HelpfulCount'] as int) + 1,
        });
      });

  static int _rowId(String id) => int.tryParse(id) ?? 0;
}

/// The help articles: shared content, seeded even in an empty workspace.
FakeTable helpTable(FakeBackend backend) => backend.store.table(
  'support/articles',
  () => helpFixtures(backend.graph),
  always: true,
);

/// Every word of [term] appears in the article's titles, summaries, steps or
/// keywords, in either language.
bool matchesHelpTerm(Map<String, dynamic> row, String term) {
  final words = normalizeBangla(
    term,
  ).toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return true;
  final haystack = [
    row['Title'],
    row['TitleBn'],
    row['Summary'],
    row['SummaryBn'],
    for (final step in row['Steps'] as List) ...[
      (step as Map)['Text'],
      step['TextBn'],
    ],
    ...row['Keywords'] as List,
  ].join(' ');
  final folded = normalizeBangla(haystack).toLowerCase();
  return words.every(folded.contains);
}

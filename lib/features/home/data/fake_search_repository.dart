import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/features/home/data/search_fixtures.dart';
import 'package:salesroot/features/home/data/search_repository.dart';
import 'package:salesroot/features/home/models/search_result.dart';

/// The server has no search across kinds yet, so search runs on the seeded
/// graph.
class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository(this._backend);

  static const int topPerKind = 5;

  final FakeBackend _backend;

  @override
  Future<SearchResults> search(SearchQuery query, {int page = 1}) =>
      _backend.run('Search', () {
        final body = query.toQuery();
        fakeRequire(body, ['Term']);
        final term = body['Term'] as String;
        final index = [
          ..._backend.table('search_index', searchIndexFixtures).rows,
          ..._backend.table('search_tasks', searchTaskFixtures).rows,
        ];
        final kind = query.kind;
        return SearchResults.fromJson({
          for (final k in SearchKind.values)
            if (kind == null || kind == k)
              k.wire: _group(
                [
                  for (final row in index)
                    if (row['Kind'] == k.wire &&
                        fakeMatches(row, term, [
                          'Title',
                          'Subtitle',
                          'Keywords',
                        ]))
                      row,
                ],
                term,
                page: kind == null ? 1 : page,
                pageSize: kind == null ? topPerKind : 20,
              ),
        });
      });

  Map<String, dynamic> _group(
    List<Map<String, dynamic>> rows,
    String term, {
    required int page,
    required int pageSize,
  }) {
    final q = term.toLowerCase();
    bool starts(Map<String, dynamic> row) =>
        '${row['Title']}'.toLowerCase().startsWith(q);
    final ranked = [...rows.where(starts), ...rows.where((r) => !starts(r))];
    return fakePage(ranked, page: page, pageSize: pageSize);
  }
}

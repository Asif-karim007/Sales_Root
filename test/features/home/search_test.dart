import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/features/home/data/fake_search_repository.dart';
import 'package:salesroot/features/home/data/search_repository.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/home/models/search_result.dart';
import 'package:salesroot/features/home/providers/search_providers.dart';

import 'home_test_setup.dart';

void main() {
  test('an empty box searches nothing', () async {
    final container = await homeContainer();
    container.listen(searchResultsProvider, (_, _) {});

    expect(await container.read(searchResultsProvider.future), isNull);
  });

  test('typing finds leads, contacts and companies by name', () async {
    final container = await homeContainer();
    container.listen(searchResultsProvider, (_, _) {});
    container.read(searchQueryProvider.notifier).setTerm('Karim');

    final results = await container.read(searchResultsProvider.future);

    expect(results, isNotNull);
    if (results == null) return;
    final leads = results.group(SearchKind.lead);
    final contacts = results.group(SearchKind.contact);
    expect(leads?.items.first.title, startsWith('Karim Textiles'));
    expect(leads?.items.length, lessThanOrEqualTo(5));
    expect(contacts?.items.map((h) => h.title), contains('Md. Karim'));
    expect(
      results.group(SearchKind.company)?.items.first.route,
      startsWith('/companies/'),
    );
  });

  test('a Bangla area name finds companies there', () async {
    final container = await homeContainer();
    container.listen(searchResultsProvider, (_, _) {});
    container.read(searchQueryProvider.notifier).setTerm('মিরপুর');

    final results = await container.read(searchResultsProvider.future);

    expect(results?.group(SearchKind.company)?.items, isNotEmpty);
  });

  test('one kind pages 20 at a time', () async {
    final container = await homeContainer();
    container.listen(searchResultsProvider, (_, _) {});
    container.read(searchQueryProvider.notifier)
      ..setTerm('a')
      ..setKind(SearchKind.lead);

    final first = await container.read(searchResultsProvider.future);
    final group = first?.group(SearchKind.lead);
    expect(first?.groups.length, 1);
    expect(group?.items.length, 20);
    expect(group?.hasMore, isTrue);

    await container.read(searchResultsProvider.notifier).loadMore();
    final more = container.read(searchResultsProvider).value;
    expect(more?.group(SearchKind.lead)?.items.length, 40);
  });

  test('typing quickly searches once for the last term', () async {
    final terms = <String>[];
    final container = await homeContainer(
      overrides: [
        searchRepositoryProvider.overrideWith(
          (ref) => _RecordingSearch(
            FakeSearchRepository(ref.watch(fakeBackendProvider)),
            terms,
          ),
        ),
      ],
    );
    container.listen(searchResultsProvider, (_, _) {});
    final query = container.read(searchQueryProvider.notifier);
    query.setTerm('Del');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    query.setTerm('Delta');

    final results = await container.read(searchResultsProvider.future);
    expect(results?.group(SearchKind.lead)?.items.first.title, 'Delta Power');
    expect(terms, ['Delta']);
  });

  test('offline shows the offline failure', () async {
    final container = await homeContainer();
    container.listen(searchResultsProvider, (_, _) {});
    goOffline(container);
    container.read(searchQueryProvider.notifier).setTerm('Karim');

    await expectLater(
      container.read(searchResultsProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
    );
  });

  test('recent searches keep the newest six without duplicates', () async {
    final container = await homeContainer();
    container.listen(recentSearchesProvider, (_, _) {});
    final recent = container.read(recentSearchesProvider.notifier);
    for (final term in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'B ']) {
      recent.remember(term);
    }

    expect(container.read(recentSearchesProvider), [
      'B',
      'g',
      'f',
      'e',
      'd',
      'c',
    ]);
    recent.remove('g');
    expect(container.read(recentSearchesProvider), hasLength(5));
  });
}

class _RecordingSearch implements SearchRepository {
  _RecordingSearch(this._inner, this.terms);

  final SearchRepository _inner;
  final List<String> terms;

  @override
  Future<SearchResults> search(SearchQuery query, {int page = 1}) {
    terms.add(query.term);
    return _inner.search(query, page: page);
  }
}

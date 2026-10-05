import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/home/data/fake_search_repository.dart';
import 'package:salesroot/features/home/data/search_repository.dart';
import 'package:salesroot/features/home/models/search_result.dart';
import 'package:salesroot/features/home/providers/search_providers.dart';

import '../../helpers/api_stub.dart';

/// Search stays on the seeded graph: the server has no search across kinds.
Future<ProviderContainer> searchContainer({
  List<Override> overrides = const [],
}) async {
  final container = await apiContainer(ApiStub(), overrides: overrides);
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false));
  return container;
}

void main() {
  test('an empty box searches nothing', () async {
    final container = await searchContainer();
    container.listen(searchResultsProvider, (_, _) {});

    expect(await container.read(searchResultsProvider.future), isNull);
  });

  test('typing finds contacts and companies by name', () async {
    final container = await searchContainer();
    container.listen(searchResultsProvider, (_, _) {});
    container.read(searchQueryProvider.notifier).setTerm('Karim');

    final results = await container.read(searchResultsProvider.future);

    expect(results, isNotNull);
    if (results == null) return;
    final contacts = results.group(SearchKind.contact);
    final companies = results.group(SearchKind.company);
    expect(companies?.items.first.title, 'Karim Textiles');
    expect(contacts?.items.length, lessThanOrEqualTo(5));
    expect(contacts?.items.map((h) => h.title), contains('Md. Karim'));
    expect(
      results.group(SearchKind.company)?.items.first.route,
      startsWith('/companies/'),
    );
  });

  test('a Bangla area name finds companies there', () async {
    final container = await searchContainer();
    container.listen(searchResultsProvider, (_, _) {});
    container.read(searchQueryProvider.notifier).setTerm('মিরপুর');

    final results = await container.read(searchResultsProvider.future);

    expect(results?.group(SearchKind.company)?.items, isNotEmpty);
  });

  test('one kind pages 20 at a time', () async {
    final container = await searchContainer();
    container.listen(searchResultsProvider, (_, _) {});
    container.read(searchQueryProvider.notifier)
      ..setTerm('a')
      ..setKind(SearchKind.contact);

    final first = await container.read(searchResultsProvider.future);
    final group = first?.group(SearchKind.contact);
    expect(first?.groups.length, 1);
    expect(group?.items.length, 20);
    expect(group?.hasMore, isTrue);

    await container.read(searchResultsProvider.notifier).loadMore();
    final more = container.read(searchResultsProvider).value;
    expect(more?.group(SearchKind.contact)?.items.length, 40);
  });

  test('typing quickly searches once for the last term', () async {
    final terms = <String>[];
    final container = await searchContainer(
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
    expect(
      results?.group(SearchKind.company)?.items.first.title,
      'Delta Power',
    );
    expect(results?.group(SearchKind.company)?.items.first.id, isA<String>());
    expect(terms, ['Delta']);
  });

  test('offline shows the offline failure', () async {
    final container = await searchContainer();
    container.listen(searchResultsProvider, (_, _) {});
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: true));
    container.read(searchQueryProvider.notifier).setTerm('Karim');

    await expectLater(
      container.read(searchResultsProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
    );
  });

  test('recent searches keep the newest six without duplicates', () async {
    final container = await searchContainer();
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

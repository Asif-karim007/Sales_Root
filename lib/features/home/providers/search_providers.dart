import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/home/data/fake_search_repository.dart';
import 'package:salesroot/features/home/data/search_repository.dart';
import 'package:salesroot/features/home/models/search_result.dart';

part 'search_providers.g.dart';

const searchDebounce = Duration(milliseconds: 350);

@Riverpod(keepAlive: true)
SearchRepository searchRepository(Ref ref) =>
    FakeSearchRepository(ref.watch(fakeBackendProvider));

@riverpod
class SearchQueryNotifier extends _$SearchQueryNotifier {
  @override
  SearchQuery build() => const SearchQuery();

  void setTerm(String term) => state = state.copyWith(term: term);

  void setKind(SearchKind? kind) => state = state.copyWith(kind: () => kind);
}

/// Results for the box, fetched once typing pauses for [searchDebounce].
/// Null while the box is empty.
@riverpod
class SearchResultsNotifier extends _$SearchResultsNotifier {
  bool _loadingMore = false;

  @override
  Future<SearchResults?> build() async {
    final query = ref.watch(searchQueryProvider);
    ref.watch(currentWorkspaceProvider.select((w) => w?.id));
    if (query.isEmpty) return null;
    var superseded = false;
    ref.onDispose(() => superseded = true);
    await Future<void>.delayed(searchDebounce);
    if (superseded) return null;
    return ref.read(searchRepositoryProvider).search(query);
  }

  /// The next 20 of the single kind being searched.
  Future<void> loadMore() async {
    final query = ref.read(searchQueryProvider);
    final kind = query.kind;
    final group = kind == null ? null : state.value?.group(kind);
    if (kind == null || group == null || !group.hasMore || _loadingMore) {
      return;
    }
    _loadingMore = true;
    try {
      final next = await ref
          .read(searchRepositoryProvider)
          .search(query, page: group.items.length ~/ 20 + 1);
      if (!ref.mounted) return;
      final more = next.group(kind);
      if (more == null) return;
      state = AsyncData(
        SearchResults([
          SearchGroup(
            kind: kind,
            items: [...group.items, ...more.items],
            totalCount: more.totalCount,
          ),
        ]),
      );
    } on ApiFailure {
      return;
    } finally {
      _loadingMore = false;
    }
  }
}

/// The last few searches in this workspace, newest first.
@riverpod
class RecentSearchesNotifier extends _$RecentSearchesNotifier {
  static const int max = 6;

  @override
  List<String> build() {
    ref.watch(currentWorkspaceProvider.select((w) => w?.id));
    return ref.read(sharedPreferencesProvider).getStringList(_key) ?? const [];
  }

  String get _key =>
      'search/recent/${ref.read(currentWorkspaceProvider)?.id ?? 0}';

  void remember(String term) {
    final clean = term.trim();
    if (clean.isEmpty) return;
    _save(
      [
        clean,
        ...state.where((t) => t.toLowerCase() != clean.toLowerCase()),
      ].take(max).toList(),
    );
  }

  void remove(String term) => _save([...state.where((t) => t != term)]);

  void clear() => _save(const []);

  void _save(List<String> terms) {
    ref.read(sharedPreferencesProvider).setStringList(_key, terms);
    state = terms;
  }
}

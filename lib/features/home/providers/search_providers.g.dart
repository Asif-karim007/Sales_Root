// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(searchRepository)
final searchRepositoryProvider = SearchRepositoryProvider._();

final class SearchRepositoryProvider
    extends
        $FunctionalProvider<
          SearchRepository,
          SearchRepository,
          SearchRepository
        >
    with $Provider<SearchRepository> {
  SearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchRepositoryHash();

  @$internal
  @override
  $ProviderElement<SearchRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchRepository create(Ref ref) {
    return searchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchRepository>(value),
    );
  }
}

String _$searchRepositoryHash() => r'a854f2e39c66b6696578207671b57d2aa2cabf13';

@ProviderFor(SearchQueryNotifier)
final searchQueryProvider = SearchQueryNotifierProvider._();

final class SearchQueryNotifierProvider
    extends $NotifierProvider<SearchQueryNotifier, SearchQuery> {
  SearchQueryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryNotifierHash();

  @$internal
  @override
  SearchQueryNotifier create() => SearchQueryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchQuery>(value),
    );
  }
}

String _$searchQueryNotifierHash() =>
    r'a2122db0de5bb004a3ea5240b127bb1fe0b1ad7e';

abstract class _$SearchQueryNotifier extends $Notifier<SearchQuery> {
  SearchQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchQuery, SearchQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchQuery, SearchQuery>,
              SearchQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Results for the box, fetched once typing pauses for [searchDebounce].
/// Null while the box is empty.

@ProviderFor(SearchResultsNotifier)
final searchResultsProvider = SearchResultsNotifierProvider._();

/// Results for the box, fetched once typing pauses for [searchDebounce].
/// Null while the box is empty.
final class SearchResultsNotifierProvider
    extends $AsyncNotifierProvider<SearchResultsNotifier, SearchResults?> {
  /// Results for the box, fetched once typing pauses for [searchDebounce].
  /// Null while the box is empty.
  SearchResultsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsNotifierHash();

  @$internal
  @override
  SearchResultsNotifier create() => SearchResultsNotifier();
}

String _$searchResultsNotifierHash() =>
    r'4b1403c97e4c519e8f33e04210a241ebfc6ffcd4';

/// Results for the box, fetched once typing pauses for [searchDebounce].
/// Null while the box is empty.

abstract class _$SearchResultsNotifier extends $AsyncNotifier<SearchResults?> {
  FutureOr<SearchResults?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SearchResults?>, SearchResults?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SearchResults?>, SearchResults?>,
              AsyncValue<SearchResults?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The last few searches in this workspace, newest first.

@ProviderFor(RecentSearchesNotifier)
final recentSearchesProvider = RecentSearchesNotifierProvider._();

/// The last few searches in this workspace, newest first.
final class RecentSearchesNotifierProvider
    extends $NotifierProvider<RecentSearchesNotifier, List<String>> {
  /// The last few searches in this workspace, newest first.
  RecentSearchesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchesNotifierHash();

  @$internal
  @override
  RecentSearchesNotifier create() => RecentSearchesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$recentSearchesNotifierHash() =>
    r'4c83f9218ac79757d41aac38a63838264ab246d0';

/// The last few searches in this workspace, newest first.

abstract class _$RecentSearchesNotifier extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

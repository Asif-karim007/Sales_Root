import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// One server page: `{Items, Page, PageSize, TotalCount, TotalPages}`. Facets
/// such as `StageCounts` stay in [raw].
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.totalCount,
    required this.totalPages,
    this.raw = const {},
  });

  final List<T> items;
  final int page;
  final int totalCount;
  final int totalPages;
  final Map<String, dynamic> raw;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) build,
  ) => PageResult(
    items: jsonList(json['Items'], build),
    page: jsonInt(json['Page']) ?? 1,
    totalCount: jsonInt(json['TotalCount']) ?? 0,
    totalPages: jsonInt(json['TotalPages']) ?? 0,
    raw: json,
  );

  /// A `{key: count}` facet, e.g. `facet('StageCounts')`.
  Map<String, int> facet(String key) {
    final value = raw[key];
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        '${entry.key}': jsonInt(entry.value) ?? 0,
    };
  }
}

/// The state of a list that loads 20 at a time on scroll.
class Paged<T> {
  const Paged({
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.facets = const {},
  });

  factory Paged.first(
    PageResult<T> result, {
    List<String> facetKeys = const [],
  }) => Paged(
    items: result.items,
    page: result.page,
    totalCount: result.totalCount,
    facets: {for (final key in facetKeys) key: result.facet(key)},
  );

  final List<T> items;
  final int page;
  final int totalCount;
  final bool isLoadingMore;
  final ApiFailure? loadMoreError;
  final Map<String, Map<String, int>> facets;

  bool get hasMore => items.length < totalCount;
  bool get isEmpty => items.isEmpty;

  Paged<T> loadingMore() => _copy(isLoadingMore: true);

  Paged<T> failedMore(ApiFailure failure) => _copy(loadMoreError: failure);

  Paged<T> append(PageResult<T> next) => Paged(
    items: [...items, ...next.items],
    page: next.page,
    totalCount: next.totalCount,
    facets: facets,
  );

  Paged<T> map(T Function(T item) change) =>
      _copy(items: [for (final item in items) change(item)]);

  Paged<T> where(bool Function(T item) keep) {
    final kept = items.where(keep).toList();
    return _copy(
      items: kept,
      totalCount: totalCount - (items.length - kept.length),
    );
  }

  Paged<T> prepend(T item) =>
      _copy(items: [item, ...items], totalCount: totalCount + 1);

  Paged<T> _copy({
    List<T>? items,
    int? totalCount,
    bool isLoadingMore = false,
    ApiFailure? loadMoreError,
  }) => Paged(
    items: items ?? this.items,
    page: page,
    totalCount: totalCount ?? this.totalCount,
    isLoadingMore: isLoadingMore,
    loadMoreError: loadMoreError,
    facets: facets,
  );
}

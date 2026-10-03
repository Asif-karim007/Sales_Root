// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(helpRepository)
final helpRepositoryProvider = HelpRepositoryProvider._();

final class HelpRepositoryProvider
    extends $FunctionalProvider<HelpRepository, HelpRepository, HelpRepository>
    with $Provider<HelpRepository> {
  HelpRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'helpRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$helpRepositoryHash();

  @$internal
  @override
  $ProviderElement<HelpRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HelpRepository create(Ref ref) {
    return helpRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HelpRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HelpRepository>(value),
    );
  }
}

String _$helpRepositoryHash() => r'34244ea04015f149d368c7eb526dbbee9f15a0e0';

@ProviderFor(HelpQueryNotifier)
final helpQueryProvider = HelpQueryNotifierProvider._();

final class HelpQueryNotifierProvider
    extends $NotifierProvider<HelpQueryNotifier, HelpQuery> {
  HelpQueryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'helpQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$helpQueryNotifierHash();

  @$internal
  @override
  HelpQueryNotifier create() => HelpQueryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HelpQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HelpQuery>(value),
    );
  }
}

String _$helpQueryNotifierHash() => r'8a8abf981bc768ce67c17c8ad9da36ca125a1655';

abstract class _$HelpQueryNotifier extends $Notifier<HelpQuery> {
  HelpQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HelpQuery, HelpQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HelpQuery, HelpQuery>,
              HelpQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Search results for the current [HelpQuery], 20 at a time.

@ProviderFor(HelpSearchNotifier)
final helpSearchProvider = HelpSearchNotifierProvider._();

/// Search results for the current [HelpQuery], 20 at a time.
final class HelpSearchNotifierProvider
    extends $AsyncNotifierProvider<HelpSearchNotifier, Paged<HelpArticle>> {
  /// Search results for the current [HelpQuery], 20 at a time.
  HelpSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'helpSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$helpSearchNotifierHash();

  @$internal
  @override
  HelpSearchNotifier create() => HelpSearchNotifier();
}

String _$helpSearchNotifierHash() =>
    r'5b887916f2b7f6788c61b16bcf546c14e1a837e9';

/// Search results for the current [HelpQuery], 20 at a time.

abstract class _$HelpSearchNotifier extends $AsyncNotifier<Paged<HelpArticle>> {
  FutureOr<Paged<HelpArticle>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<HelpArticle>>, Paged<HelpArticle>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<HelpArticle>>, Paged<HelpArticle>>,
              AsyncValue<Paged<HelpArticle>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(popularArticles)
final popularArticlesProvider = PopularArticlesProvider._();

final class PopularArticlesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HelpArticle>>,
          List<HelpArticle>,
          FutureOr<List<HelpArticle>>
        >
    with
        $FutureModifier<List<HelpArticle>>,
        $FutureProvider<List<HelpArticle>> {
  PopularArticlesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'popularArticlesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$popularArticlesHash();

  @$internal
  @override
  $FutureProviderElement<List<HelpArticle>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HelpArticle>> create(Ref ref) {
    return popularArticles(ref);
  }
}

String _$popularArticlesHash() => r'ce9f6f3adda240f7bbeabdc348b629533a3557fe';

@ProviderFor(helpArticle)
final helpArticleProvider = HelpArticleFamily._();

final class HelpArticleProvider
    extends
        $FunctionalProvider<
          AsyncValue<HelpArticle>,
          HelpArticle,
          FutureOr<HelpArticle>
        >
    with $FutureModifier<HelpArticle>, $FutureProvider<HelpArticle> {
  HelpArticleProvider._({
    required HelpArticleFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'helpArticleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$helpArticleHash();

  @override
  String toString() {
    return r'helpArticleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<HelpArticle> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HelpArticle> create(Ref ref) {
    final argument = this.argument as int;
    return helpArticle(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HelpArticleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$helpArticleHash() => r'044f7180d19e041de84fe97a62ee9eca1af92b75';

final class HelpArticleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<HelpArticle>, int> {
  HelpArticleFamily._()
    : super(
        retry: null,
        name: r'helpArticleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HelpArticleProvider call(int id) =>
      HelpArticleProvider._(argument: id, from: this);

  @override
  String toString() => r'helpArticleProvider';
}

/// The reader's "did this help?" answer; null until they answer.

@ProviderFor(ArticleVoteNotifier)
final articleVoteProvider = ArticleVoteNotifierFamily._();

/// The reader's "did this help?" answer; null until they answer.
final class ArticleVoteNotifierProvider
    extends $AsyncNotifierProvider<ArticleVoteNotifier, bool?> {
  /// The reader's "did this help?" answer; null until they answer.
  ArticleVoteNotifierProvider._({
    required ArticleVoteNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'articleVoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articleVoteNotifierHash();

  @override
  String toString() {
    return r'articleVoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ArticleVoteNotifier create() => ArticleVoteNotifier();

  @override
  bool operator ==(Object other) {
    return other is ArticleVoteNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articleVoteNotifierHash() =>
    r'0c8d372cc92e651c7e63f011dcafb196d7473c37';

/// The reader's "did this help?" answer; null until they answer.

final class ArticleVoteNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ArticleVoteNotifier,
          AsyncValue<bool?>,
          bool?,
          FutureOr<bool?>,
          int
        > {
  ArticleVoteNotifierFamily._()
    : super(
        retry: null,
        name: r'articleVoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The reader's "did this help?" answer; null until they answer.

  ArticleVoteNotifierProvider call(int id) =>
      ArticleVoteNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'articleVoteProvider';
}

/// The reader's "did this help?" answer; null until they answer.

abstract class _$ArticleVoteNotifier extends $AsyncNotifier<bool?> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<bool?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool?>, bool?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool?>, bool?>,
              AsyncValue<bool?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeApi)
final homeApiProvider = HomeApiProvider._();

final class HomeApiProvider
    extends $FunctionalProvider<HomeApi, HomeApi, HomeApi>
    with $Provider<HomeApi> {
  HomeApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeApiHash();

  @$internal
  @override
  $ProviderElement<HomeApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeApi create(Ref ref) {
    return homeApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeApi>(value),
    );
  }
}

String _$homeApiHash() => r'3459940f7a408d5e0f1c40c79105f5a10bdefd4a';

@ProviderFor(homeRepository)
final homeRepositoryProvider = HomeRepositoryProvider._();

final class HomeRepositoryProvider
    extends $FunctionalProvider<HomeRepository, HomeRepository, HomeRepository>
    with $Provider<HomeRepository> {
  HomeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRepositoryHash();

  @$internal
  @override
  $ProviderElement<HomeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeRepository create(Ref ref) {
    return homeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeRepository>(value),
    );
  }
}

String _$homeRepositoryHash() => r'159bc459724e7719fd2a4a1645fa85d25107519e';

/// The home the role and level call for once the workspace has data.

@ProviderFor(homeLayout)
final homeLayoutProvider = HomeLayoutProvider._();

/// The home the role and level call for once the workspace has data.

final class HomeLayoutProvider
    extends $FunctionalProvider<HomeVariant, HomeVariant, HomeVariant>
    with $Provider<HomeVariant> {
  /// The home the role and level call for once the workspace has data.
  HomeLayoutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeLayoutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeLayoutHash();

  @$internal
  @override
  $ProviderElement<HomeVariant> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeVariant create(Ref ref) {
    return homeLayout(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeVariant value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeVariant>(value),
    );
  }
}

String _$homeLayoutHash() => r'68ce312b765c4bf6cf9f6bdb6c316e5982480403';

@ProviderFor(homeSummary)
final homeSummaryProvider = HomeSummaryProvider._();

final class HomeSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeSummary>,
          HomeSummary,
          FutureOr<HomeSummary>
        >
    with $FutureModifier<HomeSummary>, $FutureProvider<HomeSummary> {
  HomeSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeSummaryHash();

  @$internal
  @override
  $FutureProviderElement<HomeSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomeSummary> create(Ref ref) {
    return homeSummary(ref);
  }
}

String _$homeSummaryHash() => r'5181a30419221214f128472027f584fb9eb21b79';

/// The home to show once the summary has said whether the workspace is new.

@ProviderFor(homeVariant)
final homeVariantProvider = HomeVariantProvider._();

/// The home to show once the summary has said whether the workspace is new.

final class HomeVariantProvider
    extends $FunctionalProvider<HomeVariant?, HomeVariant?, HomeVariant?>
    with $Provider<HomeVariant?> {
  /// The home to show once the summary has said whether the workspace is new.
  HomeVariantProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeVariantProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeVariantHash();

  @$internal
  @override
  $ProviderElement<HomeVariant?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeVariant? create(Ref ref) {
    return homeVariant(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeVariant? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeVariant?>(value),
    );
  }
}

String _$homeVariantHash() => r'd70232d04c399f7b065d8de3f43cf3a55a83eb56';

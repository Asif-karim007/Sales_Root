// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$homeRepositoryHash() => r'1556e207b267165d3d9810406edb0e60257f4092';

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

String _$homeSummaryHash() => r'dd3d3baa493e4a65873ea92ae0f9de9900650b0c';

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

String _$homeVariantHash() => r'abac1d561b40e615bf9561b9a0df45c6d217b16f';

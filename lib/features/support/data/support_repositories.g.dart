// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_repositories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supportApi)
final supportApiProvider = SupportApiProvider._();

final class SupportApiProvider
    extends $FunctionalProvider<SupportApi, SupportApi, SupportApi>
    with $Provider<SupportApi> {
  SupportApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportApiHash();

  @$internal
  @override
  $ProviderElement<SupportApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupportApi create(Ref ref) {
    return supportApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupportApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupportApi>(value),
    );
  }
}

String _$supportApiHash() => r'5133cd5c5a7f28ab66bec5186a2dbd34c3460f1c';

@ProviderFor(supportRepository)
final supportRepositoryProvider = SupportRepositoryProvider._();

final class SupportRepositoryProvider
    extends
        $FunctionalProvider<
          SupportRepository,
          SupportRepository,
          SupportRepository
        >
    with $Provider<SupportRepository> {
  SupportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupportRepository create(Ref ref) {
    return supportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupportRepository>(value),
    );
  }
}

String _$supportRepositoryHash() => r'757a0baf352db046e3821e1681fd3c88712b7dfa';

@ProviderFor(guideRepository)
final guideRepositoryProvider = GuideRepositoryProvider._();

final class GuideRepositoryProvider
    extends
        $FunctionalProvider<GuideRepository, GuideRepository, GuideRepository>
    with $Provider<GuideRepository> {
  GuideRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideRepositoryHash();

  @$internal
  @override
  $ProviderElement<GuideRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GuideRepository create(Ref ref) {
    return guideRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuideRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuideRepository>(value),
    );
  }
}

String _$guideRepositoryHash() => r'eeba12d42c12c0a1f2e084eda78efd510473c59d';

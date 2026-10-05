// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_repositories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(billingApi)
final billingApiProvider = BillingApiProvider._();

final class BillingApiProvider
    extends $FunctionalProvider<BillingApi, BillingApi, BillingApi>
    with $Provider<BillingApi> {
  BillingApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingApiHash();

  @$internal
  @override
  $ProviderElement<BillingApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BillingApi create(Ref ref) {
    return billingApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingApi>(value),
    );
  }
}

String _$billingApiHash() => r'753e61df2dd506b24193f4249d4f55d7b2c3a44e';

@ProviderFor(billingRepository)
final billingRepositoryProvider = BillingRepositoryProvider._();

final class BillingRepositoryProvider
    extends
        $FunctionalProvider<
          BillingRepository,
          BillingRepository,
          BillingRepository
        >
    with $Provider<BillingRepository> {
  BillingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingRepositoryHash();

  @$internal
  @override
  $ProviderElement<BillingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BillingRepository create(Ref ref) {
    return billingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingRepository>(value),
    );
  }
}

String _$billingRepositoryHash() => r'f317f624aac838494da0e950f17ad31a2d63aa24';

@ProviderFor(referralRepository)
final referralRepositoryProvider = ReferralRepositoryProvider._();

final class ReferralRepositoryProvider
    extends
        $FunctionalProvider<
          ReferralRepository,
          ReferralRepository,
          ReferralRepository
        >
    with $Provider<ReferralRepository> {
  ReferralRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'referralRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$referralRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReferralRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReferralRepository create(Ref ref) {
    return referralRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReferralRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReferralRepository>(value),
    );
  }
}

String _$referralRepositoryHash() =>
    r'c9756d803d5ad11fccc0ac917ff8a1181de28cdf';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fake_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fakeNetwork)
final fakeNetworkProvider = FakeNetworkProvider._();

final class FakeNetworkProvider
    extends $FunctionalProvider<FakeNetwork, FakeNetwork, FakeNetwork>
    with $Provider<FakeNetwork> {
  FakeNetworkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fakeNetworkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fakeNetworkHash();

  @$internal
  @override
  $ProviderElement<FakeNetwork> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FakeNetwork create(Ref ref) {
    return fakeNetwork(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FakeNetwork value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FakeNetwork>(value),
    );
  }
}

String _$fakeNetworkHash() => r'c60786cd4d739a1f49bfef9be9a903ca7d59c9f6';

/// Rebuilt — and so reseeded — when the dev menu reseeds or empties the data.

@ProviderFor(fakeStore)
final fakeStoreProvider = FakeStoreProvider._();

/// Rebuilt — and so reseeded — when the dev menu reseeds or empties the data.

final class FakeStoreProvider
    extends $FunctionalProvider<FakeStore, FakeStore, FakeStore>
    with $Provider<FakeStore> {
  /// Rebuilt — and so reseeded — when the dev menu reseeds or empties the data.
  FakeStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fakeStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fakeStoreHash();

  @$internal
  @override
  $ProviderElement<FakeStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FakeStore create(Ref ref) {
    return fakeStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FakeStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FakeStore>(value),
    );
  }
}

String _$fakeStoreHash() => r'626e21864b827ecc5ff66571e2cdb90c270054bd';

@ProviderFor(seedGraph)
final seedGraphProvider = SeedGraphProvider._();

final class SeedGraphProvider
    extends $FunctionalProvider<SeedGraph, SeedGraph, SeedGraph>
    with $Provider<SeedGraph> {
  SeedGraphProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seedGraphProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seedGraphHash();

  @$internal
  @override
  $ProviderElement<SeedGraph> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SeedGraph create(Ref ref) {
    return seedGraph(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeedGraph value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeedGraph>(value),
    );
  }
}

String _$seedGraphHash() => r'b4af2481d7528932bc9e9e52563003b094aea7d9';

/// The fake server for the current workspace. Every fake repository is built
/// from this, so dev-menu changes reload every screen.

@ProviderFor(fakeBackend)
final fakeBackendProvider = FakeBackendProvider._();

/// The fake server for the current workspace. Every fake repository is built
/// from this, so dev-menu changes reload every screen.

final class FakeBackendProvider
    extends $FunctionalProvider<FakeBackend, FakeBackend, FakeBackend>
    with $Provider<FakeBackend> {
  /// The fake server for the current workspace. Every fake repository is built
  /// from this, so dev-menu changes reload every screen.
  FakeBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fakeBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fakeBackendHash();

  @$internal
  @override
  $ProviderElement<FakeBackend> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FakeBackend create(Ref ref) {
    return fakeBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FakeBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FakeBackend>(value),
    );
  }
}

String _$fakeBackendHash() => r'185db5952ac973ac3bddc94b56761c2a26901208';

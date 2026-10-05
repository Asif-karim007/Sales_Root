// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PinSetupNotifier)
final pinSetupProvider = PinSetupNotifierProvider._();

final class PinSetupNotifierProvider
    extends $NotifierProvider<PinSetupNotifier, PinSetup> {
  PinSetupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinSetupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinSetupNotifierHash();

  @$internal
  @override
  PinSetupNotifier create() => PinSetupNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PinSetup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PinSetup>(value),
    );
  }
}

String _$pinSetupNotifierHash() => r'186ee66247210787b1c791fce9525a918bc9e69b';

abstract class _$PinSetupNotifier extends $Notifier<PinSetup> {
  PinSetup build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PinSetup, PinSetup>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PinSetup, PinSetup>,
              PinSetup,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The lock screen. Wrong tries survive a restart; after
/// [PinUnlock.maxAttempts] the session is signed out.

@ProviderFor(PinUnlockNotifier)
final pinUnlockProvider = PinUnlockNotifierProvider._();

/// The lock screen. Wrong tries survive a restart; after
/// [PinUnlock.maxAttempts] the session is signed out.
final class PinUnlockNotifierProvider
    extends $NotifierProvider<PinUnlockNotifier, PinUnlock> {
  /// The lock screen. Wrong tries survive a restart; after
  /// [PinUnlock.maxAttempts] the session is signed out.
  PinUnlockNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinUnlockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinUnlockNotifierHash();

  @$internal
  @override
  PinUnlockNotifier create() => PinUnlockNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PinUnlock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PinUnlock>(value),
    );
  }
}

String _$pinUnlockNotifierHash() => r'0d2350e2f212c6f2e15e9fedaff40fc25426cbc9';

/// The lock screen. Wrong tries survive a restart; after
/// [PinUnlock.maxAttempts] the session is signed out.

abstract class _$PinUnlockNotifier extends $Notifier<PinUnlock> {
  PinUnlock build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PinUnlock, PinUnlock>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PinUnlock, PinUnlock>,
              PinUnlock,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

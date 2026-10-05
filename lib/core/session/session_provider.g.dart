// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user, or null. Restored from secure storage at start.

@ProviderFor(SessionNotifier)
final sessionProvider = SessionNotifierProvider._();

/// The signed-in user, or null. Restored from secure storage at start.
final class SessionNotifierProvider
    extends $AsyncNotifierProvider<SessionNotifier, AuthSession?> {
  /// The signed-in user, or null. Restored from secure storage at start.
  SessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionNotifierHash();

  @$internal
  @override
  SessionNotifier create() => SessionNotifier();
}

String _$sessionNotifierHash() => r'ba01f2b68d2ae9ba41adf0c1637b6f98b458b719';

/// The signed-in user, or null. Restored from secure storage at start.

abstract class _$SessionNotifier extends $AsyncNotifier<AuthSession?> {
  FutureOr<AuthSession?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthSession?>, AuthSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthSession?>, AuthSession?>,
              AsyncValue<AuthSession?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// True once per expiry, until the dialog explaining it has been shown.

@ProviderFor(SessionExpiredNotifier)
final sessionExpiredProvider = SessionExpiredNotifierProvider._();

/// True once per expiry, until the dialog explaining it has been shown.
final class SessionExpiredNotifierProvider
    extends $NotifierProvider<SessionExpiredNotifier, bool> {
  /// True once per expiry, until the dialog explaining it has been shown.
  SessionExpiredNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionExpiredProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionExpiredNotifierHash();

  @$internal
  @override
  SessionExpiredNotifier create() => SessionExpiredNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$sessionExpiredNotifierHash() =>
    r'c510143dea514e7eebb967144c4fb3721e56d297';

/// True once per expiry, until the dialog explaining it has been shown.

abstract class _$SessionExpiredNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The PIN screen sits in front of a restored session until it is unlocked.

@ProviderFor(PinLockNotifier)
final pinLockProvider = PinLockNotifierProvider._();

/// The PIN screen sits in front of a restored session until it is unlocked.
final class PinLockNotifierProvider
    extends $AsyncNotifierProvider<PinLockNotifier, bool> {
  /// The PIN screen sits in front of a restored session until it is unlocked.
  PinLockNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinLockNotifierHash();

  @$internal
  @override
  PinLockNotifier create() => PinLockNotifier();
}

String _$pinLockNotifierHash() => r'37b76a1c9bdab208270a6fb017b522bccf418b4d';

/// The PIN screen sits in front of a restored session until it is unlocked.

abstract class _$PinLockNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

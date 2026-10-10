// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Asks once for permission to notify, then keeps this install's push token
/// registered for the signed-in user and workspace.

@ProviderFor(pushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

/// Asks once for permission to notify, then keeps this install's push token
/// registered for the signed-in user and workspace.

final class PushRegistrationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Asks once for permission to notify, then keeps this install's push token
  /// registered for the signed-in user and workspace.
  PushRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrationHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return pushRegistration(ref);
  }
}

String _$pushRegistrationHash() => r'd465a517fb3d7266e93aadf924ca2854ecb0894b';

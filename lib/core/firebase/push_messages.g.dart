// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_messages.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pushMessages)
final pushMessagesProvider = PushMessagesProvider._();

final class PushMessagesProvider
    extends $FunctionalProvider<PushMessages, PushMessages, PushMessages>
    with $Provider<PushMessages> {
  PushMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushMessagesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushMessagesHash();

  @$internal
  @override
  $ProviderElement<PushMessages> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushMessages create(Ref ref) {
    return pushMessages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushMessages value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushMessages>(value),
    );
  }
}

String _$pushMessagesHash() => r'3d65c58236013ab322952e891f382091524ddf6f';

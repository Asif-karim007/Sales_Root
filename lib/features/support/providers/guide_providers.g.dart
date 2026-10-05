// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(guideStatus)
final guideStatusProvider = GuideStatusProvider._();

final class GuideStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<GuideStatus>,
          GuideStatus,
          FutureOr<GuideStatus>
        >
    with $FutureModifier<GuideStatus>, $FutureProvider<GuideStatus> {
  GuideStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideStatusHash();

  @$internal
  @override
  $FutureProviderElement<GuideStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GuideStatus> create(Ref ref) {
    return guideStatus(ref);
  }
}

String _$guideStatusHash() => r'3e3ef8f7ad3c4b0c2f901483e30cfda862c69357';

@ProviderFor(GuideChatNotifier)
final guideChatProvider = GuideChatNotifierProvider._();

final class GuideChatNotifierProvider
    extends $NotifierProvider<GuideChatNotifier, GuideChat> {
  GuideChatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideChatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideChatNotifierHash();

  @$internal
  @override
  GuideChatNotifier create() => GuideChatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuideChat value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuideChat>(value),
    );
  }
}

String _$guideChatNotifierHash() => r'c524a59dc97f098bc1f6e843f0df787b89050ff6';

abstract class _$GuideChatNotifier extends $Notifier<GuideChat> {
  GuideChat build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GuideChat, GuideChat>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GuideChat, GuideChat>,
              GuideChat,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

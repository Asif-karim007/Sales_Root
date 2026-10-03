// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Gemini when the build has `GEMINI_API_KEY`, the keyword matcher otherwise.

@ProviderFor(guideRepository)
final guideRepositoryProvider = GuideRepositoryProvider._();

/// Gemini when the build has `GEMINI_API_KEY`, the keyword matcher otherwise.

final class GuideRepositoryProvider
    extends
        $FunctionalProvider<GuideRepository, GuideRepository, GuideRepository>
    with $Provider<GuideRepository> {
  /// Gemini when the build has `GEMINI_API_KEY`, the keyword matcher otherwise.
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

String _$guideRepositoryHash() => r'a2aaf38184312fd3d8ccb6ab08fcc2b975659011';

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

String _$guideChatNotifierHash() => r'55d32f159e7619b1a0c3bcf05f2725af6d7ec0ef';

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

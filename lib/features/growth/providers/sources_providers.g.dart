// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sources_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(leadSourcesRepository)
final leadSourcesRepositoryProvider = LeadSourcesRepositoryProvider._();

final class LeadSourcesRepositoryProvider
    extends
        $FunctionalProvider<
          LeadSourcesRepository,
          LeadSourcesRepository,
          LeadSourcesRepository
        >
    with $Provider<LeadSourcesRepository> {
  LeadSourcesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadSourcesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadSourcesRepositoryHash();

  @$internal
  @override
  $ProviderElement<LeadSourcesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LeadSourcesRepository create(Ref ref) {
    return leadSourcesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadSourcesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadSourcesRepository>(value),
    );
  }
}

String _$leadSourcesRepositoryHash() =>
    r'5fc565813a5cab25b735de2ceb0aec17945ed9f7';

@ProviderFor(leadChannels)
final leadChannelsProvider = LeadChannelsProvider._();

final class LeadChannelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeadChannel>>,
          List<LeadChannel>,
          FutureOr<List<LeadChannel>>
        >
    with
        $FutureModifier<List<LeadChannel>>,
        $FutureProvider<List<LeadChannel>> {
  LeadChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadChannelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadChannelsHash();

  @$internal
  @override
  $FutureProviderElement<List<LeadChannel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LeadChannel>> create(Ref ref) {
    return leadChannels(ref);
  }
}

String _$leadChannelsHash() => r'386c536ba92fdd3c59ea2b07e419e02a96480d37';

/// Connect and disconnect from the channel list; callers show the outcome.

@ProviderFor(ChannelActions)
final channelActionsProvider = ChannelActionsProvider._();

/// Connect and disconnect from the channel list; callers show the outcome.
final class ChannelActionsProvider
    extends $NotifierProvider<ChannelActions, void> {
  /// Connect and disconnect from the channel list; callers show the outcome.
  ChannelActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelActionsHash();

  @$internal
  @override
  ChannelActions create() => ChannelActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$channelActionsHash() => r'66325a9bc91b36cd27b7302f9e8bd99f6266dc79';

/// Connect and disconnect from the channel list; callers show the outcome.

abstract class _$ChannelActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FacebookSetupNotifier)
final facebookSetupProvider = FacebookSetupNotifierProvider._();

final class FacebookSetupNotifierProvider
    extends $AsyncNotifierProvider<FacebookSetupNotifier, FacebookDraft> {
  FacebookSetupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'facebookSetupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$facebookSetupNotifierHash();

  @$internal
  @override
  FacebookSetupNotifier create() => FacebookSetupNotifier();
}

String _$facebookSetupNotifierHash() =>
    r'4a525230c05970eb4c663ac991782453fec22704';

abstract class _$FacebookSetupNotifier extends $AsyncNotifier<FacebookDraft> {
  FutureOr<FacebookDraft> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FacebookDraft>, FacebookDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FacebookDraft>, FacebookDraft>,
              AsyncValue<FacebookDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

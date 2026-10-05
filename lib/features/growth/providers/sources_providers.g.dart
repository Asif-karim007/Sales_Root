// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sources_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(growthApi)
final growthApiProvider = GrowthApiProvider._();

final class GrowthApiProvider
    extends $FunctionalProvider<GrowthApi, GrowthApi, GrowthApi>
    with $Provider<GrowthApi> {
  GrowthApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'growthApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$growthApiHash();

  @$internal
  @override
  $ProviderElement<GrowthApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GrowthApi create(Ref ref) {
    return growthApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrowthApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrowthApi>(value),
    );
  }
}

String _$growthApiHash() => r'5adfc1a3f2bcff60b8e718d6697ea9e78193fe36';

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
    r'5e29d9603b27f987d99f842958c048597421008f';

@ProviderFor(integrations)
final integrationsProvider = IntegrationsProvider._();

final class IntegrationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Integration>>,
          List<Integration>,
          FutureOr<List<Integration>>
        >
    with
        $FutureModifier<List<Integration>>,
        $FutureProvider<List<Integration>> {
  IntegrationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'integrationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$integrationsHash();

  @$internal
  @override
  $FutureProviderElement<List<Integration>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Integration>> create(Ref ref) {
    return integrations(ref);
  }
}

String _$integrationsHash() => r'5d8d79e2c9b05b6a2bf382291b45f756ea21e34b';

/// Every channel (#134), connected or not.

@ProviderFor(leadChannels)
final leadChannelsProvider = LeadChannelsProvider._();

/// Every channel (#134), connected or not.

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
  /// Every channel (#134), connected or not.
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

String _$leadChannelsHash() => r'11883ec135ca3a0e03f52edecae8b69b6fc4c12f';

/// The connected Meta Page, or null (#135).

@ProviderFor(facebookPage)
final facebookPageProvider = FacebookPageProvider._();

/// The connected Meta Page, or null (#135).

final class FacebookPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<Integration?>,
          Integration?,
          FutureOr<Integration?>
        >
    with $FutureModifier<Integration?>, $FutureProvider<Integration?> {
  /// The connected Meta Page, or null (#135).
  FacebookPageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'facebookPageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$facebookPageHash();

  @$internal
  @override
  $FutureProviderElement<Integration?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Integration?> create(Ref ref) {
    return facebookPage(ref);
  }
}

String _$facebookPageHash() => r'8b51ed936a994a05cb15998bed999a39747570c3';

/// Connect, disconnect and switch forms on or off; callers show the outcome.

@ProviderFor(ChannelActions)
final channelActionsProvider = ChannelActionsProvider._();

/// Connect, disconnect and switch forms on or off; callers show the outcome.
final class ChannelActionsProvider
    extends $NotifierProvider<ChannelActions, void> {
  /// Connect, disconnect and switch forms on or off; callers show the outcome.
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

String _$channelActionsHash() => r'fcbccee29529dbf2a642cb572137ea92f3bfbedc';

/// Connect, disconnect and switch forms on or off; callers show the outcome.

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

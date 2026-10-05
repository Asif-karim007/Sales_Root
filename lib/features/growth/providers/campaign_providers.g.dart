// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(campaignRepository)
final campaignRepositoryProvider = CampaignRepositoryProvider._();

final class CampaignRepositoryProvider
    extends
        $FunctionalProvider<
          CampaignRepository,
          CampaignRepository,
          CampaignRepository
        >
    with $Provider<CampaignRepository> {
  CampaignRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'campaignRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$campaignRepositoryHash();

  @$internal
  @override
  $ProviderElement<CampaignRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CampaignRepository create(Ref ref) {
    return campaignRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CampaignRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CampaignRepository>(value),
    );
  }
}

String _$campaignRepositoryHash() =>
    r'f3da27c1c22779192993dfe30b274df1634b2204';

/// The campaign list (#143).

@ProviderFor(CampaignListNotifier)
final campaignListProvider = CampaignListNotifierProvider._();

/// The campaign list (#143).
final class CampaignListNotifierProvider
    extends $AsyncNotifierProvider<CampaignListNotifier, Paged<Campaign>> {
  /// The campaign list (#143).
  CampaignListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'campaignListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$campaignListNotifierHash();

  @$internal
  @override
  CampaignListNotifier create() => CampaignListNotifier();
}

String _$campaignListNotifierHash() =>
    r'137ea20d171630a44cf4e569f9cc799b96798703';

/// The campaign list (#143).

abstract class _$CampaignListNotifier extends $AsyncNotifier<Paged<Campaign>> {
  FutureOr<Paged<Campaign>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Campaign>>, Paged<Campaign>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Campaign>>, Paged<Campaign>>,
              AsyncValue<Paged<Campaign>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(campaign)
final campaignProvider = CampaignFamily._();

final class CampaignProvider
    extends
        $FunctionalProvider<AsyncValue<Campaign>, Campaign, FutureOr<Campaign>>
    with $FutureModifier<Campaign>, $FutureProvider<Campaign> {
  CampaignProvider._({
    required CampaignFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'campaignProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$campaignHash();

  @override
  String toString() {
    return r'campaignProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Campaign> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Campaign> create(Ref ref) {
    final argument = this.argument as String;
    return campaign(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CampaignProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$campaignHash() => r'f8bf16affa432c8dc057a4cbfb30989c5cc831c8';

final class CampaignFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Campaign>, String> {
  CampaignFamily._()
    : super(
        retry: null,
        name: r'campaignProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CampaignProvider call(String id) =>
      CampaignProvider._(argument: id, from: this);

  @override
  String toString() => r'campaignProvider';
}

/// The workspace's SMS credit balance, from the plan.

@ProviderFor(smsCredits)
final smsCreditsProvider = SmsCreditsProvider._();

/// The workspace's SMS credit balance, from the plan.

final class SmsCreditsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// The workspace's SMS credit balance, from the plan.
  SmsCreditsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smsCreditsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smsCreditsHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return smsCredits(ref);
  }
}

String _$smsCreditsHash() => r'5760dfcea7a81f72d409a0e23a37ffd1ab0f700d';

@ProviderFor(campaignAudiences)
final campaignAudiencesProvider = CampaignAudiencesFamily._();

final class CampaignAudiencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Audience>>,
          List<Audience>,
          FutureOr<List<Audience>>
        >
    with $FutureModifier<List<Audience>>, $FutureProvider<List<Audience>> {
  CampaignAudiencesProvider._({
    required CampaignAudiencesFamily super.from,
    required CampaignChannel super.argument,
  }) : super(
         retry: null,
         name: r'campaignAudiencesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$campaignAudiencesHash();

  @override
  String toString() {
    return r'campaignAudiencesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Audience>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Audience>> create(Ref ref) {
    final argument = this.argument as CampaignChannel;
    return campaignAudiences(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CampaignAudiencesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$campaignAudiencesHash() => r'd1773e6a7e0425aeaf822ec5066d96c475309746';

final class CampaignAudiencesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Audience>>, CampaignChannel> {
  CampaignAudiencesFamily._()
    : super(
        retry: null,
        name: r'campaignAudiencesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CampaignAudiencesProvider call(CampaignChannel channel) =>
      CampaignAudiencesProvider._(argument: channel, from: this);

  @override
  String toString() => r'campaignAudiencesProvider';
}

@ProviderFor(smsTemplates)
final smsTemplatesProvider = SmsTemplatesProvider._();

final class SmsTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageTemplate>>,
          List<MessageTemplate>,
          FutureOr<List<MessageTemplate>>
        >
    with
        $FutureModifier<List<MessageTemplate>>,
        $FutureProvider<List<MessageTemplate>> {
  SmsTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smsTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smsTemplatesHash();

  @$internal
  @override
  $FutureProviderElement<List<MessageTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MessageTemplate>> create(Ref ref) {
    return smsTemplates(ref);
  }
}

String _$smsTemplatesHash() => r'd0167c9b4f505190f1d85b8c131663c31768836b';

/// Cancelling a scheduled campaign; callers show the outcome.

@ProviderFor(CampaignActions)
final campaignActionsProvider = CampaignActionsProvider._();

/// Cancelling a scheduled campaign; callers show the outcome.
final class CampaignActionsProvider
    extends $NotifierProvider<CampaignActions, void> {
  /// Cancelling a scheduled campaign; callers show the outcome.
  CampaignActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'campaignActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$campaignActionsHash();

  @$internal
  @override
  CampaignActions create() => CampaignActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$campaignActionsHash() => r'098d682cc5970b9f7b7e0247a8bd76608ef48bb5';

/// Cancelling a scheduled campaign; callers show the outcome.

abstract class _$CampaignActions extends $Notifier<void> {
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

/// Sending or scheduling a bulk SMS (#144) or email (#145).

@ProviderFor(CampaignSubmit)
final campaignSubmitProvider = CampaignSubmitProvider._();

/// Sending or scheduling a bulk SMS (#144) or email (#145).
final class CampaignSubmitProvider
    extends $NotifierProvider<CampaignSubmit, AsyncValue<Campaign?>> {
  /// Sending or scheduling a bulk SMS (#144) or email (#145).
  CampaignSubmitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'campaignSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$campaignSubmitHash();

  @$internal
  @override
  CampaignSubmit create() => CampaignSubmit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Campaign?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Campaign?>>(value),
    );
  }
}

String _$campaignSubmitHash() => r'7a98e94d3c33b96f5ac4881da9bb4b1c53d758a8';

/// Sending or scheduling a bulk SMS (#144) or email (#145).

abstract class _$CampaignSubmit extends $Notifier<AsyncValue<Campaign?>> {
  AsyncValue<Campaign?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Campaign?>, AsyncValue<Campaign?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Campaign?>, AsyncValue<Campaign?>>,
              AsyncValue<Campaign?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

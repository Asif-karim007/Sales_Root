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
    r'e86fac5d4d1ff317233540822817e423b21d7ff6';

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
    r'06124b2111c200471ad348f2c10087a30ea6d70f';

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
    required int super.argument,
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
    final argument = this.argument as int;
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

String _$campaignHash() => r'28291ddd74aa1fed6046902cbe86527c6a032ce6';

final class CampaignFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Campaign>, int> {
  CampaignFamily._()
    : super(
        retry: null,
        name: r'campaignProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CampaignProvider call(int id) => CampaignProvider._(argument: id, from: this);

  @override
  String toString() => r'campaignProvider';
}

@ProviderFor(messagingBalance)
final messagingBalanceProvider = MessagingBalanceProvider._();

final class MessagingBalanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<MessagingBalance>,
          MessagingBalance,
          FutureOr<MessagingBalance>
        >
    with $FutureModifier<MessagingBalance>, $FutureProvider<MessagingBalance> {
  MessagingBalanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagingBalanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagingBalanceHash();

  @$internal
  @override
  $FutureProviderElement<MessagingBalance> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MessagingBalance> create(Ref ref) {
    return messagingBalance(ref);
  }
}

String _$messagingBalanceHash() => r'06d8898d13fec79b4eeb556338cd508e12a081c1';

@ProviderFor(campaignAudiences)
final campaignAudiencesProvider = CampaignAudiencesProvider._();

final class CampaignAudiencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Audience>>,
          List<Audience>,
          FutureOr<List<Audience>>
        >
    with $FutureModifier<List<Audience>>, $FutureProvider<List<Audience>> {
  CampaignAudiencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'campaignAudiencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$campaignAudiencesHash();

  @$internal
  @override
  $FutureProviderElement<List<Audience>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Audience>> create(Ref ref) {
    return campaignAudiences(ref);
  }
}

String _$campaignAudiencesHash() => r'c8dd535b944dbc07bcce69e57dc5bfdfd0cf5fe7';

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

String _$smsTemplatesHash() => r'6b257ba414e5d85db8b269767fa0765bb9df4331';

@ProviderFor(creditPacks)
final creditPacksProvider = CreditPacksProvider._();

final class CreditPacksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CreditPack>>,
          List<CreditPack>,
          FutureOr<List<CreditPack>>
        >
    with $FutureModifier<List<CreditPack>>, $FutureProvider<List<CreditPack>> {
  CreditPacksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creditPacksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creditPacksHash();

  @$internal
  @override
  $FutureProviderElement<List<CreditPack>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CreditPack>> create(Ref ref) {
    return creditPacks(ref);
  }
}

String _$creditPacksHash() => r'b2f10910794e66a5e57f145b6990f67b98dfc848';

/// Test sends, retries and cancellations; callers show the outcome.

@ProviderFor(CampaignActions)
final campaignActionsProvider = CampaignActionsProvider._();

/// Test sends, retries and cancellations; callers show the outcome.
final class CampaignActionsProvider
    extends $NotifierProvider<CampaignActions, void> {
  /// Test sends, retries and cancellations; callers show the outcome.
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

String _$campaignActionsHash() => r'6f541a73faf7be97df62a4761ce5dc44a33b3c93';

/// Test sends, retries and cancellations; callers show the outcome.

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

/// Sending or scheduling a bulk SMS (#144).

@ProviderFor(SmsCampaignSubmit)
final smsCampaignSubmitProvider = SmsCampaignSubmitProvider._();

/// Sending or scheduling a bulk SMS (#144).
final class SmsCampaignSubmitProvider
    extends $NotifierProvider<SmsCampaignSubmit, AsyncValue<Campaign?>> {
  /// Sending or scheduling a bulk SMS (#144).
  SmsCampaignSubmitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smsCampaignSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smsCampaignSubmitHash();

  @$internal
  @override
  SmsCampaignSubmit create() => SmsCampaignSubmit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Campaign?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Campaign?>>(value),
    );
  }
}

String _$smsCampaignSubmitHash() => r'04fd678ad490d4e6be108bd0c060539961bd2302';

/// Sending or scheduling a bulk SMS (#144).

abstract class _$SmsCampaignSubmit extends $Notifier<AsyncValue<Campaign?>> {
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

/// Sending a bulk email (#145).

@ProviderFor(EmailCampaignSubmit)
final emailCampaignSubmitProvider = EmailCampaignSubmitProvider._();

/// Sending a bulk email (#145).
final class EmailCampaignSubmitProvider
    extends $NotifierProvider<EmailCampaignSubmit, AsyncValue<Campaign?>> {
  /// Sending a bulk email (#145).
  EmailCampaignSubmitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emailCampaignSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emailCampaignSubmitHash();

  @$internal
  @override
  EmailCampaignSubmit create() => EmailCampaignSubmit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Campaign?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Campaign?>>(value),
    );
  }
}

String _$emailCampaignSubmitHash() =>
    r'3f3dc7036c8f28c0cf893f00531b0da1257c22a0';

/// Sending a bulk email (#145).

abstract class _$EmailCampaignSubmit extends $Notifier<AsyncValue<Campaign?>> {
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

/// Buying an SMS credit pack (#147).

@ProviderFor(CreditPurchase)
final creditPurchaseProvider = CreditPurchaseProvider._();

/// Buying an SMS credit pack (#147).
final class CreditPurchaseProvider
    extends $NotifierProvider<CreditPurchase, AsyncValue<MessagingBalance?>> {
  /// Buying an SMS credit pack (#147).
  CreditPurchaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creditPurchaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creditPurchaseHash();

  @$internal
  @override
  CreditPurchase create() => CreditPurchase();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<MessagingBalance?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<MessagingBalance?>>(
        value,
      ),
    );
  }
}

String _$creditPurchaseHash() => r'9be9dac506f9629f7c86f8b49f47e20bbdc4b703';

/// Buying an SMS credit pack (#147).

abstract class _$CreditPurchase
    extends $Notifier<AsyncValue<MessagingBalance?>> {
  AsyncValue<MessagingBalance?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<MessagingBalance?>,
              AsyncValue<MessagingBalance?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<MessagingBalance?>,
                AsyncValue<MessagingBalance?>
              >,
              AsyncValue<MessagingBalance?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(referralRepository)
final referralRepositoryProvider = ReferralRepositoryProvider._();

final class ReferralRepositoryProvider
    extends
        $FunctionalProvider<
          ReferralRepository,
          ReferralRepository,
          ReferralRepository
        >
    with $Provider<ReferralRepository> {
  ReferralRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'referralRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$referralRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReferralRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReferralRepository create(Ref ref) {
    return referralRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReferralRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReferralRepository>(value),
    );
  }
}

String _$referralRepositoryHash() =>
    r'0b0ad1a0b5311c952db5c27ccf6670b58d797664';

@ProviderFor(referralOverview)
final referralOverviewProvider = ReferralOverviewProvider._();

final class ReferralOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReferralOverview>,
          ReferralOverview,
          FutureOr<ReferralOverview>
        >
    with $FutureModifier<ReferralOverview>, $FutureProvider<ReferralOverview> {
  ReferralOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'referralOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$referralOverviewHash();

  @$internal
  @override
  $FutureProviderElement<ReferralOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReferralOverview> create(Ref ref) {
    return referralOverview(ref);
  }
}

String _$referralOverviewHash() => r'2a582b2e18cd5fe05b46861bcab89e8cead1497d';

/// The status chip on the referral list; null shows all.

@ProviderFor(ReferralFilter)
final referralFilterProvider = ReferralFilterProvider._();

/// The status chip on the referral list; null shows all.
final class ReferralFilterProvider
    extends $NotifierProvider<ReferralFilter, ReferralStatus?> {
  /// The status chip on the referral list; null shows all.
  ReferralFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'referralFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$referralFilterHash();

  @$internal
  @override
  ReferralFilter create() => ReferralFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReferralStatus? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReferralStatus?>(value),
    );
  }
}

String _$referralFilterHash() => r'8d6948b7c1703faac2eb2ff050f635ceec3078ac';

/// The status chip on the referral list; null shows all.

abstract class _$ReferralFilter extends $Notifier<ReferralStatus?> {
  ReferralStatus? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReferralStatus?, ReferralStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReferralStatus?, ReferralStatus?>,
              ReferralStatus?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ReferralsNotifier)
final referralsProvider = ReferralsNotifierProvider._();

final class ReferralsNotifierProvider
    extends $AsyncNotifierProvider<ReferralsNotifier, Paged<Referral>> {
  ReferralsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'referralsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$referralsNotifierHash();

  @$internal
  @override
  ReferralsNotifier create() => ReferralsNotifier();
}

String _$referralsNotifierHash() => r'1fd516a3df32dc9621ed568d01b30e2606d95f42';

abstract class _$ReferralsNotifier extends $AsyncNotifier<Paged<Referral>> {
  FutureOr<Paged<Referral>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Referral>>, Paged<Referral>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Referral>>, Paged<Referral>>,
              AsyncValue<Paged<Referral>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(WalletEntriesNotifier)
final walletEntriesProvider = WalletEntriesNotifierProvider._();

final class WalletEntriesNotifierProvider
    extends $AsyncNotifierProvider<WalletEntriesNotifier, Paged<WalletEntry>> {
  WalletEntriesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletEntriesNotifierHash();

  @$internal
  @override
  WalletEntriesNotifier create() => WalletEntriesNotifier();
}

String _$walletEntriesNotifierHash() =>
    r'97ed2a36cbd3bec05b4b682f309aada47e8731d9';

abstract class _$WalletEntriesNotifier
    extends $AsyncNotifier<Paged<WalletEntry>> {
  FutureOr<Paged<WalletEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<WalletEntry>>, Paged<WalletEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<WalletEntry>>, Paged<WalletEntry>>,
              AsyncValue<Paged<WalletEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(referralLeaderboard)
final referralLeaderboardProvider = ReferralLeaderboardProvider._();

final class ReferralLeaderboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeaderboardEntry>>,
          List<LeaderboardEntry>,
          FutureOr<List<LeaderboardEntry>>
        >
    with
        $FutureModifier<List<LeaderboardEntry>>,
        $FutureProvider<List<LeaderboardEntry>> {
  ReferralLeaderboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'referralLeaderboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$referralLeaderboardHash();

  @$internal
  @override
  $FutureProviderElement<List<LeaderboardEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LeaderboardEntry>> create(Ref ref) {
    return referralLeaderboard(ref);
  }
}

String _$referralLeaderboardHash() =>
    r'67aef1c9448197affdc9e9477d4ee3d0dc7ee359';

@ProviderFor(inviteCheck)
final inviteCheckProvider = InviteCheckFamily._();

final class InviteCheckProvider
    extends
        $FunctionalProvider<
          AsyncValue<InviteCheck>,
          InviteCheck,
          FutureOr<InviteCheck>
        >
    with $FutureModifier<InviteCheck>, $FutureProvider<InviteCheck> {
  InviteCheckProvider._({
    required InviteCheckFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inviteCheckProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteCheckHash();

  @override
  String toString() {
    return r'inviteCheckProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InviteCheck> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InviteCheck> create(Ref ref) {
    final argument = this.argument as String;
    return inviteCheck(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InviteCheckProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteCheckHash() => r'c77828a8ab6858ad9f6b662f8a3992ddbff1f086';

final class InviteCheckFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InviteCheck>, String> {
  InviteCheckFamily._()
    : super(
        retry: null,
        name: r'inviteCheckProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InviteCheckProvider call(String contact) =>
      InviteCheckProvider._(argument: contact, from: this);

  @override
  String toString() => r'inviteCheckProvider';
}

/// Sends or records one invite; the data is the referral once saved.

@ProviderFor(InviteNotifier)
final inviteProvider = InviteNotifierProvider._();

/// Sends or records one invite; the data is the referral once saved.
final class InviteNotifierProvider
    extends $AsyncNotifierProvider<InviteNotifier, Referral?> {
  /// Sends or records one invite; the data is the referral once saved.
  InviteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inviteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inviteNotifierHash();

  @$internal
  @override
  InviteNotifier create() => InviteNotifier();
}

String _$inviteNotifierHash() => r'c6b0c871c8f5ffd0a65cea1da11b4cb39b94795a';

/// Sends or records one invite; the data is the referral once saved.

abstract class _$InviteNotifier extends $AsyncNotifier<Referral?> {
  FutureOr<Referral?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Referral?>, Referral?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Referral?>, Referral?>,
              AsyncValue<Referral?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The reward to celebrate once; marked seen as soon as it is shown.

@ProviderFor(PendingRewardNotifier)
final pendingRewardProvider = PendingRewardNotifierProvider._();

/// The reward to celebrate once; marked seen as soon as it is shown.
final class PendingRewardNotifierProvider
    extends $AsyncNotifierProvider<PendingRewardNotifier, RewardMoment?> {
  /// The reward to celebrate once; marked seen as soon as it is shown.
  PendingRewardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRewardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingRewardNotifierHash();

  @$internal
  @override
  PendingRewardNotifier create() => PendingRewardNotifier();
}

String _$pendingRewardNotifierHash() =>
    r'a8271d1e8f83554ba8997ee7014895c3494671f0';

/// The reward to celebrate once; marked seen as soon as it is shown.

abstract class _$PendingRewardNotifier extends $AsyncNotifier<RewardMoment?> {
  FutureOr<RewardMoment?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RewardMoment?>, RewardMoment?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RewardMoment?>, RewardMoment?>,
              AsyncValue<RewardMoment?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$referralsNotifierHash() => r'c99cf914c2a72d454a37e8eff0503072f4d28f9f';

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

@ProviderFor(inviteCheck)
final inviteCheckProvider = InviteCheckFamily._();

final class InviteCheckProvider
    extends
        $FunctionalProvider<
          AsyncValue<InviteEligibility>,
          InviteEligibility,
          FutureOr<InviteEligibility>
        >
    with
        $FutureModifier<InviteEligibility>,
        $FutureProvider<InviteEligibility> {
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
  $FutureProviderElement<InviteEligibility> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InviteEligibility> create(Ref ref) {
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

String _$inviteCheckHash() => r'c56a6d314eca4d801c1a196eac31596be6bdac1d';

final class InviteCheckFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InviteEligibility>, String> {
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

/// Sends or records one invite; the data is the server's answer once saved.

@ProviderFor(InviteNotifier)
final inviteProvider = InviteNotifierProvider._();

/// Sends or records one invite; the data is the server's answer once saved.
final class InviteNotifierProvider
    extends $AsyncNotifierProvider<InviteNotifier, InviteResult?> {
  /// Sends or records one invite; the data is the server's answer once saved.
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

String _$inviteNotifierHash() => r'bb8b4a9bf253b303bfa0ed7a5115179772e5d138';

/// Sends or records one invite; the data is the server's answer once saved.

abstract class _$InviteNotifier extends $AsyncNotifier<InviteResult?> {
  FutureOr<InviteResult?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<InviteResult?>, InviteResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InviteResult?>, InviteResult?>,
              AsyncValue<InviteResult?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

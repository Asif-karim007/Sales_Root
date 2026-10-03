// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trackingRepository)
final trackingRepositoryProvider = TrackingRepositoryProvider._();

final class TrackingRepositoryProvider
    extends
        $FunctionalProvider<
          TrackingRepository,
          TrackingRepository,
          TrackingRepository
        >
    with $Provider<TrackingRepository> {
  TrackingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackingRepositoryHash();

  @$internal
  @override
  $ProviderElement<TrackingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TrackingRepository create(Ref ref) {
    return trackingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackingRepository>(value),
    );
  }
}

String _$trackingRepositoryHash() =>
    r'af3b09db743a99dae250896a6edefc0b0f0d5e50';

@ProviderFor(TrackingSettingsNotifier)
final trackingSettingsProvider = TrackingSettingsNotifierProvider._();

final class TrackingSettingsNotifierProvider
    extends $AsyncNotifierProvider<TrackingSettingsNotifier, TrackingSettings> {
  TrackingSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackingSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackingSettingsNotifierHash();

  @$internal
  @override
  TrackingSettingsNotifier create() => TrackingSettingsNotifier();
}

String _$trackingSettingsNotifierHash() =>
    r'bb70e6443014bcdbe471342e7fdbef2e13598619';

abstract class _$TrackingSettingsNotifier
    extends $AsyncNotifier<TrackingSettings> {
  FutureOr<TrackingSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TrackingSettings>, TrackingSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TrackingSettings>, TrackingSettings>,
              AsyncValue<TrackingSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LiveFilterNotifier)
final liveFilterProvider = LiveFilterNotifierProvider._();

final class LiveFilterNotifierProvider
    extends $NotifierProvider<LiveFilterNotifier, LiveFilter> {
  LiveFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveFilterNotifierHash();

  @$internal
  @override
  LiveFilterNotifier create() => LiveFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveFilter>(value),
    );
  }
}

String _$liveFilterNotifierHash() =>
    r'a22490cb93ab5509af1e0a9d12ef02b9ce94b363';

abstract class _$LiveFilterNotifier extends $Notifier<LiveFilter> {
  LiveFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LiveFilter, LiveFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LiveFilter, LiveFilter>,
              LiveFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Where the team is now, refreshed every minute while the map is open.

@ProviderFor(LiveTeamNotifier)
final liveTeamProvider = LiveTeamNotifierProvider._();

/// Where the team is now, refreshed every minute while the map is open.
final class LiveTeamNotifierProvider
    extends $AsyncNotifierProvider<LiveTeamNotifier, List<LiveMember>> {
  /// Where the team is now, refreshed every minute while the map is open.
  LiveTeamNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveTeamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveTeamNotifierHash();

  @$internal
  @override
  LiveTeamNotifier create() => LiveTeamNotifier();
}

String _$liveTeamNotifierHash() => r'0eb2cd25983f57858fe8ddb76687755e350e654a';

/// Where the team is now, refreshed every minute while the map is open.

abstract class _$LiveTeamNotifier extends $AsyncNotifier<List<LiveMember>> {
  FutureOr<List<LiveMember>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LiveMember>>, List<LiveMember>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LiveMember>>, List<LiveMember>>,
              AsyncValue<List<LiveMember>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(MemberDayDate)
final memberDayDateProvider = MemberDayDateFamily._();

final class MemberDayDateProvider
    extends $NotifierProvider<MemberDayDate, DateTime> {
  MemberDayDateProvider._({
    required MemberDayDateFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'memberDayDateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberDayDateHash();

  @override
  String toString() {
    return r'memberDayDateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MemberDayDate create() => MemberDayDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberDayDateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberDayDateHash() => r'3a6337c6d16768611ed28e1b1c6434bc4f5e914e';

final class MemberDayDateFamily extends $Family
    with
        $ClassFamilyOverride<MemberDayDate, DateTime, DateTime, DateTime, int> {
  MemberDayDateFamily._()
    : super(
        retry: null,
        name: r'memberDayDateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberDayDateProvider call(int memberId) =>
      MemberDayDateProvider._(argument: memberId, from: this);

  @override
  String toString() => r'memberDayDateProvider';
}

abstract class _$MemberDayDate extends $Notifier<DateTime> {
  late final _$args = ref.$arg as int;
  int get memberId => _$args;

  DateTime build(int memberId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(memberDay)
final memberDayProvider = MemberDayFamily._();

final class MemberDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<MemberDay>,
          MemberDay,
          FutureOr<MemberDay>
        >
    with $FutureModifier<MemberDay>, $FutureProvider<MemberDay> {
  MemberDayProvider._({
    required MemberDayFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'memberDayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberDayHash();

  @override
  String toString() {
    return r'memberDayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MemberDay> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MemberDay> create(Ref ref) {
    final argument = this.argument as int;
    return memberDay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberDayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberDayHash() => r'47515273b2cb448867941af9f0de7c8f4ca53d5c';

final class MemberDayFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MemberDay>, int> {
  MemberDayFamily._()
    : super(
        retry: null,
        name: r'memberDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberDayProvider call(int memberId) =>
      MemberDayProvider._(argument: memberId, from: this);

  @override
  String toString() => r'memberDayProvider';
}

@ProviderFor(trackingConsent)
final trackingConsentProvider = TrackingConsentProvider._();

final class TrackingConsentProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrackingConsent>,
          TrackingConsent,
          FutureOr<TrackingConsent>
        >
    with $FutureModifier<TrackingConsent>, $FutureProvider<TrackingConsent> {
  TrackingConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackingConsentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackingConsentHash();

  @$internal
  @override
  $FutureProviderElement<TrackingConsent> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrackingConsent> create(Ref ref) {
    return trackingConsent(ref);
  }
}

String _$trackingConsentHash() => r'8ac728bc53046d5baac94d8c3e204c45fc6e370c';

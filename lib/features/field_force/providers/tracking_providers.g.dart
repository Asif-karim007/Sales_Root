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
    r'd7729ae7cbef782ad63bea62b1eac3e7269a5288';

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
    r'8a8023ce8903f508d4bfee175be0908f3853b47a';

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
    required String super.argument,
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

String _$memberDayDateHash() => r'16664cb2a68740fd187c531a767fe7f4fbf6f1cc';

final class MemberDayDateFamily extends $Family
    with
        $ClassFamilyOverride<
          MemberDayDate,
          DateTime,
          DateTime,
          DateTime,
          String
        > {
  MemberDayDateFamily._()
    : super(
        retry: null,
        name: r'memberDayDateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberDayDateProvider call(String memberId) =>
      MemberDayDateProvider._(argument: memberId, from: this);

  @override
  String toString() => r'memberDayDateProvider';
}

abstract class _$MemberDayDate extends $Notifier<DateTime> {
  late final _$args = ref.$arg as String;
  String get memberId => _$args;

  DateTime build(String memberId);
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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$memberDayHash() => r'a0932be5b3c4e1b011afe31e4d3320fed3ab0b6c';

final class MemberDayFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MemberDay>, String> {
  MemberDayFamily._()
    : super(
        retry: null,
        name: r'memberDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberDayProvider call(String memberId) =>
      MemberDayProvider._(argument: memberId, from: this);

  @override
  String toString() => r'memberDayProvider';
}

/// When this member agreed to live tracking on this phone, if they did.

@ProviderFor(trackingConsent)
final trackingConsentProvider = TrackingConsentProvider._();

/// When this member agreed to live tracking on this phone, if they did.

final class TrackingConsentProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrackingConsent>,
          TrackingConsent,
          FutureOr<TrackingConsent>
        >
    with $FutureModifier<TrackingConsent>, $FutureProvider<TrackingConsent> {
  /// When this member agreed to live tracking on this phone, if they did.
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

String _$trackingConsentHash() => r'2947e87589411f01233e0c4bbad518bc317919a8';

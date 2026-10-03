// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(attendanceRepository)
final attendanceRepositoryProvider = AttendanceRepositoryProvider._();

final class AttendanceRepositoryProvider
    extends
        $FunctionalProvider<
          AttendanceRepository,
          AttendanceRepository,
          AttendanceRepository
        >
    with $Provider<AttendanceRepository> {
  AttendanceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceRepositoryHash();

  @$internal
  @override
  $ProviderElement<AttendanceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AttendanceRepository create(Ref ref) {
    return attendanceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttendanceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttendanceRepository>(value),
    );
  }
}

String _$attendanceRepositoryHash() =>
    r'951949627e8239ec98dc195cc9648e34088cb15b';

/// The user's attendance today: punch in and out, and breaks.

@ProviderFor(AttendanceTodayNotifier)
final attendanceTodayProvider = AttendanceTodayNotifierProvider._();

/// The user's attendance today: punch in and out, and breaks.
final class AttendanceTodayNotifierProvider
    extends $AsyncNotifierProvider<AttendanceTodayNotifier, AttendanceToday> {
  /// The user's attendance today: punch in and out, and breaks.
  AttendanceTodayNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceTodayNotifierHash();

  @$internal
  @override
  AttendanceTodayNotifier create() => AttendanceTodayNotifier();
}

String _$attendanceTodayNotifierHash() =>
    r'af3198831570aba12c7b4bca4d5953006a840b52';

/// The user's attendance today: punch in and out, and breaks.

abstract class _$AttendanceTodayNotifier
    extends $AsyncNotifier<AttendanceToday> {
  FutureOr<AttendanceToday> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AttendanceToday>, AttendanceToday>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AttendanceToday>, AttendanceToday>,
              AsyncValue<AttendanceToday>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AttendanceMonthCursor)
final attendanceMonthCursorProvider = AttendanceMonthCursorProvider._();

final class AttendanceMonthCursorProvider
    extends $NotifierProvider<AttendanceMonthCursor, DateTime> {
  AttendanceMonthCursorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceMonthCursorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceMonthCursorHash();

  @$internal
  @override
  AttendanceMonthCursor create() => AttendanceMonthCursor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$attendanceMonthCursorHash() =>
    r'fbdd0281e9c3c4e36c0cecbf16c69fe4fcba1010';

abstract class _$AttendanceMonthCursor extends $Notifier<DateTime> {
  DateTime build();
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
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AttendanceMonthNotifier)
final attendanceMonthProvider = AttendanceMonthNotifierProvider._();

final class AttendanceMonthNotifierProvider
    extends $AsyncNotifierProvider<AttendanceMonthNotifier, AttendanceMonth> {
  AttendanceMonthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceMonthNotifierHash();

  @$internal
  @override
  AttendanceMonthNotifier create() => AttendanceMonthNotifier();
}

String _$attendanceMonthNotifierHash() =>
    r'5b5d8ffb8bbf03f4cac4a899cc12a84cf17649d1';

abstract class _$AttendanceMonthNotifier
    extends $AsyncNotifier<AttendanceMonth> {
  FutureOr<AttendanceMonth> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AttendanceMonth>, AttendanceMonth>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AttendanceMonth>, AttendanceMonth>,
              AsyncValue<AttendanceMonth>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TeamAttendanceFilter)
final teamAttendanceFilterProvider = TeamAttendanceFilterProvider._();

final class TeamAttendanceFilterProvider
    extends $NotifierProvider<TeamAttendanceFilter, TeamAttendanceQuery> {
  TeamAttendanceFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamAttendanceFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamAttendanceFilterHash();

  @$internal
  @override
  TeamAttendanceFilter create() => TeamAttendanceFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamAttendanceQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamAttendanceQuery>(value),
    );
  }
}

String _$teamAttendanceFilterHash() =>
    r'2c7a37c357addd5c79692a8b07842032167a0c50';

abstract class _$TeamAttendanceFilter extends $Notifier<TeamAttendanceQuery> {
  TeamAttendanceQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TeamAttendanceQuery, TeamAttendanceQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TeamAttendanceQuery, TeamAttendanceQuery>,
              TeamAttendanceQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(teamAttendanceSummary)
final teamAttendanceSummaryProvider = TeamAttendanceSummaryProvider._();

final class TeamAttendanceSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeamAttendanceSummary>,
          TeamAttendanceSummary,
          FutureOr<TeamAttendanceSummary>
        >
    with
        $FutureModifier<TeamAttendanceSummary>,
        $FutureProvider<TeamAttendanceSummary> {
  TeamAttendanceSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamAttendanceSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamAttendanceSummaryHash();

  @$internal
  @override
  $FutureProviderElement<TeamAttendanceSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TeamAttendanceSummary> create(Ref ref) {
    return teamAttendanceSummary(ref);
  }
}

String _$teamAttendanceSummaryHash() =>
    r'af763470364eabb358f8198684ab70011e03b73c';

/// The team's attendance, 20 members at a time.

@ProviderFor(TeamAttendanceNotifier)
final teamAttendanceProvider = TeamAttendanceNotifierProvider._();

/// The team's attendance, 20 members at a time.
final class TeamAttendanceNotifierProvider
    extends
        $AsyncNotifierProvider<
          TeamAttendanceNotifier,
          Paged<TeamAttendanceRow>
        > {
  /// The team's attendance, 20 members at a time.
  TeamAttendanceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamAttendanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamAttendanceNotifierHash();

  @$internal
  @override
  TeamAttendanceNotifier create() => TeamAttendanceNotifier();
}

String _$teamAttendanceNotifierHash() =>
    r'1db7097a17773f88c4412639b108b57e4b1f35db';

/// The team's attendance, 20 members at a time.

abstract class _$TeamAttendanceNotifier
    extends $AsyncNotifier<Paged<TeamAttendanceRow>> {
  FutureOr<Paged<TeamAttendanceRow>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Paged<TeamAttendanceRow>>,
              Paged<TeamAttendanceRow>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Paged<TeamAttendanceRow>>,
                Paged<TeamAttendanceRow>
              >,
              AsyncValue<Paged<TeamAttendanceRow>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

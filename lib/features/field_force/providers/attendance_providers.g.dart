// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fieldApi)
final fieldApiProvider = FieldApiProvider._();

final class FieldApiProvider
    extends $FunctionalProvider<FieldApi, FieldApi, FieldApi>
    with $Provider<FieldApi> {
  FieldApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fieldApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fieldApiHash();

  @$internal
  @override
  $ProviderElement<FieldApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FieldApi create(Ref ref) {
    return fieldApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FieldApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FieldApi>(value),
    );
  }
}

String _$fieldApiHash() => r'3900b1ceda859f9ee0cc20c19b05d7ca2e67d814';

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
    r'e7359c0035c5355f6c1012fa08bf066c2e166762';

/// The user's attendance today: the punch, today's visits and route.

@ProviderFor(AttendanceTodayNotifier)
final attendanceTodayProvider = AttendanceTodayNotifierProvider._();

/// The user's attendance today: the punch, today's visits and route.
final class AttendanceTodayNotifierProvider
    extends $AsyncNotifierProvider<AttendanceTodayNotifier, AttendanceToday> {
  /// The user's attendance today: the punch, today's visits and route.
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
    r'068bd3c287101ebf94d1295ae079425a4d87c201';

/// The user's attendance today: the punch, today's visits and route.

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

/// Saturday to Friday of this week, day by day.

@ProviderFor(attendanceWeek)
final attendanceWeekProvider = AttendanceWeekProvider._();

/// Saturday to Friday of this week, day by day.

final class AttendanceWeekProvider
    extends
        $FunctionalProvider<
          AsyncValue<AttendanceMonth>,
          AttendanceMonth,
          FutureOr<AttendanceMonth>
        >
    with $FutureModifier<AttendanceMonth>, $FutureProvider<AttendanceMonth> {
  /// Saturday to Friday of this week, day by day.
  AttendanceWeekProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceWeekProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceWeekHash();

  @$internal
  @override
  $FutureProviderElement<AttendanceMonth> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AttendanceMonth> create(Ref ref) {
    return attendanceWeek(ref);
  }
}

String _$attendanceWeekHash() => r'e11433a0746ddd16617450c904cea1c4f22153e7';

/// This calendar month's totals.

@ProviderFor(attendanceThisMonth)
final attendanceThisMonthProvider = AttendanceThisMonthProvider._();

/// This calendar month's totals.

final class AttendanceThisMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<AttendanceSummary>,
          AttendanceSummary,
          FutureOr<AttendanceSummary>
        >
    with
        $FutureModifier<AttendanceSummary>,
        $FutureProvider<AttendanceSummary> {
  /// This calendar month's totals.
  AttendanceThisMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceThisMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceThisMonthHash();

  @$internal
  @override
  $FutureProviderElement<AttendanceSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AttendanceSummary> create(Ref ref) {
    return attendanceThisMonth(ref);
  }
}

String _$attendanceThisMonthHash() =>
    r'68018b2b76bbda54ad68edc6780029e576912cc6';

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

@ProviderFor(attendanceMonth)
final attendanceMonthProvider = AttendanceMonthProvider._();

final class AttendanceMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<AttendanceMonth>,
          AttendanceMonth,
          FutureOr<AttendanceMonth>
        >
    with $FutureModifier<AttendanceMonth>, $FutureProvider<AttendanceMonth> {
  AttendanceMonthProvider._()
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
  String debugGetCreateSourceHash() => _$attendanceMonthHash();

  @$internal
  @override
  $FutureProviderElement<AttendanceMonth> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AttendanceMonth> create(Ref ref) {
    return attendanceMonth(ref);
  }
}

String _$attendanceMonthHash() => r'93e76a482e8600d73b424f317ae1b39a7603b565';

@ProviderFor(TeamAttendancePeriod)
final teamAttendancePeriodProvider = TeamAttendancePeriodProvider._();

final class TeamAttendancePeriodProvider
    extends $NotifierProvider<TeamAttendancePeriod, TeamPeriod> {
  TeamAttendancePeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamAttendancePeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamAttendancePeriodHash();

  @$internal
  @override
  TeamAttendancePeriod create() => TeamAttendancePeriod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamPeriod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamPeriod>(value),
    );
  }
}

String _$teamAttendancePeriodHash() =>
    r'c6ffc0a88d48d835ca0a401fcc2d02370c9fe95e';

abstract class _$TeamAttendancePeriod extends $Notifier<TeamPeriod> {
  TeamPeriod build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TeamPeriod, TeamPeriod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TeamPeriod, TeamPeriod>,
              TeamPeriod,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The team's attendance for the chosen period.

@ProviderFor(teamAttendance)
final teamAttendanceProvider = TeamAttendanceProvider._();

/// The team's attendance for the chosen period.

final class TeamAttendanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeamAttendance>,
          TeamAttendance,
          FutureOr<TeamAttendance>
        >
    with $FutureModifier<TeamAttendance>, $FutureProvider<TeamAttendance> {
  /// The team's attendance for the chosen period.
  TeamAttendanceProvider._()
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
  String debugGetCreateSourceHash() => _$teamAttendanceHash();

  @$internal
  @override
  $FutureProviderElement<TeamAttendance> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TeamAttendance> create(Ref ref) {
    return teamAttendance(ref);
  }
}

String _$teamAttendanceHash() => r'a26e6533ac04e371bafbf3760ce173b451cedc38';

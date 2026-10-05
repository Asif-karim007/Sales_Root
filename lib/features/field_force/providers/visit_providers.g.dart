// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(visitRepository)
final visitRepositoryProvider = VisitRepositoryProvider._();

final class VisitRepositoryProvider
    extends
        $FunctionalProvider<VisitRepository, VisitRepository, VisitRepository>
    with $Provider<VisitRepository> {
  VisitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitRepositoryHash();

  @$internal
  @override
  $ProviderElement<VisitRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VisitRepository create(Ref ref) {
    return visitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisitRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisitRepository>(value),
    );
  }
}

String _$visitRepositoryHash() => r'364aea5af4061702abee6fab2ce5cd4fba7e1c10';

/// Today's visits, then the route stops still to visit.

@ProviderFor(todayPlan)
final todayPlanProvider = TodayPlanProvider._();

/// Today's visits, then the route stops still to visit.

final class TodayPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanStop>>,
          List<PlanStop>,
          FutureOr<List<PlanStop>>
        >
    with $FutureModifier<List<PlanStop>>, $FutureProvider<List<PlanStop>> {
  /// Today's visits, then the route stops still to visit.
  TodayPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayPlanHash();

  @$internal
  @override
  $FutureProviderElement<List<PlanStop>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanStop>> create(Ref ref) {
    return todayPlan(ref);
  }
}

String _$todayPlanHash() => r'9894c1af7efd5fc5d376dd0d6ebef566b8575934';

@ProviderFor(visitOutcomes)
final visitOutcomesProvider = VisitOutcomesProvider._();

final class VisitOutcomesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VisitOutcomeOption>>,
          List<VisitOutcomeOption>,
          FutureOr<List<VisitOutcomeOption>>
        >
    with
        $FutureModifier<List<VisitOutcomeOption>>,
        $FutureProvider<List<VisitOutcomeOption>> {
  VisitOutcomesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitOutcomesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitOutcomesHash();

  @$internal
  @override
  $FutureProviderElement<List<VisitOutcomeOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VisitOutcomeOption>> create(Ref ref) {
    return visitOutcomes(ref);
  }
}

String _$visitOutcomesHash() => r'0d0f7ed852f684c880de49f6eea9a68b090ba583';

/// One visit, with the notes and photos taken on this phone during it.

@ProviderFor(VisitDetailNotifier)
final visitDetailProvider = VisitDetailNotifierFamily._();

/// One visit, with the notes and photos taken on this phone during it.
final class VisitDetailNotifierProvider
    extends $AsyncNotifierProvider<VisitDetailNotifier, VisitDraft> {
  /// One visit, with the notes and photos taken on this phone during it.
  VisitDetailNotifierProvider._({
    required VisitDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'visitDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$visitDetailNotifierHash();

  @override
  String toString() {
    return r'visitDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  VisitDetailNotifier create() => VisitDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is VisitDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$visitDetailNotifierHash() =>
    r'd7d2d308389e1ad9494e79e12cf19ea28837456f';

/// One visit, with the notes and photos taken on this phone during it.

final class VisitDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          VisitDetailNotifier,
          AsyncValue<VisitDraft>,
          VisitDraft,
          FutureOr<VisitDraft>,
          String
        > {
  VisitDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'visitDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One visit, with the notes and photos taken on this phone during it.

  VisitDetailNotifierProvider call(String id) =>
      VisitDetailNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'visitDetailProvider';
}

/// One visit, with the notes and photos taken on this phone during it.

abstract class _$VisitDetailNotifier extends $AsyncNotifier<VisitDraft> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<VisitDraft> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<VisitDraft>, VisitDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<VisitDraft>, VisitDraft>,
              AsyncValue<VisitDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The check-in screen: where the phone is against where the customer is.

@ProviderFor(CheckInNotifier)
final checkInProvider = CheckInNotifierFamily._();

/// The check-in screen: where the phone is against where the customer is.
final class CheckInNotifierProvider
    extends $AsyncNotifierProvider<CheckInNotifier, CheckInState> {
  /// The check-in screen: where the phone is against where the customer is.
  CheckInNotifierProvider._({
    required CheckInNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'checkInProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checkInNotifierHash();

  @override
  String toString() {
    return r'checkInProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CheckInNotifier create() => CheckInNotifier();

  @override
  bool operator ==(Object other) {
    return other is CheckInNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkInNotifierHash() => r'4e9183e66473954b00e3038180c998b7b6980e60';

/// The check-in screen: where the phone is against where the customer is.

final class CheckInNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CheckInNotifier,
          AsyncValue<CheckInState>,
          CheckInState,
          FutureOr<CheckInState>,
          String
        > {
  CheckInNotifierFamily._()
    : super(
        retry: null,
        name: r'checkInProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The check-in screen: where the phone is against where the customer is.

  CheckInNotifierProvider call(String companyId) =>
      CheckInNotifierProvider._(argument: companyId, from: this);

  @override
  String toString() => r'checkInProvider';
}

/// The check-in screen: where the phone is against where the customer is.

abstract class _$CheckInNotifier extends $AsyncNotifier<CheckInState> {
  late final _$args = ref.$arg as String;
  String get companyId => _$args;

  FutureOr<CheckInState> build(String companyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CheckInState>, CheckInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CheckInState>, CheckInState>,
              AsyncValue<CheckInState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(VisitReportFilter)
final visitReportFilterProvider = VisitReportFilterProvider._();

final class VisitReportFilterProvider
    extends $NotifierProvider<VisitReportFilter, VisitReportQuery> {
  VisitReportFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitReportFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitReportFilterHash();

  @$internal
  @override
  VisitReportFilter create() => VisitReportFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisitReportQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisitReportQuery>(value),
    );
  }
}

String _$visitReportFilterHash() => r'b60564bd14001a59a8c95faa3b368296ed6bfd82';

abstract class _$VisitReportFilter extends $Notifier<VisitReportQuery> {
  VisitReportQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VisitReportQuery, VisitReportQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VisitReportQuery, VisitReportQuery>,
              VisitReportQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(visitReport)
final visitReportProvider = VisitReportProvider._();

final class VisitReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<VisitReport>,
          VisitReport,
          FutureOr<VisitReport>
        >
    with $FutureModifier<VisitReport>, $FutureProvider<VisitReport> {
  VisitReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitReportHash();

  @$internal
  @override
  $FutureProviderElement<VisitReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VisitReport> create(Ref ref) {
    return visitReport(ref);
  }
}

String _$visitReportHash() => r'da6b9eeb5d7a8dd39ddfd810d72531f193549cc9';

@ProviderFor(visitReportMembers)
final visitReportMembersProvider = VisitReportMembersProvider._();

final class VisitReportMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReportMember>>,
          List<ReportMember>,
          FutureOr<List<ReportMember>>
        >
    with
        $FutureModifier<List<ReportMember>>,
        $FutureProvider<List<ReportMember>> {
  VisitReportMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitReportMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitReportMembersHash();

  @$internal
  @override
  $FutureProviderElement<List<ReportMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReportMember>> create(Ref ref) {
    return visitReportMembers(ref);
  }
}

String _$visitReportMembersHash() =>
    r'154a823b2cd10252a6f57837d48967c265fe8f74';

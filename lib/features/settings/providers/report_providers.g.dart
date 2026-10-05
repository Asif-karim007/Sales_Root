// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user may switch to team-wide numbers.

@ProviderFor(canSeeTeamReports)
final canSeeTeamReportsProvider = CanSeeTeamReportsProvider._();

/// Whether the user may switch to team-wide numbers.

final class CanSeeTeamReportsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the user may switch to team-wide numbers.
  CanSeeTeamReportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canSeeTeamReportsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canSeeTeamReportsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return canSeeTeamReports(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$canSeeTeamReportsHash() => r'8f9bdf173fd9b33cd8d14dfad263cbb6a0edff0e';

/// The period and scope both report screens share.

@ProviderFor(ReportQueryNotifier)
final reportQueryProvider = ReportQueryNotifierProvider._();

/// The period and scope both report screens share.
final class ReportQueryNotifierProvider
    extends $NotifierProvider<ReportQueryNotifier, ReportQuery> {
  /// The period and scope both report screens share.
  ReportQueryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportQueryNotifierHash();

  @$internal
  @override
  ReportQueryNotifier create() => ReportQueryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportQuery>(value),
    );
  }
}

String _$reportQueryNotifierHash() =>
    r'4b939a6cac32336e30bf739bdf0e15a5e9f1160e';

/// The period and scope both report screens share.

abstract class _$ReportQueryNotifier extends $Notifier<ReportQuery> {
  ReportQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReportQuery, ReportQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportQuery, ReportQuery>,
              ReportQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(reportOverview)
final reportOverviewProvider = ReportOverviewProvider._();

final class ReportOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReportOverview>,
          ReportOverview,
          FutureOr<ReportOverview>
        >
    with $FutureModifier<ReportOverview>, $FutureProvider<ReportOverview> {
  ReportOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportOverviewHash();

  @$internal
  @override
  $FutureProviderElement<ReportOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReportOverview> create(Ref ref) {
    return reportOverview(ref);
  }
}

String _$reportOverviewHash() => r'b3b19a50872b2283df16f2d90462da675248c284';

@ProviderFor(salesReport)
final salesReportProvider = SalesReportProvider._();

final class SalesReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<SalesReport>,
          SalesReport,
          FutureOr<SalesReport>
        >
    with $FutureModifier<SalesReport>, $FutureProvider<SalesReport> {
  SalesReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesReportHash();

  @$internal
  @override
  $FutureProviderElement<SalesReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SalesReport> create(Ref ref) {
    return salesReport(ref);
  }
}

String _$salesReportHash() => r'5e414fb0c86e00ee30e889b72d03b85d196289aa';

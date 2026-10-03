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

String _$visitRepositoryHash() => r'74b5181f508f11ff32a6bd8b00014c2f74283472';

/// Today's visits for the signed-in user, in route order.

@ProviderFor(VisitsNotifier)
final visitsProvider = VisitsNotifierProvider._();

/// Today's visits for the signed-in user, in route order.
final class VisitsNotifierProvider
    extends $AsyncNotifierProvider<VisitsNotifier, Paged<Visit>> {
  /// Today's visits for the signed-in user, in route order.
  VisitsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitsNotifierHash();

  @$internal
  @override
  VisitsNotifier create() => VisitsNotifier();
}

String _$visitsNotifierHash() => r'590e50a1f7a5a10422f22850f349984d7c696804';

/// Today's visits for the signed-in user, in route order.

abstract class _$VisitsNotifier extends $AsyncNotifier<Paged<Visit>> {
  FutureOr<Paged<Visit>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Visit>>, Paged<Visit>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Visit>>, Paged<Visit>>,
              AsyncValue<Paged<Visit>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// One visit, with the actions taken during it.

@ProviderFor(VisitDetailNotifier)
final visitDetailProvider = VisitDetailNotifierFamily._();

/// One visit, with the actions taken during it.
final class VisitDetailNotifierProvider
    extends $AsyncNotifierProvider<VisitDetailNotifier, Visit> {
  /// One visit, with the actions taken during it.
  VisitDetailNotifierProvider._({
    required VisitDetailNotifierFamily super.from,
    required int super.argument,
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
    r'2517c7901585259dc31ffad69371c09501391b9e';

/// One visit, with the actions taken during it.

final class VisitDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          VisitDetailNotifier,
          AsyncValue<Visit>,
          Visit,
          FutureOr<Visit>,
          int
        > {
  VisitDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'visitDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One visit, with the actions taken during it.

  VisitDetailNotifierProvider call(int id) =>
      VisitDetailNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'visitDetailProvider';
}

/// One visit, with the actions taken during it.

abstract class _$VisitDetailNotifier extends $AsyncNotifier<Visit> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<Visit> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Visit>, Visit>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Visit>, Visit>,
              AsyncValue<Visit>,
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
    required int super.argument,
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

String _$checkInNotifierHash() => r'4968898c94c38ccb288fcd072b161f39dbcb5b05';

/// The check-in screen: where the phone is against where the customer is.

final class CheckInNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CheckInNotifier,
          AsyncValue<CheckInState>,
          CheckInState,
          FutureOr<CheckInState>,
          int
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

  CheckInNotifierProvider call(int visitId) =>
      CheckInNotifierProvider._(argument: visitId, from: this);

  @override
  String toString() => r'checkInProvider';
}

/// The check-in screen: where the phone is against where the customer is.

abstract class _$CheckInNotifier extends $AsyncNotifier<CheckInState> {
  late final _$args = ref.$arg as int;
  int get visitId => _$args;

  FutureOr<CheckInState> build(int visitId);
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

String _$visitReportFilterHash() => r'c1a34ad90eaea08751bbb538cadb8952bbf09862';

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

@ProviderFor(visitProducts)
final visitProductsProvider = VisitProductsProvider._();

final class VisitProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VisitProduct>>,
          List<VisitProduct>,
          FutureOr<List<VisitProduct>>
        >
    with
        $FutureModifier<List<VisitProduct>>,
        $FutureProvider<List<VisitProduct>> {
  VisitProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<VisitProduct>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VisitProduct>> create(Ref ref) {
    return visitProducts(ref);
  }
}

String _$visitProductsHash() => r'fcdd4cc57e77b01eb8a1857988c54a20f26c8df3';

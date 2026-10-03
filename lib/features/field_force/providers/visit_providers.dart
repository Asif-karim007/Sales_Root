import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/field_force/data/fake_visit_repository.dart';
import 'package:salesroot/features/field_force/data/visit_repository.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';
import 'package:salesroot/features/field_force/providers/location_providers.dart';
import 'package:salesroot/features/field_force/providers/tracking_providers.dart';
import 'package:salesroot/features/field_force/service/geo.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';

part 'visit_providers.g.dart';

@Riverpod(keepAlive: true)
VisitRepository visitRepository(Ref ref) =>
    FakeVisitRepository(ref.watch(fakeBackendProvider));

/// Today's visits for the signed-in user, in route order.
@riverpod
class VisitsNotifier extends _$VisitsNotifier {
  VisitQuery get _query => VisitQuery(day: DateTime.now());

  @override
  Future<Paged<Visit>> build() async =>
      Paged.first(await ref.watch(visitRepositoryProvider).list(_query));

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(visitRepositoryProvider)
          .list(_query.copyWith(page: current.page + 1));
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Visit> create(VisitInput input) async {
    final visit = await ref.read(visitRepositoryProvider).create(input);
    if (ref.mounted) ref.invalidateSelf();
    return visit;
  }

  /// Moves the stop at [from] to [to] (counted after removing it) and saves
  /// the new order; reverts if the save fails.
  Future<void> move(int from, int to) async {
    final current = state.value;
    if (current == null) return;
    final items = [...current.items];
    items.insert(to, items.removeAt(from));
    state = AsyncData(
      Paged(
        items: items,
        page: current.page,
        totalCount: current.totalCount,
        facets: current.facets,
      ),
    );
    try {
      await ref.read(visitRepositoryProvider).reorder([
        for (final visit in items) visit.id,
      ]);
    } on ApiFailure {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
  }
}

/// One visit, with the actions taken during it.
@riverpod
class VisitDetailNotifier extends _$VisitDetailNotifier {
  @override
  Future<Visit> build(int id) => ref.watch(visitRepositoryProvider).get(id);

  Future<void> addNote(String text) =>
      _apply(() => ref.read(visitRepositoryProvider).addNote(id, text));

  Future<void> addPhoto(String path) =>
      _apply(() => ref.read(visitRepositoryProvider).addPhoto(id, path));

  Future<void> setSamples(List<int> productIds) => _apply(
    () => ref.read(visitRepositoryProvider).setSamples(id, productIds),
  );

  /// Ends the visit where the phone is. A missing fix doesn't block it.
  Future<Visit> checkOut({VisitOutcome? outcome, String? note}) async {
    final location = ref.read(locationSourceProvider);
    GeoFix? fix;
    try {
      fix = await location.current();
    } on LocationFailure {
      fix = null;
    }
    final visit = await ref
        .read(visitRepositoryProvider)
        .checkOut(
          id,
          VisitEndInput(
            latitude: fix?.latitude,
            longitude: fix?.longitude,
            outcome: outcome,
            note: note,
          ),
        );
    if (!ref.mounted) return visit;
    state = AsyncData(visit);
    ref.invalidate(visitsProvider);
    return visit;
  }

  Future<void> _apply(Future<Visit> Function() change) async {
    final visit = await change();
    if (!ref.mounted) return;
    state = AsyncData(visit);
  }
}

class CheckInState {
  const CheckInState({
    required this.visit,
    required this.radius,
    this.fix,
    this.issue,
    this.locating = false,
    this.photoPath,
    this.note,
  });

  final Visit visit;

  /// Metres from the customer beyond which a check-in is far.
  final int radius;
  final GeoFix? fix;
  final LocationIssue? issue;
  final bool locating;
  final String? photoPath;
  final String? note;

  /// Metres between the phone and the customer, once both are known.
  int? get distance {
    final fix = this.fix;
    final lat = visit.latitude;
    final lng = visit.longitude;
    if (fix == null || lat == null || lng == null) return null;
    return distanceMetres(fix.latitude, fix.longitude, lat, lng).round();
  }

  bool get isFar {
    final distance = this.distance;
    return distance != null && isFarCheckIn(distance, radius: radius);
  }

  CheckInState copyWith({
    GeoFix? Function()? fix,
    LocationIssue? Function()? issue,
    bool? locating,
    String? Function()? photoPath,
    String? Function()? note,
  }) => CheckInState(
    visit: visit,
    radius: radius,
    fix: fix != null ? fix() : this.fix,
    issue: issue != null ? issue() : this.issue,
    locating: locating ?? this.locating,
    photoPath: photoPath != null ? photoPath() : this.photoPath,
    note: note != null ? note() : this.note,
  );
}

/// The check-in screen: where the phone is against where the customer is.
@riverpod
class CheckInNotifier extends _$CheckInNotifier {
  @override
  Future<CheckInState> build(int visitId) async {
    final visit = await ref.watch(visitRepositoryProvider).get(visitId);
    final settings = await ref.watch(trackingSettingsProvider.future);
    Future.microtask(locate);
    return CheckInState(
      visit: visit,
      radius: settings.checkInRadius,
      locating: true,
    );
  }

  Future<void> locate() async {
    final current = await future;
    if (!ref.mounted) return;
    state = AsyncData(current.copyWith(locating: true));
    try {
      final fix = await ref.read(locationSourceProvider).current();
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(fix: () => fix, issue: () => null, locating: false),
      );
    } on LocationFailure catch (failure) {
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(issue: () => failure.issue, locating: false),
      );
    }
  }

  void setPhoto(String? path) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(photoPath: () => path));
  }

  void setNote(String? text) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(note: () => text));
  }

  /// Checks in at the current fix. A far check-in carries [reason].
  Future<Visit> submit({String? reason}) async {
    final current = state.requireValue;
    final fix = current.fix;
    final distance = current.distance;
    if (fix == null || distance == null) {
      throw const LocationFailure(LocationIssue.unavailable);
    }
    final place = await ref
        .read(locationSourceProvider)
        .placeName(fix.latitude, fix.longitude);
    final visit = await ref
        .read(visitRepositoryProvider)
        .checkIn(
          visitId,
          VisitCheckInInput(
            latitude: fix.latitude,
            longitude: fix.longitude,
            accuracy: fix.accuracy,
            distance: distance,
            location: place,
            isFar: current.isFar,
            reason: reason,
            photoPath: current.photoPath,
            note: current.note,
          ),
        );
    if (!ref.mounted) return visit;
    ref.invalidate(visitsProvider);
    ref.invalidate(visitDetailProvider(visitId));
    return visit;
  }
}

@riverpod
class VisitReportFilter extends _$VisitReportFilter {
  @override
  VisitReportQuery build() => const VisitReportQuery();

  void setPeriod(ReportPeriod period) => state = state.copyWith(period: period);

  void setMember(int? memberId) =>
      state = state.copyWith(memberId: () => memberId);

  void toggleFar() => state = state.copyWith(farOnly: !state.farOnly);
}

@riverpod
Future<VisitReport> visitReport(Ref ref) => ref
    .watch(visitRepositoryProvider)
    .report(ref.watch(visitReportFilterProvider));

@riverpod
Future<List<ReportMember>> visitReportMembers(Ref ref) =>
    ref.watch(visitRepositoryProvider).members();

@riverpod
Future<List<VisitProduct>> visitProducts(Ref ref) =>
    ref.watch(visitRepositoryProvider).products();

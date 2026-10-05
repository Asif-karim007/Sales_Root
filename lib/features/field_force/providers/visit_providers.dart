import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/features/field_force/data/api_visit_repository.dart';
import 'package:salesroot/features/field_force/data/visit_repository.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/providers/location_providers.dart';
import 'package:salesroot/features/field_force/service/geo.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';

part 'visit_providers.g.dart';

@Riverpod(keepAlive: true)
VisitRepository visitRepository(Ref ref) =>
    ApiVisitRepository(ref.watch(fieldApiProvider), me: fieldMember(ref));

/// Today's visits, then the route stops still to visit.
@riverpod
Future<List<PlanStop>> todayPlan(Ref ref) async {
  final today = await ref.watch(attendanceTodayProvider.future);
  return dayPlan(today.visits, today.stops);
}

@riverpod
Future<List<VisitOutcomeOption>> visitOutcomes(Ref ref) =>
    ref.watch(visitRepositoryProvider).outcomes();

/// One visit, with the notes and photos taken on this phone during it.
@riverpod
class VisitDetailNotifier extends _$VisitDetailNotifier {
  @override
  Future<VisitDraft> build(String id) async =>
      VisitDraft(visit: await ref.watch(visitRepositoryProvider).get(id));

  void addNote(String text) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        notes: [
          ...current.notes,
          VisitNote(text: text, time: DateTime.now()),
        ],
      ),
    );
  }

  void addPhoto(String path) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(photoPaths: [...current.photoPaths, path]),
    );
  }

  /// Ends the visit where the phone is, with the notes and photos taken
  /// during it. A missing fix doesn't block it.
  Future<Visit> checkOut({required String outcome, String? note}) async {
    final draft = state.requireValue;
    final location = ref.read(locationSourceProvider);
    GeoFix? fix;
    try {
      fix = await location.current();
    } on LocationFailure {
      fix = null;
    }
    final text = [
      for (final n in draft.notes) n.text,
      if (note != null && note.trim().isNotEmpty) note.trim(),
    ].join('\n');
    final visit = await ref
        .read(visitRepositoryProvider)
        .end(
          id,
          VisitEndInput(
            outcome: outcome,
            latitude: fix?.latitude,
            longitude: fix?.longitude,
            note: text,
          ),
          photoPaths: draft.photoPaths,
        );
    if (!ref.mounted) return visit;
    state = AsyncData(VisitDraft(visit: visit));
    ref.invalidate(attendanceTodayProvider);
    return visit;
  }
}

class CheckInState {
  const CheckInState({
    required this.target,
    required this.radius,
    this.fix,
    this.issue,
    this.locating = false,
  });

  final VisitTarget target;

  /// Metres from the customer beyond which a check-in is far.
  final int radius;
  final GeoFix? fix;
  final LocationIssue? issue;
  final bool locating;

  /// Metres between the phone and the customer, once both are known.
  int? get distance {
    final fix = this.fix;
    final lat = target.latitude;
    final lng = target.longitude;
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
  }) => CheckInState(
    target: target,
    radius: radius,
    fix: fix != null ? fix() : this.fix,
    issue: issue != null ? issue() : this.issue,
    locating: locating ?? this.locating,
  );
}

/// The check-in screen: where the phone is against where the customer is.
@riverpod
class CheckInNotifier extends _$CheckInNotifier {
  @override
  Future<CheckInState> build(String companyId) async {
    final repository = ref.watch(visitRepositoryProvider);
    final target = repository.target(companyId);
    final today = ref.watch(attendanceTodayProvider.future);
    await Future.wait([target, today]);
    Future.microtask(locate);
    return CheckInState(
      target: await target,
      radius: (await today).settings.geofenceMetres,
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

  /// Starts the visit at the current fix.
  Future<Visit> submit({String? leadId, String? routeStopId}) async {
    final fix = state.requireValue.fix;
    if (fix == null) throw const LocationFailure(LocationIssue.unavailable);
    final visit = await ref
        .read(visitRepositoryProvider)
        .start(
          VisitStartInput(
            companyId: companyId,
            leadId: leadId,
            routeStopId: routeStopId,
            latitude: fix.latitude,
            longitude: fix.longitude,
          ),
        );
    if (ref.mounted) ref.invalidate(attendanceTodayProvider);
    return visit;
  }
}

@riverpod
class VisitReportFilter extends _$VisitReportFilter {
  @override
  VisitReportQuery build() => const VisitReportQuery();

  void setPeriod(ReportPeriod period) => state = state.copyWith(period: period);

  void setMember(String? memberId) =>
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

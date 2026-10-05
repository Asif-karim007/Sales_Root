import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum VisitStatus { planned, inProgress, done }

/// One field visit: started at a customer, then ended with an outcome.
class Visit {
  const Visit({
    required this.id,
    this.memberId,
    this.memberName,
    this.companyId,
    this.companyName,
    this.leadId,
    this.leadName,
    this.startedAt,
    this.endedAt,
    this.startLatitude,
    this.startLongitude,
    this.locationMismatch = false,
    this.outcome,
    this.note,
    this.photos = const [],
    this.routeStopId,
  });

  final String id;
  final String? memberId;
  final String? memberName;
  final String? companyId;
  final String? companyName;
  final String? leadId;
  final String? leadName;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? startLatitude;
  final double? startLongitude;

  /// The server found the start too far from the customer.
  final bool locationMismatch;

  /// A key of the workspace's visit outcomes.
  final String? outcome;
  final String? note;

  /// Uploaded file keys.
  final List<String> photos;
  final String? routeStopId;

  VisitStatus get status =>
      endedAt == null ? VisitStatus.inProgress : VisitStatus.done;
  bool get isOpen => status == VisitStatus.inProgress;
  bool get isDone => status == VisitStatus.done;

  String get title => companyName ?? leadName ?? '';

  int? get durationMinutes {
    final start = startedAt;
    final end = endedAt;
    if (start == null || end == null) return null;
    return end.difference(start).inMinutes;
  }

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
    id: jsonId(json['id']) ?? '',
    memberId: jsonId(json['membershipId']),
    memberName: json['byName'] as String?,
    companyId: jsonId(json['companyId']),
    companyName: json['companyName'] as String?,
    leadId: jsonId(json['leadId']),
    leadName: json['leadName'] as String?,
    startedAt: jsonDate(json['startedAt']),
    endedAt: jsonDate(json['endedAt']),
    startLatitude: jsonDouble(json['startLat']),
    startLongitude: jsonDouble(json['startLng']),
    locationMismatch: jsonBool(json['locationMismatch']),
    outcome: json['outcome'] as String?,
    note: json['note'] as String?,
    photos: jsonStrings(json['photos']),
    routeStopId: jsonId(json['routeStopId']),
  );
}

/// A customer on today's route plan.
class RouteStop {
  const RouteStop({
    required this.id,
    required this.companyId,
    required this.name,
    this.area,
    this.latitude,
    this.longitude,
    this.order = 0,
  });

  final String id;
  final String companyId;
  final String name;
  final String? area;
  final double? latitude;
  final double? longitude;
  final int order;

  static RouteStop? fromJson(Map<String, dynamic> json) {
    final companyId = jsonId(json['companyId']);
    if (companyId == null) return null;
    return RouteStop(
      id: jsonId(json['id']) ?? companyId,
      companyId: companyId,
      name: json['companyName'] as String? ?? json['name'] as String? ?? '',
      area: json['area'] as String?,
      latitude: jsonDouble(json['lat']),
      longitude: jsonDouble(json['lng']),
      order: jsonInt(json['seq']) ?? 0,
    );
  }
}

/// One line of today's plan: a visit already started, or a route stop still
/// to visit.
class PlanStop {
  const PlanStop({
    required this.title,
    required this.status,
    this.visit,
    this.stop,
    this.companyId,
    this.area,
    this.latitude,
    this.longitude,
    this.time,
  });

  factory PlanStop.ofVisit(Visit visit) => PlanStop(
    title: visit.title,
    status: visit.status,
    visit: visit,
    companyId: visit.companyId,
    latitude: visit.startLatitude,
    longitude: visit.startLongitude,
    time: visit.startedAt,
  );

  factory PlanStop.ofStop(RouteStop stop) => PlanStop(
    title: stop.name,
    status: VisitStatus.planned,
    stop: stop,
    companyId: stop.companyId,
    area: stop.area,
    latitude: stop.latitude,
    longitude: stop.longitude,
  );

  final String title;
  final VisitStatus status;
  final Visit? visit;
  final RouteStop? stop;
  final String? companyId;
  final String? area;
  final double? latitude;
  final double? longitude;
  final DateTime? time;

  bool get isDone => status == VisitStatus.done;

  /// A stable key for lists and map pins.
  String get key => visit?.id ?? 'stop-${stop?.id}';
}

/// Today's visits in the order they started, then the route stops nobody
/// has visited yet.
List<PlanStop> dayPlan(List<Visit> visits, List<RouteStop> stops) {
  final started = [...visits]
    ..sort(
      (a, b) =>
          (a.startedAt ?? DateTime(0)).compareTo(b.startedAt ?? DateTime(0)),
    );
  final visitedStops = {for (final v in visits) ?v.routeStopId};
  final visitedCompanies = {for (final v in visits) ?v.companyId};
  return [
    for (final visit in started) PlanStop.ofVisit(visit),
    for (final stop in stops)
      if (!visitedStops.contains(stop.id) &&
          !visitedCompanies.contains(stop.companyId))
        PlanStop.ofStop(stop),
  ];
}

/// A visit outcome from the workspace's industry pack.
class VisitOutcomeOption {
  const VisitOutcomeOption({
    required this.key,
    required this.name,
    this.productive = false,
  });

  final String key;
  final LocalizedName name;

  /// Counts as a productive visit in the field report.
  final bool productive;

  factory VisitOutcomeOption.fromJson(Map<String, dynamic> json) =>
      VisitOutcomeOption(
        key: json['key'] as String? ?? '',
        name: LocalizedName.of(json),
        productive: jsonBool(json['productive']),
      );

  /// `pack.visitOutcomes` in the workspace's `settings` JSON.
  static List<VisitOutcomeOption> ofWorkspace(Map<String, dynamic> workspace) =>
      jsonList(
        jsonMap(jsonMap(workspace['settings'])['pack'])['visitOutcomes'],
        VisitOutcomeOption.fromJson,
      ).where((o) => o.key.isNotEmpty).toList();
}

/// A customer the user can visit, with where it is.
class VisitTarget {
  const VisitTarget({
    required this.companyId,
    required this.companyName,
    this.area,
    this.address,
    this.latitude,
    this.longitude,
    this.leadId,
    this.leadTitle,
  });

  final String companyId;
  final String companyName;
  final String? area;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? leadId;
  final String? leadTitle;

  VisitTarget withLead(String? id, String? title) => VisitTarget(
    companyId: companyId,
    companyName: companyName,
    area: area,
    address: address,
    latitude: latitude,
    longitude: longitude,
    leadId: id,
    leadTitle: title,
  );

  /// A company row, or the `company` of `GET companies/{id}`.
  factory VisitTarget.fromCompany(Map<String, dynamic> json) => VisitTarget(
    companyId: jsonId(json['id']) ?? '',
    companyName: json['name'] as String? ?? '',
    area: _blankToNull(json['area'] as String?),
    address: _blankToNull(json['address'] as String?),
    latitude: jsonDouble(json['lat']),
    longitude: jsonDouble(json['lng']),
  );
}

/// What `POST visits/start` sends.
class VisitStartInput {
  const VisitStartInput({
    required this.companyId,
    this.leadId,
    this.routeStopId,
    this.latitude,
    this.longitude,
  });

  final String companyId;
  final String? leadId;
  final String? routeStopId;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'leadId': leadId,
    'routeStopId': routeStopId,
    'lat': latitude,
    'lng': longitude,
  }..removeWhere((_, value) => value == null);
}

/// What `POST visits/{id}/end` sends.
class VisitEndInput {
  const VisitEndInput({
    required this.outcome,
    this.latitude,
    this.longitude,
    this.note,
    this.photos = const [],
  });

  final String outcome;
  final double? latitude;
  final double? longitude;
  final String? note;

  /// Uploaded file keys.
  final List<String> photos;

  Map<String, dynamic> toJson() => {
    'outcome': outcome,
    'note': _blankToNull(note),
    'lat': latitude,
    'lng': longitude,
    'photos': photos,
  }..removeWhere((_, value) => value == null);
}

/// A note typed during a visit, sent with the check-out.
class VisitNote {
  const VisitNote({required this.text, required this.time});

  final String text;
  final DateTime time;
}

/// An open or finished visit, with what was captured on this phone during
/// it.
class VisitDraft {
  const VisitDraft({
    required this.visit,
    this.notes = const [],
    this.photoPaths = const [],
  });

  final Visit visit;
  final List<VisitNote> notes;

  /// Photos on this phone, uploaded at check-out.
  final List<String> photoPaths;

  VisitDraft copyWith({
    Visit? visit,
    List<VisitNote>? notes,
    List<String>? photoPaths,
  }) => VisitDraft(
    visit: visit ?? this.visit,
    notes: notes ?? this.notes,
    photoPaths: photoPaths ?? this.photoPaths,
  );
}

/// Filters and paging for `GET visits`.
class VisitQuery {
  const VisitQuery({
    this.from,
    this.to,
    this.memberId,
    this.page = 1,
    this.size = pageSize,
  });

  final DateTime? from;
  final DateTime? to;
  final String? memberId;
  final int page;
  final int size;

  Map<String, dynamic> toQuery() {
    final from = this.from;
    final to = this.to;
    return {
      'from': from == null ? null : AppDateUtils.toApiDateOnly(from),
      'to': to == null ? null : AppDateUtils.toApiDateOnly(to),
      'membershipId': memberId,
      ...pageQuery(page, size: size),
    }..removeWhere((_, value) => value == null);
  }
}

String? _blankToNull(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}

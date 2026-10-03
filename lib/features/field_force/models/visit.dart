import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum VisitStatus {
  planned('Planned'),
  inProgress('InProgress'),
  done('Done'),
  missed('Missed');

  const VisitStatus(this.wire);

  final String wire;

  static VisitStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => VisitStatus.planned,
  );
}

/// How a visit ended. A check-out without one is stored as [ignored].
enum VisitOutcome {
  interested('Interested'),
  order('Order'),
  comeBackLater('ComeBackLater'),
  notInterested('NotInterested'),
  ignored('Ignored');

  const VisitOutcome(this.wire);

  final String wire;

  static const choices = [interested, order, comeBackLater, notInterested];

  static VisitOutcome? fromWire(String? value) {
    for (final outcome in values) {
      if (outcome.wire == value) return outcome;
    }
    return null;
  }
}

/// An `{Id, Name}` pair: the lead or company a visit points at.
class VisitRef {
  const VisitRef({required this.id, required this.name});

  final int id;
  final String name;

  factory VisitRef.fromJson(Map<String, dynamic> json) => VisitRef(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
  );
}

class VisitEmployee {
  const VisitEmployee({required this.id, required this.name});

  final int id;
  final LocalizedName name;

  factory VisitEmployee.fromJson(Map<String, dynamic> json) => VisitEmployee(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
  );
}

/// Where and when a visit was checked in or out.
class VisitPoint {
  const VisitPoint({this.latitude, this.longitude, this.location, this.time});

  final double? latitude;
  final double? longitude;
  final String? location;
  final DateTime? time;

  factory VisitPoint.fromJson(Map<String, dynamic> json) => VisitPoint(
    latitude: jsonDouble(json['Latitude']),
    longitude: jsonDouble(json['Longitude']),
    location: json['Location'] as String?,
    time: jsonDate(json['Time']),
  );
}

class VisitPhoto {
  const VisitPhoto({required this.id, required this.path, this.takenAt});

  final int id;

  /// A file on this phone until the upload API exists.
  final String path;
  final DateTime? takenAt;

  factory VisitPhoto.fromJson(Map<String, dynamic> json) => VisitPhoto(
    id: jsonInt(json['Id']) ?? 0,
    path: json['Path'] as String? ?? '',
    takenAt: jsonDate(json['TakenAt']),
  );
}

class VisitNote {
  const VisitNote({required this.id, required this.text, this.time});

  final int id;
  final String text;
  final DateTime? time;

  factory VisitNote.fromJson(Map<String, dynamic> json) => VisitNote(
    id: jsonInt(json['Id']) ?? 0,
    text: json['Text'] as String? ?? '',
    time: jsonDate(json['Time']),
  );
}

/// One field visit: planned against a lead, then checked in and out at the
/// customer's location.
class Visit {
  const Visit({
    required this.id,
    required this.status,
    this.employee,
    this.lead,
    this.company,
    this.contactName,
    this.area,
    this.address,
    this.latitude,
    this.longitude,
    this.plannedAt,
    this.purpose,
    this.start,
    this.end,
    this.durationMinutes,
    this.checkInDistance,
    this.isFarCheckIn = false,
    this.farReason,
    this.outcome,
    this.note,
    this.photos = const [],
    this.notes = const [],
    this.sampleProductIds = const [],
    this.canEdit = false,
    this.canDelete = false,
  });

  final int id;
  final VisitStatus status;
  final VisitEmployee? employee;
  final VisitRef? lead;
  final VisitRef? company;
  final String? contactName;
  final LocalizedName? area;
  final String? address;

  /// The customer's location the check-in distance is measured from.
  final double? latitude;
  final double? longitude;
  final DateTime? plannedAt;
  final String? purpose;
  final VisitPoint? start;
  final VisitPoint? end;
  final int? durationMinutes;

  /// Metres between the check-in fix and the customer, measured by the server.
  final int? checkInDistance;
  final bool isFarCheckIn;
  final String? farReason;
  final VisitOutcome? outcome;
  final String? note;
  final List<VisitPhoto> photos;
  final List<VisitNote> notes;
  final List<int> sampleProductIds;
  final bool canEdit;
  final bool canDelete;

  bool get isOpen => status == VisitStatus.inProgress;
  bool get isDone => status == VisitStatus.done;

  String get title => company?.name ?? lead?.name ?? '';

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
    id: jsonInt(json['Id']) ?? 0,
    status: VisitStatus.fromWire(json['Status'] as String?),
    employee: jsonObject(json['Employee'], VisitEmployee.fromJson),
    lead: jsonObject(json['Lead'], VisitRef.fromJson),
    company: jsonObject(json['Company'], VisitRef.fromJson),
    contactName: json['ContactName'] as String?,
    area: jsonObject(json['Area'], LocalizedName.fromJson),
    address: json['Address'] as String?,
    latitude: jsonDouble(json['Latitude']),
    longitude: jsonDouble(json['Longitude']),
    plannedAt: jsonDate(json['PlannedAt']),
    purpose: json['Purpose'] as String?,
    start: jsonObject(json['Start'], VisitPoint.fromJson),
    end: jsonObject(json['End'], VisitPoint.fromJson),
    durationMinutes: jsonInt(json['DurationMinutes']),
    checkInDistance: jsonInt(json['CheckInDistance']),
    isFarCheckIn: jsonBool(json['IsFarCheckIn']),
    farReason: json['FarReason'] as String?,
    outcome: VisitOutcome.fromWire(json['Outcome'] as String?),
    note: json['Note'] as String?,
    photos: jsonList(json['Photos'], VisitPhoto.fromJson),
    notes: jsonList(json['Notes'], VisitNote.fromJson),
    sampleProductIds: jsonInts(json['SampleProductIds']),
    canEdit: jsonBool(json['CanEdit']),
    canDelete: jsonBool(json['CanDelete']),
  );
}

/// What `POST /visits` sends to plan a visit.
class VisitInput {
  const VisitInput({this.leadId, this.plannedAt, this.purpose});

  final int? leadId;
  final DateTime? plannedAt;
  final String? purpose;

  Map<String, dynamic> toJson() => {
    'LeadId': leadId,
    'PlannedAt': jsonUtc(plannedAt),
    'Purpose': _blankToNull(purpose),
  }..removeWhere((_, value) => value == null);
}

/// What the check-in sends: the fix, how far it is from the customer, and
/// for a far check-in the reason and a photo.
class VisitCheckInInput {
  const VisitCheckInInput({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.distance,
    this.location,
    this.isFar = false,
    this.reason,
    this.photoPath,
    this.note,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final int distance;
  final String? location;
  final bool isFar;
  final String? reason;
  final String? photoPath;
  final String? note;

  Map<String, dynamic> toJson() => {
    'Latitude': latitude,
    'Longitude': longitude,
    'Accuracy': accuracy,
    'Distance': distance,
    'Location': location,
    'IsFar': isFar,
    'FarReason': _blankToNull(reason),
    'PhotoPath': photoPath,
    'Note': _blankToNull(note),
  }..removeWhere((_, value) => value == null);
}

/// What the check-out sends. A blank outcome is stored as "Ignored", so the
/// visit report never shows an empty cell.
class VisitEndInput {
  const VisitEndInput({
    this.latitude,
    this.longitude,
    this.location,
    this.outcome,
    this.note,
  });

  final double? latitude;
  final double? longitude;
  final String? location;
  final VisitOutcome? outcome;
  final String? note;

  Map<String, dynamic> toJson() => {
    'Latitude': latitude,
    'Longitude': longitude,
    'Location': location,
    'Outcome': (outcome ?? VisitOutcome.ignored).wire,
    'Note': _blankToNull(note),
  }..removeWhere((_, value) => value == null);
}

/// A lead the user can plan a visit to.
class VisitTarget {
  const VisitTarget({
    required this.leadId,
    required this.leadTitle,
    required this.companyId,
    required this.companyName,
    this.area,
  });

  final int leadId;
  final String leadTitle;
  final int companyId;
  final String companyName;
  final LocalizedName? area;

  factory VisitTarget.fromJson(Map<String, dynamic> json) => VisitTarget(
    leadId: jsonInt(json['LeadId']) ?? 0,
    leadTitle: json['LeadTitle'] as String? ?? '',
    companyId: jsonInt(json['CompanyId']) ?? 0,
    companyName: json['CompanyName'] as String? ?? '',
    area: jsonObject(json['Area'], LocalizedName.fromJson),
  );
}

class VisitProduct {
  const VisitProduct({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  factory VisitProduct.fromJson(Map<String, dynamic> json) => VisitProduct(
    id: jsonInt(json['Id']) ?? 0,
    code: json['Code'] as String? ?? '',
    name: json['Name'] as String? ?? '',
  );
}

/// Filters and paging for `GET /visits`: one member's visits on one day.
class VisitQuery {
  const VisitQuery({required this.day, this.memberId, this.page = 1});

  final DateTime day;
  final int? memberId;
  final int page;

  VisitQuery copyWith({int? page}) =>
      VisitQuery(day: day, memberId: memberId, page: page ?? this.page);

  Map<String, dynamic> toQuery() => {
    'date': AppDateUtils.toApiDateOnly(day),
    'employeeId': memberId,
    'page': page,
    'pageSize': 20,
  }..removeWhere((_, value) => value == null);
}

String? _blankToNull(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}

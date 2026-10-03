import 'package:salesroot/core/utils/json_fields.dart';

enum ReportPeriod { week, month }

class VisitReportQuery {
  const VisitReportQuery({
    this.period = ReportPeriod.week,
    this.memberId,
    this.farOnly = false,
  });

  final ReportPeriod period;
  final int? memberId;
  final bool farOnly;

  VisitReportQuery copyWith({
    ReportPeriod? period,
    int? Function()? memberId,
    bool? farOnly,
  }) => VisitReportQuery(
    period: period ?? this.period,
    memberId: memberId != null ? memberId() : this.memberId,
    farOnly: farOnly ?? this.farOnly,
  );

  Map<String, dynamic> toQuery() =>
      {'period': period.name, 'employeeId': memberId, 'farOnly': farOnly}
        ..removeWhere((_, value) => value == null);
}

class MemberVisitStat {
  const MemberVisitStat({
    required this.memberId,
    required this.name,
    required this.planned,
    required this.done,
    required this.far,
  });

  final int memberId;
  final LocalizedName name;
  final int planned;
  final int done;
  final int far;

  double get ratio => planned == 0 ? 0 : done / planned;

  factory MemberVisitStat.fromJson(Map<String, dynamic> json) =>
      MemberVisitStat(
        memberId: jsonInt(json['MemberId']) ?? 0,
        name: LocalizedName.fromJson(json),
        planned: jsonInt(json['Planned']) ?? 0,
        done: jsonInt(json['Done']) ?? 0,
        far: jsonInt(json['Far']) ?? 0,
      );
}

class FarCheckIn {
  const FarCheckIn({
    required this.visitId,
    required this.memberId,
    required this.memberName,
    required this.company,
    required this.distance,
    this.date,
    this.reason,
  });

  final int visitId;
  final int memberId;
  final LocalizedName memberName;
  final String company;
  final int distance;
  final DateTime? date;
  final String? reason;

  factory FarCheckIn.fromJson(Map<String, dynamic> json) => FarCheckIn(
    visitId: jsonInt(json['VisitId']) ?? 0,
    memberId: jsonInt(json['MemberId']) ?? 0,
    memberName: LocalizedName(
      json['MemberName'] as String? ?? '',
      json['MemberNameBn'] as String? ?? '',
    ),
    company: json['Company'] as String? ?? '',
    distance: jsonInt(json['Distance']) ?? 0,
    date: jsonDate(json['Date']),
    reason: json['Reason'] as String?,
  );
}

/// Planned, done, missed and far check-ins over a period.
class VisitReport {
  const VisitReport({
    required this.from,
    required this.to,
    required this.planned,
    required this.done,
    required this.missed,
    required this.far,
    required this.byMember,
    required this.farCheckIns,
  });

  final DateTime from;
  final DateTime to;
  final int planned;
  final int done;
  final int missed;
  final int far;
  final List<MemberVisitStat> byMember;
  final List<FarCheckIn> farCheckIns;

  factory VisitReport.fromJson(Map<String, dynamic> json) => VisitReport(
    from: jsonDate(json['From']) ?? DateTime(2000),
    to: jsonDate(json['To']) ?? DateTime(2000),
    planned: jsonInt(json['Planned']) ?? 0,
    done: jsonInt(json['Done']) ?? 0,
    missed: jsonInt(json['Missed']) ?? 0,
    far: jsonInt(json['Far']) ?? 0,
    byMember: jsonList(json['ByMember'], MemberVisitStat.fromJson),
    farCheckIns: jsonList(json['FarCheckIns'], FarCheckIn.fromJson),
  );
}

/// A team member to filter by.
class ReportMember {
  const ReportMember({required this.id, required this.name});

  final int id;
  final LocalizedName name;

  factory ReportMember.fromJson(Map<String, dynamic> json) => ReportMember(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
  );
}

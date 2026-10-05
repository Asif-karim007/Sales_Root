import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/visit.dart';

enum ReportPeriod { week, month }

class VisitReportQuery {
  const VisitReportQuery({
    this.period = ReportPeriod.week,
    this.memberId,
    this.farOnly = false,
  });

  final ReportPeriod period;
  final String? memberId;
  final bool farOnly;

  VisitReportQuery copyWith({
    ReportPeriod? period,
    String? Function()? memberId,
    bool? farOnly,
  }) => VisitReportQuery(
    period: period ?? this.period,
    memberId: memberId != null ? memberId() : this.memberId,
    farOnly: farOnly ?? this.farOnly,
  );

  /// The period's first and last day around [today]: Saturday to Friday,
  /// or the calendar month.
  (DateTime, DateTime) range(DateTime today) {
    final day = AppDateUtils.dateOnly(today);
    return switch (period) {
      ReportPeriod.week => weekAround(day),
      ReportPeriod.month => (
        DateTime(day.year, day.month),
        DateTime(day.year, day.month + 1, 0),
      ),
    };
  }
}

/// Saturday to Friday of the week holding [day].
(DateTime, DateTime) weekAround(DateTime day) {
  final start = DateTime(
    day.year,
    day.month,
    day.day - (day.weekday - DateTime.saturday) % 7,
  );
  return (start, DateTime(start.year, start.month, start.day + 6));
}

class MemberVisitStat {
  const MemberVisitStat({
    required this.memberId,
    required this.name,
    required this.visits,
    required this.productive,
  });

  final String memberId;
  final String name;
  final int visits;
  final int productive;

  double get ratio => visits == 0 ? 0 : productive / visits;
}

/// A visit started too far from its customer.
class FarCheckIn {
  const FarCheckIn({
    required this.visitId,
    required this.memberName,
    required this.company,
    this.memberId,
    this.date,
  });

  final String visitId;
  final String? memberId;
  final String memberName;
  final String company;
  final DateTime? date;

  factory FarCheckIn.of(Visit visit) => FarCheckIn(
    visitId: visit.id,
    memberId: visit.memberId,
    memberName: visit.memberName ?? '',
    company: visit.title,
    date: visit.startedAt,
  );
}

/// Visits, productive visits and far check-ins over a period.
class VisitReport {
  const VisitReport({
    required this.from,
    required this.to,
    required this.visits,
    required this.productive,
    required this.far,
    required this.byMember,
    required this.farCheckIns,
  });

  final DateTime from;
  final DateTime to;
  final int visits;
  final int productive;
  final int far;
  final List<MemberVisitStat> byMember;
  final List<FarCheckIn> farCheckIns;

  factory VisitReport.of(
    FieldReport report, {
    required DateTime from,
    required DateTime to,
    required List<Visit> farVisits,
  }) => VisitReport(
    from: from,
    to: to,
    visits: report.visits,
    productive: report.productiveVisits,
    far: report.locationMismatch,
    byMember: [
      for (final person in report.people)
        if (person.visits > 0)
          MemberVisitStat(
            memberId: person.memberId,
            name: person.name,
            visits: person.visits,
            productive: person.productiveVisits,
          ),
    ],
    farCheckIns: [for (final visit in farVisits) FarCheckIn.of(visit)],
  );
}

/// A team member to filter by.
class ReportMember {
  const ReportMember({required this.id, required this.name});

  final String id;
  final String name;

  factory ReportMember.fromJson(Map<String, dynamic> json) => ReportMember(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? '',
  );
}

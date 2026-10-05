import 'package:salesroot/core/utils/json_fields.dart';

/// The team lead's view of today: activity, sleeping leads, who is working
/// and how many requests wait for them.
class TeamSummary {
  const TeamSummary({
    this.activityToday = 0,
    this.noFollowUp = 0,
    this.targetPercent,
    this.members = const [],
    this.approvalsCount = 0,
  });

  /// Calls and visits by the team so far today.
  final int activityToday;

  /// Open leads nobody has followed up on for a week or more.
  final int noFollowUp;

  /// Null while the team has no sales target.
  final int? targetPercent;
  final List<MemberToday> members;
  final int approvalsCount;
}

enum MemberDayStatus { active, late, absent }

/// One row of `GET attendance` for today.
class MemberToday {
  const MemberToday({
    required this.memberId,
    required this.name,
    required this.calls,
    required this.visits,
    required this.status,
    this.checkInAt,
  });

  final String memberId;
  final String name;
  final int calls;
  final int visits;
  final MemberDayStatus status;
  final DateTime? checkInAt;

  /// [calls] comes from the activity report, which attendance lacks.
  factory MemberToday.fromJson(Map<String, dynamic> json, {int calls = 0}) {
    final checkInAt = jsonDate(json['checkInAt']);
    return MemberToday(
      memberId: jsonId(json['membershipId']) ?? '',
      name: json['name'] as String? ?? '',
      calls: calls,
      visits: jsonInt(json['visits']) ?? 0,
      status: json['status'] == 'late'
          ? MemberDayStatus.late
          : checkInAt == null
          ? MemberDayStatus.absent
          : MemberDayStatus.active,
      checkInAt: checkInAt,
    );
  }
}

/// The numbers of `GET ai/daily-summary` for one day, scoped to the caller's
/// team.
class DayNumbers {
  const DayNumbers({
    this.calls = 0,
    this.visits = 0,
    this.newLeads = 0,
    this.present = 0,
    this.late = 0,
    this.teamSize = 0,
    this.pendingApprovals = 0,
  });

  final int calls;
  final int visits;
  final int newLeads;
  final int present;
  final int late;
  final int teamSize;
  final int pendingApprovals;

  factory DayNumbers.fromJson(Map<String, dynamic> json) {
    final numbers = jsonMap(json['numbers']);
    int count(String key) => jsonInt(numbers[key]) ?? 0;
    return DayNumbers(
      calls: count('calls'),
      visits: count('visits'),
      newLeads: count('newLeads'),
      present: count('present'),
      late: count('late'),
      teamSize: count('teamSize'),
      pendingApprovals: count('pendingApprovals'),
    );
  }
}

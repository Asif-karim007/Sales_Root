import 'package:salesroot/core/utils/json_fields.dart';

/// The team lead's view of today: activity, silent leads, members and the
/// requests waiting for them.
class TeamSummary {
  const TeamSummary({
    this.activityToday = 0,
    this.noFollowUp = 0,
    this.targetPercent = 0,
    this.members = const [],
    this.approvals = const [],
    this.approvalsCount = 0,
  });

  final int activityToday;

  /// Open leads nobody has touched for seven days or more.
  final int noFollowUp;
  final int targetPercent;
  final List<MemberToday> members;
  final List<PendingApproval> approvals;
  final int approvalsCount;

  factory TeamSummary.fromJson(Map<String, dynamic> json) => TeamSummary(
    activityToday: jsonInt(json['ActivityToday']) ?? 0,
    noFollowUp: jsonInt(json['NoFollowUp']) ?? 0,
    targetPercent: jsonInt(json['TargetPercent']) ?? 0,
    members: jsonList(json['Members'], MemberToday.fromJson),
    approvals: jsonList(json['Approvals'], PendingApproval.fromJson),
    approvalsCount: jsonInt(json['ApprovalsCount']) ?? 0,
  );
}

enum MemberDayStatus {
  active('Active'),
  late('Late'),
  absent('Absent');

  const MemberDayStatus(this.wire);

  final String wire;

  static MemberDayStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => MemberDayStatus.absent,
  );
}

class MemberToday {
  const MemberToday({
    required this.memberId,
    required this.name,
    required this.calls,
    required this.visits,
    required this.status,
    this.checkInAt,
  });

  final int memberId;
  final LocalizedName name;
  final int calls;
  final int visits;
  final MemberDayStatus status;
  final DateTime? checkInAt;

  factory MemberToday.fromJson(Map<String, dynamic> json) => MemberToday(
    memberId: jsonInt(json['MemberId']) ?? 0,
    name: LocalizedName.fromJson(json),
    calls: jsonInt(json['Calls']) ?? 0,
    visits: jsonInt(json['Visits']) ?? 0,
    status: MemberDayStatus.fromWire(json['Status'] as String?),
    checkInAt: jsonDate(json['CheckInAt']),
  );
}

enum ApprovalKind {
  leave('Leave'),
  expense('Expense');

  const ApprovalKind(this.wire);

  final String wire;

  static ApprovalKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => ApprovalKind.expense,
  );
}

class PendingApproval {
  const PendingApproval({
    required this.id,
    required this.kind,
    required this.memberName,
    this.amount,
    this.from,
    this.to,
  });

  final int id;
  final ApprovalKind kind;
  final LocalizedName memberName;
  final int? amount;
  final DateTime? from;
  final DateTime? to;

  factory PendingApproval.fromJson(Map<String, dynamic> json) =>
      PendingApproval(
        id: jsonInt(json['Id']) ?? 0,
        kind: ApprovalKind.fromWire(json['Kind'] as String?),
        memberName: LocalizedName(
          json['MemberName'] as String? ?? '',
          json['MemberNameBn'] as String? ?? '',
        ),
        amount: jsonInt(json['Amount']),
        from: jsonDate(json['From']),
        to: jsonDate(json['To']),
      );
}

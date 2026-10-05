import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// The server's workspace roles, as the team screens show and assign them.
enum MemberRole {
  owner('owner'),
  teamLead('teamlead'),
  executive('executive'),
  finance('finance');

  const MemberRole(this.wire);

  final String wire;

  static MemberRole fromWire(String? value) => switch (value) {
    'owner' || 'admin' => MemberRole.owner,
    'teamlead' || 'manager' => MemberRole.teamLead,
    'finance' => MemberRole.finance,
    _ => MemberRole.executive,
  };

  /// The roles an owner or team lead can give someone.
  static const assignable = [
    MemberRole.executive,
    MemberRole.teamLead,
    MemberRole.finance,
  ];
}

/// A membership's standing in the workspace, as the server keeps it.
abstract final class MembershipStatus {
  static const active = 'active';
  static const invited = 'invited';
  static const suspended = 'suspended';
  static const removed = 'removed';
}

/// Where the member is today, from attendance.
enum MemberStatus { active, notStarted, onLeave, deactivated }

/// One row of `GET workspaces/members`, plus what the list gives about the
/// rest of the team (manager name, report count) and today's attendance.
class Member {
  const Member({
    required this.id,
    required this.name,
    this.userId,
    this.phone,
    this.designation,
    this.role = MemberRole.executive,
    this.level = ExperienceLevel.easy,
    this.membership = MembershipStatus.active,
    this.managerId,
    this.managerName,
    this.area,
    this.status = MemberStatus.notStarted,
    this.reportCount = 0,
    this.joiningDate,
    this.inviteExpiresAt,
    this.imageUrl,
    this.isMe = false,
    this.stats,
  });

  /// The membership id.
  final String id;
  final String? userId;
  final LocalizedName name;
  final String? phone;
  final String? designation;
  final MemberRole role;
  final ExperienceLevel level;

  /// One of [MembershipStatus].
  final String membership;
  final String? managerId;
  final LocalizedName? managerName;

  /// The member's team, else their territory.
  final String? area;
  final MemberStatus status;
  final int reportCount;
  final DateTime? joiningDate;
  final DateTime? inviteExpiresAt;
  final String? imageUrl;

  /// This member is the signed-in user.
  final bool isMe;

  /// Only the detail call fills this, and only for people the caller's
  /// reports cover.
  final MemberStats? stats;

  bool get isOwner => role == MemberRole.owner;
  bool get isTeamLead => role == MemberRole.teamLead;
  bool get isActive => membership == MembershipStatus.active;
  bool get isInvited => membership == MembershipStatus.invited;
  bool get isRemoved => membership == MembershipStatus.removed;
  bool get canEdit => !isOwner;
  bool get canDelete => !isOwner && !isMe;

  factory Member.fromJson(Map<String, dynamic> json) {
    final membership = json['status'] as String? ?? MembershipStatus.active;
    final territory = jsonStrings(json['territory']);
    return Member(
      id: jsonId(json['id']) ?? '',
      userId: jsonId(json['userId']),
      name: LocalizedName.pair(json),
      phone: json['phone'] as String?,
      designation: json['designation'] as String?,
      role: MemberRole.fromWire(json['role'] as String?),
      level:
          ExperienceLevel.fromWire(json['level'] as String?) ??
          ExperienceLevel.easy,
      membership: membership,
      managerId: jsonId(json['reportsTo']),
      area:
          json['teamName'] as String? ??
          (territory.isEmpty ? null : territory.join(', ')),
      status: membership == MembershipStatus.active
          ? MemberStatus.notStarted
          : MemberStatus.deactivated,
      joiningDate: jsonDate(json['joinedAt']),
      inviteExpiresAt: jsonDate(json['inviteExpiresAt']),
      imageUrl: json['photoUrl'] as String?,
    );
  }

  Member copyWith({
    LocalizedName? managerName,
    MemberStatus? status,
    int? reportCount,
    bool? isMe,
    MemberStats? stats,
  }) => Member(
    id: id,
    userId: userId,
    name: name,
    phone: phone,
    designation: designation,
    role: role,
    level: level,
    membership: membership,
    managerId: managerId,
    managerName: managerName ?? this.managerName,
    area: area,
    status: status ?? this.status,
    reportCount: reportCount ?? this.reportCount,
    joiningDate: joiningDate,
    inviteExpiresAt: inviteExpiresAt,
    imageUrl: imageUrl,
    isMe: isMe ?? this.isMe,
    stats: stats ?? this.stats,
  );
}

/// This month's numbers for one member, from `GET targets` plus the open
/// lead and overdue task totals.
class MemberStats {
  const MemberStats({
    this.leadsThisMonth = 0,
    this.wonValue = 0,
    this.collected = 0,
    this.openLeads = 0,
    this.overdueTasks = 0,
  });

  final int leadsThisMonth;
  final double wonValue;
  final double collected;
  final int openLeads;
  final int overdueTasks;

  /// One of `GET targets` → `people`.
  factory MemberStats.fromJson(
    Map<String, dynamic> json, {
    int openLeads = 0,
    int overdueTasks = 0,
  }) => MemberStats(
    leadsThisMonth: jsonInt(json['newLeads']) ?? 0,
    wonValue: jsonDouble(json['sales']) ?? 0,
    collected: jsonDouble(json['collection']) ?? 0,
    openLeads: openLeads,
    overdueTasks: overdueTasks,
  );
}

enum MemberFilter {
  all('all'),
  activeToday('activeToday'),
  pending('pending'),
  teamLeads('teamLeads');

  const MemberFilter(this.wire);

  final String wire;

  bool includes(Member member) => switch (this) {
    MemberFilter.all => true,
    MemberFilter.activeToday => member.status == MemberStatus.active,
    MemberFilter.pending => false,
    MemberFilter.teamLeads => member.isTeamLead,
  };
}

class MemberQuery {
  const MemberQuery({this.filter = MemberFilter.all});

  final MemberFilter filter;
}

/// A change to one member (`UpdateMember`); only the given fields are sent.
class MemberUpdate {
  const MemberUpdate({
    this.role,
    this.level,
    this.managerId,
    this.status,
    this.successorId,
  });

  final MemberRole? role;
  final ExperienceLevel? level;
  final String? managerId;

  /// One of [MembershipStatus].
  final String? status;

  /// Who takes over a removed member's work.
  final String? successorId;

  Map<String, dynamic> toJson() => {
    'role': role?.wire,
    'level': level?.wire,
    'reportsTo': managerId,
    'status': status,
    'successorId': successorId,
  }..removeWhere((_, value) => value == null);
}

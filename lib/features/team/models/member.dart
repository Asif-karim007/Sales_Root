import 'package:collection/collection.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

enum MemberStatus {
  active('Active'),
  notStarted('NotStarted'),
  onLeave('OnLeave'),
  offline('Offline'),
  deactivated('Deactivated');

  const MemberStatus(this.wire);

  final String wire;

  static MemberStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => MemberStatus.notStarted,
  );
}

/// A person in the workspace, in the shape of SaleBee's directory employee
/// plus the team fields (role, level, manager, today's status).
class Member {
  const Member({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.designation,
    this.role = WorkspaceRole.member,
    this.level = ExperienceLevel.easy,
    this.managerId,
    this.managerName,
    this.area,
    this.status = MemberStatus.notStarted,
    this.offlineDays = 0,
    this.reportCount = 0,
    this.isActive = true,
    this.joiningDate,
    this.dutyStart,
    this.dutyEnd,
    this.trackingConsent = false,
    this.imageUrl,
    this.canEdit = false,
    this.canDelete = false,
    this.isMe = false,
    this.stats,
  });

  final int id;
  final LocalizedName name;
  final String? phone;
  final String? email;
  final String? designation;
  final WorkspaceRole role;
  final ExperienceLevel level;
  final int? managerId;
  final LocalizedName? managerName;
  final LocalizedName? area;
  final MemberStatus status;
  final int offlineDays;
  final int reportCount;
  final bool isActive;
  final DateTime? joiningDate;
  final String? dutyStart;
  final String? dutyEnd;
  final bool trackingConsent;
  final String? imageUrl;
  final bool canEdit;
  final bool canDelete;

  /// This member is the signed-in user.
  final bool isMe;

  /// Only the detail call fills this.
  final MemberStats? stats;

  bool get isOwner => role == WorkspaceRole.owner;
  bool get isTeamLead => role == WorkspaceRole.teamLead;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    phone: jsonStrings(json['PhoneNumbers']).firstOrNull,
    email: jsonStrings(json['Emails']).firstOrNull,
    designation: json['Designation'] as String?,
    role: WorkspaceRole.fromWire(json['Role'] as String?),
    level:
        ExperienceLevel.fromWire(json['Level'] as String?) ??
        ExperienceLevel.easy,
    managerId: jsonInt(json['ManagerId']),
    managerName: json['ManagerName'] == null
        ? null
        : LocalizedName(
            json['ManagerName'] as String? ?? '',
            json['ManagerNameBn'] as String? ?? '',
          ),
    area: json['Area'] == null
        ? null
        : LocalizedName(
            json['Area'] as String? ?? '',
            json['AreaBn'] as String? ?? '',
          ),
    status: MemberStatus.fromWire(json['StatusToday'] as String?),
    offlineDays: jsonInt(json['OfflineDays']) ?? 0,
    reportCount: jsonInt(json['ReportCount']) ?? 0,
    isActive: json['IsActive'] != false,
    joiningDate: jsonDate(json['JoiningDate']),
    dutyStart: json['DutyStart'] as String?,
    dutyEnd: json['DutyEnd'] as String?,
    trackingConsent: jsonBool(json['TrackingConsent']),
    imageUrl: json['ImageUrl'] as String?,
    canEdit: jsonBool(json['CanEdit']),
    canDelete: jsonBool(json['CanDelete']),
    isMe: jsonBool(json['IsMe']),
    stats: jsonObject(json['Stats'], MemberStats.fromJson),
  );
}

class MemberStats {
  const MemberStats({
    this.leadsThisMonth = 0,
    this.wonValue = 0,
    this.attendanceDays = 0,
    this.workingDays = 0,
    this.openLeads = 0,
    this.openLeadValue = 0,
    this.openTasks = 0,
    this.overdueTasks = 0,
    this.todayVisits = 0,
  });

  final int leadsThisMonth;
  final int wonValue;
  final int attendanceDays;
  final int workingDays;
  final int openLeads;
  final int openLeadValue;
  final int openTasks;
  final int overdueTasks;
  final int todayVisits;

  factory MemberStats.fromJson(Map<String, dynamic> json) => MemberStats(
    leadsThisMonth: jsonInt(json['LeadsThisMonth']) ?? 0,
    wonValue: jsonInt(json['WonValue']) ?? 0,
    attendanceDays: jsonInt(json['AttendanceDays']) ?? 0,
    workingDays: jsonInt(json['WorkingDays']) ?? 0,
    openLeads: jsonInt(json['OpenLeads']) ?? 0,
    openLeadValue: jsonInt(json['OpenLeadValue']) ?? 0,
    openTasks: jsonInt(json['OpenTasks']) ?? 0,
    overdueTasks: jsonInt(json['OverdueTasks']) ?? 0,
    todayVisits: jsonInt(json['TodayVisits']) ?? 0,
  );
}

enum MemberFilter {
  all('All'),
  activeToday('ActiveToday'),
  pending('Pending'),
  teamLeads('TeamLeads');

  const MemberFilter(this.wire);

  final String wire;
}

class MemberQuery {
  const MemberQuery({this.filter = MemberFilter.all, this.page = 1});

  final MemberFilter filter;
  final int page;

  Map<String, dynamic> toQuery() => {
    'Filter': filter.wire,
    'Page': page,
    'PageSize': 20,
  };
}

/// A change to one member; only the given fields are sent.
class MemberUpdate {
  const MemberUpdate({this.role, this.level, this.managerId, this.isActive});

  final WorkspaceRole? role;
  final ExperienceLevel? level;
  final int? managerId;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
    'Role': role?.wire,
    'Level': level?.wire,
    'ManagerId': managerId,
    'IsActive': isActive,
  }..removeWhere((_, value) => value == null);
}

class RemovalInput {
  const RemovalInput({
    required this.reassignToId,
    this.reassignLeads = true,
    this.reassignTasks = true,
    this.reassignVisits = true,
    this.keepChatHistory = true,
    this.keepContactsCopy = false,
    this.reason,
  });

  final int? reassignToId;
  final bool reassignLeads;
  final bool reassignTasks;
  final bool reassignVisits;
  final bool keepChatHistory;
  final bool keepContactsCopy;
  final String? reason;

  Map<String, dynamic> toJson() {
    final reason = this.reason?.trim() ?? '';
    return {
      'ReassignToId': reassignToId,
      'ReassignLeads': reassignLeads,
      'ReassignTasks': reassignTasks,
      'ReassignVisits': reassignVisits,
      'KeepChatHistory': keepChatHistory,
      'KeepContactsCopy': keepContactsCopy,
      'Reason': reason.isEmpty ? null : reason,
    }..removeWhere((_, value) => value == null);
  }
}

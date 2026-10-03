import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum WorkspaceKind { personal, team }

enum WorkspaceRole {
  owner('Owner'),
  teamLead('TeamLead'),
  member('Member');

  const WorkspaceRole(this.wire);

  final String wire;

  static WorkspaceRole fromWire(String? value) => values.firstWhere(
    (role) => role.wire == value,
    orElse: () => WorkspaceRole.member,
  );
}

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.kind,
    required this.role,
    this.memberCount = 1,
    this.leadCount = 0,
    this.lockedLevel,
    this.ownerName,
  });

  final int id;
  final String name;
  final WorkspaceKind kind;
  final WorkspaceRole role;
  final int memberCount;
  final int leadCount;

  /// Set when the owner has fixed everyone's experience level.
  final ExperienceLevel? lockedLevel;
  final String? ownerName;

  bool get isPersonal => kind == WorkspaceKind.personal;

  factory Workspace.fromJson(Map<String, dynamic> json) => Workspace(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    kind: json['Kind'] == 'Team' ? WorkspaceKind.team : WorkspaceKind.personal,
    role: WorkspaceRole.fromWire(json['Role'] as String?),
    memberCount: jsonInt(json['MemberCount']) ?? 1,
    leadCount: jsonInt(json['LeadCount']) ?? 0,
    lockedLevel: ExperienceLevel.fromWire(json['LockedLevel'] as String?),
    ownerName: json['OwnerName'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    'Kind': kind == WorkspaceKind.team ? 'Team' : 'Personal',
    'Role': role.wire,
    'MemberCount': memberCount,
    'LeadCount': leadCount,
    'LockedLevel': lockedLevel?.wire,
    'OwnerName': ownerName,
  }..removeWhere((_, value) => value == null);
}

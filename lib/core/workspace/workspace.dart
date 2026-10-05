import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum WorkspaceKind { personal, team }

/// The three ways the app is shaped for a role. The server's finer role is
/// kept in [Workspace.roleKey].
enum WorkspaceRole {
  owner('owner'),
  teamLead('teamlead'),
  member('executive');

  const WorkspaceRole(this.wire);

  final String wire;

  static WorkspaceRole fromWire(String? value) => switch (value) {
    'owner' || 'admin' => WorkspaceRole.owner,
    'teamlead' || 'manager' => WorkspaceRole.teamLead,
    _ => WorkspaceRole.member,
  };
}

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.kind,
    required this.role,
    this.roleKey = 'executive',
    this.membershipId,
    this.level,
    this.lockedLevel,
    this.plan,
    this.planStatus,
    this.layers = const [],
    this.industryPack,
    this.currency = 'BDT',
    this.timezone,
    this.memberCount = 1,
    this.leadCount = 0,
    this.ownerName,
  });

  final String id;
  final String name;
  final WorkspaceKind kind;
  final WorkspaceRole role;

  /// The server's role: owner, admin, teamlead, manager, executive, finance…
  final String roleKey;
  final String? membershipId;

  /// The member's own experience level here.
  final ExperienceLevel? level;

  /// Set when the owner has fixed everyone's experience level.
  final ExperienceLevel? lockedLevel;
  final String? plan;
  final String? planStatus;

  /// The plan's feature layers: sales, collection, fieldforce, growth…
  final List<String> layers;
  final String? industryPack;
  final String currency;
  final String? timezone;
  final int memberCount;
  final int leadCount;
  final String? ownerName;

  bool get isPersonal => kind == WorkspaceKind.personal;

  bool get isFinance => roleKey == 'finance';

  Set<AddOn> get addOns => {
    if (layers.contains('fieldforce')) AddOn.fieldForce,
    if (layers.contains('growth')) AddOn.growth,
  };

  factory Workspace.fromJson(Map<String, dynamic> json) {
    final roleKey = json['role'] as String? ?? 'executive';
    final locked = jsonBool(json['levelLocked']);
    return Workspace(
      id: jsonId(json['id']) ?? '',
      name: json['name'] as String? ?? '',
      kind: json['type'] == 'personal'
          ? WorkspaceKind.personal
          : WorkspaceKind.team,
      role: WorkspaceRole.fromWire(roleKey),
      roleKey: roleKey,
      membershipId: jsonId(json['membershipId']),
      level: ExperienceLevel.fromWire(json['level'] as String?),
      lockedLevel: locked
          ? ExperienceLevel.fromWire(
              (json['defaultLevel'] ?? json['level']) as String?,
            )
          : null,
      plan: json['plan'] as String?,
      planStatus: json['planStatus'] as String?,
      layers: jsonStrings(json['layers']),
      industryPack: json['industryPack'] as String?,
      currency: json['currency'] as String? ?? 'BDT',
      timezone: json['timezone'] as String?,
      memberCount: jsonInt(json['memberCount']) ?? 1,
      leadCount: jsonInt(json['leadCount']) ?? 0,
      ownerName: json['ownerName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Workspace &&
      other.id == id &&
      other.name == name &&
      other.roleKey == roleKey &&
      other.level == level &&
      other.lockedLevel == lockedLevel &&
      other.plan == plan &&
      other.planStatus == planStatus &&
      other.layers.join(',') == layers.join(',') &&
      other.industryPack == industryPack &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(id, name, roleKey, level, plan);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': kind == WorkspaceKind.personal ? 'personal' : 'sme',
    'role': roleKey,
    'membershipId': membershipId,
    'level': level?.wire,
    'levelLocked': lockedLevel != null,
    'defaultLevel': lockedLevel?.wire,
    'plan': plan,
    'planStatus': planStatus,
    'layers': layers,
    'industryPack': industryPack,
    'currency': currency,
    'timezone': timezone,
    'memberCount': memberCount,
    'leadCount': leadCount,
    'ownerName': ownerName,
  }..removeWhere((_, value) => value == null);
}

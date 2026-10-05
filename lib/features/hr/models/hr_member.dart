import 'package:salesroot/core/utils/json_fields.dart';

/// A workspace member as `workspaces/members` sends them.
class HrMember {
  const HrMember({
    required this.id,
    required this.name,
    this.designation,
    this.reportsTo,
    this.joinedAt,
  });

  /// The membership id.
  final String id;
  final String name;
  final String? designation;

  /// The membership id of the member's manager.
  final String? reportsTo;
  final DateTime? joinedAt;

  factory HrMember.fromJson(Map<String, dynamic> json) => HrMember(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? '',
    designation: json['designation'] as String?,
    reportsTo: jsonId(json['reportsTo']),
    joinedAt: jsonDate(json['joinedAt']),
  );
}

extension HrMembers on List<HrMember> {
  HrMember? byId(String? id) =>
      id == null ? null : where((m) => m.id == id).firstOrNull;

  /// Who approves [id]'s requests: their manager.
  HrMember? managerOf(String? id) => byId(byId(id)?.reportsTo);
}

import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

class Invitation {
  const Invitation({
    required this.code,
    required this.workspaceId,
    required this.workspaceName,
    required this.inviter,
    required this.role,
    required this.memberCount,
  });

  final String code;
  final int workspaceId;
  final String workspaceName;
  final LocalizedName inviter;
  final WorkspaceRole role;
  final int memberCount;

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
    code: json['Code'] as String? ?? '',
    workspaceId: jsonInt(json['WorkspaceId']) ?? 0,
    workspaceName: json['WorkspaceName'] as String? ?? '',
    inviter: LocalizedName(
      json['InviterName'] as String? ?? '',
      json['InviterNameBn'] as String? ?? '',
    ),
    role: WorkspaceRole.fromWire(json['Role'] as String?),
    memberCount: jsonInt(json['MemberCount']) ?? 1,
  );
}

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

  /// The invited membership's id.
  final String code;
  final String workspaceId;
  final String workspaceName;
  final LocalizedName inviter;
  final WorkspaceRole role;
  final int memberCount;

  /// One of `me.invites`.
  factory Invitation.fromJson(Map<String, dynamic> json) {
    final inviter =
        (json['invitedByName'] ?? json['inviterName'] ?? json['invitedBy'])
            as String? ??
        '';
    return Invitation(
      code: jsonId(json['membershipId']) ?? jsonId(json['id']) ?? '',
      workspaceId: jsonId(json['workspaceId']) ?? '',
      workspaceName:
          (json['workspaceName'] ?? json['name']) as String? ?? '',
      inviter: LocalizedName(inviter, inviter),
      role: WorkspaceRole.fromWire(json['role'] as String?),
      memberCount: jsonInt(json['memberCount']) ?? 1,
    );
  }
}

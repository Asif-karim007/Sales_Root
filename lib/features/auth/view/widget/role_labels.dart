import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/translations/translations.dart';

extension WorkspaceRoleLabel on WorkspaceRole {
  String label(AppLocalizations l10n) => switch (this) {
    WorkspaceRole.owner => l10n.authRoleOwner,
    WorkspaceRole.teamLead => l10n.authRoleTeamLead,
    WorkspaceRole.member => l10n.authRoleMember,
  };
}

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/workspace/workspace.dart';

/// Which home the Home tab shows.
enum HomeVariant { newUser, easy, standard, teamLead, manager, owner }

/// The home for a workspace with data; an empty one gets
/// [HomeVariant.newUser] instead. Owners get the money dashboard from
/// Standard up. Team leads get the team home, or the manager home (money,
/// forecast, teams side by side) at the Advanced level. Members get the Easy
/// or Standard home by level.
HomeVariant homeLayoutFor({
  required WorkspaceRole role,
  required ExperienceLevel level,
  required bool ownerDashboard,
}) => switch (role) {
  WorkspaceRole.owner when level == ExperienceLevel.easy => HomeVariant.easy,
  WorkspaceRole.owner =>
    ownerDashboard ? HomeVariant.owner : HomeVariant.standard,
  WorkspaceRole.teamLead =>
    level == ExperienceLevel.advanced
        ? HomeVariant.manager
        : HomeVariant.teamLead,
  WorkspaceRole.member =>
    level == ExperienceLevel.easy ? HomeVariant.easy : HomeVariant.standard,
};

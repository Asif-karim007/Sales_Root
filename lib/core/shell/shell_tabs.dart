import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

part 'shell_tabs.g.dart';

/// The four tabs in the bottom bar. The third one depends on who is using
/// the app: Team for leads and owners, Sales from the Standard level up,
/// Tasks otherwise.
@Riverpod(keepAlive: true)
List<ShellBranch> shellTabs(Ref ref) {
  final role = ref.watch(currentRoleProvider);
  final level = ref.watch(experienceLevelProvider);
  final team = ref.watch(moduleAccessProvider(AppModule.team));
  final sales = ref.watch(moduleAccessProvider(AppModule.quotation));
  final third = role != WorkspaceRole.member && team.visible
      ? ShellBranch.team
      : level.atLeast(ExperienceLevel.standard) && sales.visible
      ? ShellBranch.sales
      : ShellBranch.tasks;
  return [ShellBranch.home, ShellBranch.leads, third, ShellBranch.more];
}

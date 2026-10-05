import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/data/access_api.dart';
import 'package:salesroot/core/access/data/access_repository.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/access/role_grants.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

part 'access_providers.g.dart';

@Riverpod(keepAlive: true)
AccessApi accessApi(Ref ref) => AccessApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
AccessRepository accessRepository(Ref ref) =>
    ApiAccessRepository(ref.watch(accessApiProvider));

/// The role's grants in the current workspace. The server applies the same
/// matrix, so this only decides what the app offers.
@Riverpod(keepAlive: true)
class PermissionsNotifier extends _$PermissionsNotifier {
  @override
  Future<Map<AppModule, ModulePermission>> build() async {
    await ref.watch(workspacesProvider.future);
    final workspace = ref.watch(currentWorkspaceProvider);
    if (workspace == null) return const {};
    return {
      for (final module in AppModule.values)
        module: roleGrant(
          workspace.role,
          module,
          finance: workspace.isFinance,
        ),
    };
  }
}

@Riverpod(keepAlive: true)
class PlanNotifier extends _$PlanNotifier {
  @override
  Future<Plan?> build() async {
    final workspaceId = ref.watch(
      currentWorkspaceProvider.select((w) => w?.id),
    );
    if (workspaceId == null) return null;
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'plan/$workspaceId';
    try {
      final plan = await ref.read(accessRepositoryProvider).plan();
      await prefs.setString(key, jsonEncode(plan.toJson()));
      return plan;
    } on ApiFailure catch (failure) {
      final cached = prefs.getString(key);
      if (!failure.isOffline || cached == null) rethrow;
      return Plan.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }
  }
}

@Riverpod(keepAlive: true)
class ExperienceLevelNotifier extends _$ExperienceLevelNotifier {
  @override
  ExperienceLevel build() {
    final workspace = ref.watch(currentWorkspaceProvider);
    final locked = workspace?.lockedLevel;
    if (locked != null) return locked;
    final stored = ExperienceLevel.fromWire(
      ref.read(sharedPreferencesProvider).getString(_key(workspace)),
    );
    if (stored != null) return stored;
    final own = workspace?.level;
    if (own != null) return own;
    return ref.watch(currentRoleProvider) == WorkspaceRole.member
        ? ExperienceLevel.easy
        : ExperienceLevel.standard;
  }

  bool get isLocked => ref.read(experienceLevelLockedProvider);

  /// Applies at once and saves to the member's profile in the background.
  Future<void> set(ExperienceLevel level) async {
    if (isLocked) return;
    final workspace = ref.read(currentWorkspaceProvider);
    final repository = ref.read(accessRepositoryProvider);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key(workspace), level.wire);
    state = level;
    try {
      await repository.setLevel(level);
    } on ApiFailure {
      return;
    }
  }

  static String _key(Workspace? workspace) => 'level/${workspace?.id}';
}

@Riverpod(keepAlive: true)
bool experienceLevelLocked(Ref ref) =>
    ref.watch(currentWorkspaceProvider.select((w) => w?.lockedLevel)) != null;

/// What the user may do in [module]: role grants, narrowed by the plan's
/// add-ons and the experience level.
@Riverpod(keepAlive: true)
ModuleAccess moduleAccess(Ref ref, AppModule module) {
  final row = ref.watch(permissionsProvider.select((p) => p.value?[module]));
  final addOn = module.addOn;
  final included = ref.watch(
    currentWorkspaceProvider.select(
      (w) => addOn == null || (w?.addOns.contains(addOn) ?? false),
    ),
  );
  final plan = ref.watch(planProvider).value;
  final level = ref.watch(experienceLevelProvider);
  return ModuleAccess.fromPermission(row).restrict(
    planOk: addOn == null || (plan?.has(addOn) ?? included),
    levelOk: level.atLeast(module.minLevel),
  );
}

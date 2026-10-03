import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/data/access_repository.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

part 'access_providers.g.dart';

@Riverpod(keepAlive: true)
AccessRepository accessRepository(Ref ref) =>
    FakeAccessRepository(ref.watch(fakeBackendProvider));

/// The role's grants in the current workspace, cached for offline starts.
@Riverpod(keepAlive: true)
class PermissionsNotifier extends _$PermissionsNotifier {
  @override
  Future<Map<AppModule, ModulePermission>> build() async {
    final workspaceId = ref.watch(
      currentWorkspaceProvider.select((w) => w?.id),
    );
    ref.watch(currentRoleProvider);
    if (workspaceId == null) return const {};
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'permissions/$workspaceId';
    try {
      final rows = await ref.read(accessRepositoryProvider).permissions();
      await prefs.setString(
        key,
        jsonEncode([for (final r in rows) r.toJson()]),
      );
      return {for (final row in rows) row.module: row};
    } on ApiFailure catch (failure) {
      final cached = prefs.getString(key);
      if (!failure.isOffline || cached == null) rethrow;
      final rows = [
        for (final json in jsonDecode(cached) as List)
          ?ModulePermission.fromJson(json as Map<String, dynamic>),
      ];
      return {for (final row in rows) row.module: row};
    }
  }
}

@Riverpod(keepAlive: true)
class PlanNotifier extends _$PlanNotifier {
  @override
  Future<Plan?> build() async {
    final workspaceId = ref.watch(
      currentWorkspaceProvider.select((w) => w?.id),
    );
    ref.watch(fakeBackendProvider.select((b) => b.settings.addOns));
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
    return ref.watch(currentRoleProvider) == WorkspaceRole.member
        ? ExperienceLevel.easy
        : ExperienceLevel.standard;
  }

  bool get isLocked => ref.read(experienceLevelLockedProvider);

  void set(ExperienceLevel level) {
    if (isLocked) return;
    final workspace = ref.read(currentWorkspaceProvider);
    ref.read(sharedPreferencesProvider).setString(_key(workspace), level.wire);
    state = level;
  }

  static String _key(Workspace? workspace) => 'level/${workspace?.id}';
}

@Riverpod(keepAlive: true)
bool experienceLevelLocked(Ref ref) =>
    ref.watch(currentWorkspaceProvider.select((w) => w?.lockedLevel)) != null ||
    ref.watch(devSettingsProvider.select((s) => s.lockLevel));

/// What the user may do in [module]: role grants, narrowed by the plan's
/// add-ons and the experience level.
@Riverpod(keepAlive: true)
ModuleAccess moduleAccess(Ref ref, AppModule module) {
  final row = ref.watch(permissionsProvider.select((p) => p.value?[module]));
  final plan = ref.watch(planProvider).value;
  final level = ref.watch(experienceLevelProvider);
  final addOn = module.addOn;
  return ModuleAccess.fromPermission(row).restrict(
    planOk: addOn == null || (plan?.has(addOn) ?? false),
    levelOk: level.atLeast(module.minLevel),
  );
}

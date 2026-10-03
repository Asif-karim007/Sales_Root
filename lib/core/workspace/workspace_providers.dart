import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_repository.dart';

part 'workspace_providers.g.dart';

@Riverpod(keepAlive: true)
WorkspaceRepository workspaceRepository(Ref ref) => FakeWorkspaceRepository(
  ref.watch(fakeNetworkProvider),
  ref.watch(fakeStoreProvider),
);

/// The user's workspaces. Cached so a cold start offline still opens.
@Riverpod(keepAlive: true)
class WorkspacesNotifier extends _$WorkspacesNotifier {
  static const _cacheKey = 'workspaces';

  @override
  Future<List<Workspace>> build() async {
    final session = await ref.watch(sessionProvider.future);
    if (session == null) return const [];
    final prefs = ref.read(sharedPreferencesProvider);
    try {
      final list = await ref.read(workspaceRepositoryProvider).list();
      await prefs.setString(
        _cacheKey,
        jsonEncode([for (final w in list) w.toJson()]),
      );
      return list;
    } on ApiFailure catch (failure) {
      final cached = prefs.getString(_cacheKey);
      if (!failure.isOffline || cached == null) rethrow;
      return [
        for (final row in jsonDecode(cached) as List)
          Workspace.fromJson(row as Map<String, dynamic>),
      ];
    }
  }

  Future<Workspace> create(String name) async {
    final workspace = await ref.read(workspaceRepositoryProvider).create(name);
    ref.invalidateSelf();
    return workspace;
  }
}

@Riverpod(keepAlive: true)
class CurrentWorkspaceNotifier extends _$CurrentWorkspaceNotifier {
  static const _key = 'current_workspace';

  @override
  Workspace? build() {
    final list = ref.watch(workspacesProvider).value ?? const <Workspace>[];
    if (list.isEmpty) return null;
    final id = ref.read(sharedPreferencesProvider).getInt(_key);
    return list.firstWhere(
      (w) => w.id == id,
      orElse: () =>
          list.firstWhere((w) => !w.isPersonal, orElse: () => list.first),
    );
  }

  void select(Workspace workspace) {
    ref.read(sharedPreferencesProvider).setInt(_key, workspace.id);
    state = workspace;
  }
}

/// The role in the current workspace, after any dev-menu override.
@Riverpod(keepAlive: true)
WorkspaceRole currentRole(Ref ref) =>
    ref.watch(devSettingsProvider.select((s) => s.role)) ??
    ref.watch(currentWorkspaceProvider)?.role ??
    WorkspaceRole.member;

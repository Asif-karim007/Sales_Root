import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_api.dart';
import 'package:salesroot/core/workspace/workspace_repository.dart';

part 'workspace_providers.g.dart';

@Riverpod(keepAlive: true)
WorkspaceApi workspaceApi(Ref ref) => WorkspaceApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
WorkspaceRepository workspaceRepository(Ref ref) =>
    ApiWorkspaceRepository(ref.watch(workspaceApiProvider));

/// The user's workspaces. Cached so a cold start offline still opens.
@Riverpod(keepAlive: true)
class WorkspacesNotifier extends _$WorkspacesNotifier {
  static const _cacheKey = 'workspaces';

  @override
  Future<List<Workspace>> build() async {
    final userId = await ref.watch(
      sessionProvider.selectAsync((s) => s?.userId),
    );
    if (userId == null) return const [];
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

  /// Creates a team, signs into it and returns it.
  Future<Workspace> create(String name, {String? industryPack}) async {
    final id = await ref
        .read(workspaceRepositoryProvider)
        .create(name, industryPack: industryPack);
    await ref.read(sessionProvider.notifier).switchWorkspace(id);
    ref.invalidateSelf();
    final list = await future;
    return list.firstWhere((w) => w.id == id, orElse: () => list.first);
  }
}

/// The workspace the session token is scoped to.
@Riverpod(keepAlive: true)
class CurrentWorkspaceNotifier extends _$CurrentWorkspaceNotifier {
  @override
  Workspace? build() {
    final list = ref.watch(workspacesProvider).value ?? const <Workspace>[];
    if (list.isEmpty) return null;
    final id = ref.watch(sessionProvider.select((s) => s.value?.workspaceId));
    return list.firstWhere(
      (w) => w.id == id,
      orElse: () =>
          list.firstWhere((w) => !w.isPersonal, orElse: () => list.first),
    );
  }

  /// Re-scopes the session to [workspace]; dependants rebuild for it.
  Future<void> select(Workspace workspace) =>
      ref.read(sessionProvider.notifier).switchWorkspace(workspace.id);
}

@Riverpod(keepAlive: true)
WorkspaceRole currentRole(Ref ref) =>
    ref.watch(currentWorkspaceProvider)?.role ?? WorkspaceRole.member;

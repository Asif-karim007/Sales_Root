import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

/// A signed-in container on the fake backend with latency off, in the
/// Dhaka Sales workspace, with [role] forced from the dev menu.
Future<ProviderContainer> homeContainer({
  WorkspaceRole? role,
  bool empty = false,
  List<Override> overrides = const [],
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'session': jsonEncode({'Token': 't', 'UserId': 1, 'Name': 'Karim Hossain'}),
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  container
      .read(devSettingsProvider.notifier)
      .update(
        (s) =>
            s.copyWith(latency: false, emptyWorkspace: empty, role: () => role),
      );
  container.listen(currentWorkspaceProvider, (_, _) {});
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  return container;
}

void goOffline(ProviderContainer container) => container
    .read(devSettingsProvider.notifier)
    .update((s) => s.copyWith(offline: true));

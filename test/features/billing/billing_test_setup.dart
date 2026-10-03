import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

/// A signed-in container on [workspaceId] (200 is the Team workspace) with
/// latency off and the role forced to [role].
Future<ProviderContainer> billingContainer({
  int workspaceId = 200,
  WorkspaceRole role = WorkspaceRole.owner,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'session': jsonEncode({'Token': 't', 'UserId': 1, 'Name': 'Karim Hossain'}),
  });
  SharedPreferences.setMockInitialValues({'current_workspace': workspaceId});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false, role: () => role));
  await container.read(workspacesProvider.future);
  expect(container.read(currentWorkspaceProvider)?.id, workspaceId);
  return container;
}

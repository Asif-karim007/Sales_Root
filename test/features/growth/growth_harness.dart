import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

/// A signed-in container on the fake backend with latency off, in
/// [workspace] (300 has the Growth add-on) as [role].
Future<ProviderContainer> growthContainer({
  WorkspaceRole role = WorkspaceRole.owner,
  int workspace = 300,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'session': jsonEncode({'Token': 't', 'UserId': 1, 'Name': 'Karim Hossain'}),
  });
  SharedPreferences.setMockInitialValues({'current_workspace': workspace});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false, role: () => role));
  await container.read(workspacesProvider.future);
  return container;
}

FakeBackend backendOf(ProviderContainer container) =>
    container.read(fakeBackendProvider);

void goOffline(ProviderContainer container) => container
    .read(devSettingsProvider.notifier)
    .update((s) => s.copyWith(offline: true));

void reachQuota(ProviderContainer container) => container
    .read(devSettingsProvider.notifier)
    .update((s) => s.copyWith(quotaReached: true));

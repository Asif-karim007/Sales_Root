import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

/// A signed-in container over the fake backend with latency off, in the
/// Dhaka Sales team workspace, acting as [role].
Future<ProviderContainer> hrContainer({
  WorkspaceRole role = WorkspaceRole.member,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({
    'session': jsonEncode({'Token': 't', 'UserId': 1, 'Name': 'Karim Hossain'}),
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  setRole(container, role);
  await container.read(workspacesProvider.future);
  return container;
}

void setRole(ProviderContainer container, WorkspaceRole role) => container
    .read(devSettingsProvider.notifier)
    .update((s) => s.copyWith(latency: false, role: () => role));

void setOffline(ProviderContainer container, bool offline) => container
    .read(devSettingsProvider.notifier)
    .update((s) => s.copyWith(offline: offline));

/// Keeps an auto-dispose provider alive for the test and returns its value.
T keep<T>(ProviderContainer container, ProviderListenable<T> provider) =>
    container.listen(provider, (_, _) {}).read();

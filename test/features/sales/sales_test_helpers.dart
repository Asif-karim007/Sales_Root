import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

/// A signed-in container on the "Dhaka Sales" team workspace, with the fake
/// server's latency off and [role] forced.
Future<ProviderContainer> salesContainer({
  WorkspaceRole role = WorkspaceRole.owner,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'session': jsonEncode({'Token': 't', 'UserId': 1, 'Name': 'Karim Hossain'}),
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false, role: () => role));
  await container.read(workspacesProvider.future);
  container.listen(fakeBackendProvider, (_, _) {});
  return container;
}

/// Switches the fake server's dev-menu failures on or off.
void setDev(ProviderContainer container, DevSettings Function(DevSettings) f) =>
    container.read(devSettingsProvider.notifier).update(f);

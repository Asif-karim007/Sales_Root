import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

/// A signed-in container on the "Dhaka Sales" team workspace (21 members),
/// fake latency off and no retries, acting as [role].
Future<ProviderContainer> teamContainer({
  WorkspaceRole role = WorkspaceRole.owner,
  List<Override> overrides = const [],
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'session': jsonEncode({'Token': 't', 'UserId': 1, 'Name': 'Karim Hossain'}),
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ],
  );
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false, role: () => role));
  await container.read(workspacesProvider.future);
  return container;
}

/// Turns a dev-menu switch on, as the developer menu does.
void setDev(
  ProviderContainer container,
  DevSettings Function(DevSettings settings) change,
) => container.read(devSettingsProvider.notifier).update(change);

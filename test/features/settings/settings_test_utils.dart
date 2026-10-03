import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

/// A signed-in container on the fake backend with latency off. The default
/// workspace is Dhaka Sales (Team plan with Field Force), where the user is
/// a member.
Future<ProviderContainer> signedInContainer({
  WorkspaceRole? role,
  Set<AddOn>? addOns,
  bool lockLevel = false,
  Map<String, Object> prefs = const {},
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'session': jsonEncode({
      'Token': 't',
      'UserId': 1,
      'Name': 'Karim Hossain',
      'Phone': '+8801711234567',
    }),
  });
  SharedPreferences.setMockInitialValues(prefs);
  PackageInfo.setMockInitialValues(
    appName: 'SalesRoot',
    packageName: 'com.salesrootcrm.salesroot',
    version: '2.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final shared = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(shared)],
    retry: (_, _) => null,
  );
  container
      .read(devSettingsProvider.notifier)
      .update(
        (s) => s.copyWith(
          latency: false,
          lockLevel: lockLevel,
          role: () => role,
          addOns: () => addOns,
        ),
      );
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  await container.read(planProvider.future);
  return container;
}

/// Keeps an auto-dispose provider alive for the test.
void keepAlive(ProviderContainer container, ProviderListenable<Object?> p) =>
    container.listen(p, (_, _) {});

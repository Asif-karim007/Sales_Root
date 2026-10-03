import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';

/// A container over the fake backend with latency and retries off.
Future<ProviderContainer> supportContainer({SharedPreferences? prefs}) async {
  FlutterSecureStorage.setMockInitialValues({});
  if (prefs == null) SharedPreferences.setMockInitialValues({});
  final preferences = prefs ?? await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false));
  return container;
}

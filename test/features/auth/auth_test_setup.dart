import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';

/// Karim Hossain's stored session, as after an earlier sign-in.
final storedSession = {
  'session': jsonEncode({
    'Token': 'fake.1.test',
    'UserId': 1,
    'Name': 'Karim Hossain',
    'Phone': '+8801710000000',
  }),
};

/// A container over the fake backend with latency off and, as in the app
/// for a 4xx, no automatic retry.
Future<ProviderContainer> authContainer({
  Map<String, String> secure = const {},
}) async {
  FlutterSecureStorage.setMockInitialValues({...secure});
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false));
  return container;
}

/// Lets fire-and-forget work, like the PIN check after the fourth digit, end.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      retry: _retry,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}

/// Retries only failures that can clear by themselves: no connection and
/// gateway errors. A 4xx or a plain 500 is shown at once.
Duration? _retry(int retryCount, Object error) {
  if (retryCount >= 3) return null;
  final transient =
      error is ApiFailure &&
      (error.isOffline || const {502, 503, 504}.contains(error.statusCode));
  return transient ? Duration(milliseconds: 400 << retryCount) : null;
}

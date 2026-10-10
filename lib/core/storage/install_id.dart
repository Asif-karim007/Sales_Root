import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

const _key = 'sync/device_id';

/// The id the server knows this install by, made on first use.
String installId(SharedPreferences prefs) {
  final saved = prefs.getString(_key);
  if (saved != null) return saved;
  final random = Random.secure();
  final id = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  prefs.setString(_key, id);
  return id;
}

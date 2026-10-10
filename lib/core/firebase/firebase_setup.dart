import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:salesroot/core/utils/debug_log.dart';

/// Starts Firebase when the platform's config file is bundled with the app.
Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    logDebug('Firebase not started: $e');
    return;
  }
  if (kDebugMode) _logPushToken();
}

void _logPushToken() {
  final messaging = FirebaseMessaging.instance;
  messaging
      .getToken()
      .then((token) => logDebug('FCM token: $token'))
      .catchError((Object e) => logDebug('FCM token unavailable: $e'));
  messaging.onTokenRefresh.listen((token) => logDebug('FCM token: $token'));
}

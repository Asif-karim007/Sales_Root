import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_messages.g.dart';

/// Firebase Messaging on this phone: the permission to notify, the push token,
/// and showing a push that arrives while the app is open.
class PushMessages {
  static const channelId = 'salesroot_push';

  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foreground;

  bool get available => Firebase.apps.isNotEmpty;

  String get platform => Platform.isIOS ? 'ios' : 'android';

  Future<void> requestPermission() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  Future<String?> token() => FirebaseMessaging.instance.getToken();

  Stream<String> get tokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  /// Shows pushes while the app is open; on Android in a channel named
  /// [channelName], which background pushes use too.
  Future<void> showWhileOpen(String channelName) async {
    if (!Platform.isAndroid) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      return;
    }
    final channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    if (_foreground != null) return;
    _foreground = FirebaseMessaging.onMessage.listen(
      (message) => _show(message, channel),
    );
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  void _show(RemoteMessage message, AndroidNotificationChannel channel) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      id: message.messageId.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

@Riverpod(keepAlive: true)
PushMessages pushMessages(Ref ref) => PushMessages();

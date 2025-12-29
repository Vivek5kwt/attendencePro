import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

StreamSubscription<String>? _tokenRefreshSubscription;

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
  playSound: true,
);

Future<void> initLocalNotifications() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
  DarwinInitializationSettings();

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);

  // Android channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);

  // (Optional) Request local notification permission on iOS
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );

}


void _logToken(String? token) {
  final cleaned = token?.trim();
  if (cleaned == null || cleaned.isEmpty) {
    debugPrint('[FCM] Token unavailable');
    return;
  }
  debugPrint('[FCM] Token: $cleaned');
}

Future<void> _syncTokenWithBackend(String? token) async {
  final cleaned = token?.trim();
  if (cleaned == null || cleaned.isEmpty) return;

  debugPrint('[FCM] Backend sync skipped (handled post-login)');
}

Future<void> _handleToken(String? token) async {
  _logToken(token);
  await _syncTokenWithBackend(token);
}

Future<String?> fetchFcmToken() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  if (Platform.isIOS) {
    String? apns;
    int retry = 0;

    while (apns == null && retry < 20) {
      apns = await messaging.getAPNSToken();
      await Future.delayed(const Duration(milliseconds: 500));
      retry++;
    }
  }

  final token = await messaging.getToken();
  debugPrint('[FCM] LOGIN TOKEN => $token');
  return token?.trim();
}

/// ---- MAIN FCM SETUP ----
Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  if (Platform.isIOS) {
    String? apnsToken;
    int retry = 0;

    while (apnsToken == null && retry < 10) {
      apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null) {
        await Future.delayed(const Duration(seconds: 1));
      }
      retry++;
    }

    if (apnsToken == null) {
      debugPrint('[FCM] ❌ APNs token not ready. Skipping FCM init.');
      return;
    }

    debugPrint('[FCM] ✅ APNs token ready');
  }
  await initLocalNotifications();

  final token = await messaging.getToken();
  await _handleToken(token);
  _tokenRefreshSubscription ??=
      messaging.onTokenRefresh.listen((token) async {
        await _handleToken(token);
      });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('📩 Foreground push received');
    debugPrint('TITLE: ${message.notification?.title}');
    debugPrint('BODY : ${message.notification?.body}');

    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) {
      return;
    }

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📲 Notification tapped — app opened');
  });

  final initialMsg = await messaging.getInitialMessage();
  if (initialMsg != null) {
    debugPrint('🚀 App launched via notification');
  }
}

Future<void> disposeFCM() async {
  await _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}

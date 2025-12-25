import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

StreamSubscription<String>? _tokenRefreshSubscription;

/// Log FCM token safely
void _logToken(String? token) {
  final cleanedToken = token?.trim();
  if (cleanedToken == null || cleanedToken.isEmpty) {
    debugPrint('[FCM] Token unavailable');
    return;
  }
  debugPrint('[FCM] Token: $cleanedToken');
}

/// Sync token with backend (intentionally deferred)
Future<void> _syncTokenWithBackend(String? token) async {
  final cleanedToken = token?.trim();
  if (cleanedToken == null || cleanedToken.isEmpty) {
    return;
  }

  // ⚠️ Intentionally skipped — token send login/signup ke baad hota hai
  debugPrint('[FCM] Backend sync skipped (handled post-login)');
}

/// Handle token lifecycle
Future<void> _handleToken(String? token) async {
  _logToken(token);
  await _syncTokenWithBackend(token);
}

/// ⚠️ iOS me APNs token ready hone tak wait karo
Future<String?> fetchFcmToken() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

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

/// ✅ SAFE FCM SETUP (iOS + Android)
Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  // 1️⃣ Request notification permission
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 2️⃣ iOS → allow foreground popup
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 3️⃣ iOS: wait for APNs token
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

  // 4️⃣ Get FCM token
  final token = await messaging.getToken();
  await _handleToken(token);

  // 5️⃣ Listen for token refresh
  _tokenRefreshSubscription ??=
      messaging.onTokenRefresh.listen((token) {
        unawaited(_handleToken(token));
      });

  // 6️⃣ FOREGROUND notification listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📩 Foreground push received');
    debugPrint('TITLE: ${message.notification?.title}');
    debugPrint('BODY : ${message.notification?.body}');
  });

  // 7️⃣ When user taps notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📲 Notification tapped — app opened');
  });

  // 8️⃣ Check if app opened from terminated
  final initialMsg = await messaging.getInitialMessage();
  if (initialMsg != null) {
    debugPrint('🚀 App launched via notification');
  }
}

/// Dispose safely
Future<void> disposeFCM() async {
  await _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}

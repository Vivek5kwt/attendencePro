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

  // ⚠️ Intentionally skipped
  // Token should be sent after login/signup
  debugPrint('[FCM] Backend sync skipped (handled post-login)');
}

/// Handle token lifecycle
Future<void> _handleToken(String? token) async {
  _logToken(token);
  await _syncTokenWithBackend(token);
}

/// ⚠️ DO NOT USE directly on iOS before APNs token
/// Kept for Android / future-safe usage
Future<String?> fetchFcmToken() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 🔥 iOS: wait until APNs token is ready
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

  // 2️⃣ iOS: wait for APNs token BEFORE FCM
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
      return; // ⛔ Prevent crash
    }

    debugPrint('[FCM] ✅ APNs token ready');
  }

  // 3️⃣ SAFE: get FCM token
  final token = await messaging.getToken();
  await _handleToken(token);

  // 4️⃣ Listen for token refresh
  _tokenRefreshSubscription ??=
      messaging.onTokenRefresh.listen((token) {
        unawaited(_handleToken(token));
      });
}

/// Dispose safely
Future<void> disposeFCM() async {
  await _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}

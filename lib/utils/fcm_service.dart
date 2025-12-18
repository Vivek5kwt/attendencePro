import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

StreamSubscription<String>? _tokenRefreshSubscription;

void _logToken(String? token) {
  final cleanedToken = token?.trim();
  if (cleanedToken == null || cleanedToken.isEmpty) {
    print('FCM TOKEN: unavailable');
    return;
  }

  print('FCM TOKEN: $cleanedToken');
}

Future<void> _syncTokenWithBackend(String? token) async {
  final cleanedToken = token?.trim();
  if (cleanedToken == null || cleanedToken.isEmpty) {
    return;
  }

  debugPrint('[FCM] Backend sync skipped. Token should be provided during login/signup.');
}

Future<void> _handleToken(String? token) async {
  _logToken(token);
  await _syncTokenWithBackend(token);
}

Future<String?> fetchFcmToken() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final token = await messaging.getToken();
  _logToken(token);
  return token?.trim();
}

Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final token = await messaging.getToken();
  await _handleToken(token);

  _tokenRefreshSubscription ??=
      messaging.onTokenRefresh.listen((token) => unawaited(_handleToken(token)));
}

Future<void> disposeFCM() async {
  await _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}

import 'dart:async';

import 'package:attendancepro/apis/user_api.dart';
import 'package:attendancepro/utils/session_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

StreamSubscription<String>? _tokenRefreshSubscription;
final _sessionManager = const SessionManager();
final _userApi = UserApi();

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

  final authToken = await _sessionManager.getToken();
  final userId = await _sessionManager.getUserId();
  if (authToken == null || userId == null) {
    debugPrint('[FCM] Session not available. Skipping token sync.');
    return;
  }

  try {
    await _userApi.updateFcmToken(
      token: authToken,
      userId: userId,
      fcmToken: cleanedToken,
    );
    debugPrint('[FCM] Token synced for user $userId.');
  } catch (error) {
    debugPrint('[FCM] Failed to sync token: $error');
  }
}

Future<void> _handleToken(String? token) async {
  _logToken(token);
  await _syncTokenWithBackend(token);
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

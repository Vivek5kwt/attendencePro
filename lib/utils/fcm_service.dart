import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

StreamSubscription<String>? _tokenRefreshSubscription;

void _logToken(String? token) {
  final cleanedToken = token?.trim();
  if (cleanedToken == null || cleanedToken.isEmpty) {
    print('FCM TOKEN: unavailable');
    return;
  }

  print('FCM TOKEN: $cleanedToken');
}

Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final token = await messaging.getToken();
  _logToken(token);

  _tokenRefreshSubscription ??=
      messaging.onTokenRefresh.listen((token) => _logToken(token));
}

Future<void> disposeFCM() async {
  await _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}

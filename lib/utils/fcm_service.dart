import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

StreamSubscription<String>? _tokenRefreshSubscription;

Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final token = await messaging.getToken();
  if (token != null) {
    print("FCM TOKEN: $token");
  }

  _tokenRefreshSubscription ??=
      messaging.onTokenRefresh.listen((token) => print("FCM TOKEN: $token"));
}

Future<void> disposeFCM() async {
  await _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}

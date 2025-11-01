import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const AndroidNotificationChannel _downloadChannel =
      AndroidNotificationChannel(
    'downloads_channel',
    'Downloads',
    description: 'Notifications about saved reports',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          LocalNotificationService._handleBackgroundNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (response != null) {
      await _handleNotificationResponse(response);
    }

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_downloadChannel);
    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );

    final macImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    await macImplementation?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );

    _initialized = true;
  }

  static Future<void> showDownloadNotification({
    required String fileName,
    required String filePath,
  }) async {
    if (kIsWeb) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _downloadChannel.id,
        _downloadChannel.name,
        channelDescription: _downloadChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          'Saved to $filePath',
          contentTitle: 'Download complete',
          summaryText: fileName,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(
      id,
      'Download complete',
      '$fileName saved to $filePath',
      notificationDetails,
      payload: filePath,
    );
  }

  static Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    if (kIsWeb) {
      return;
    }

    final payload = response.payload?.trim();
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      await OpenFilex.open(payload);
    } catch (_) {
      // Ignore failures to open the file; the download is still saved locally.
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundNotificationResponse(
    NotificationResponse response,
  ) {
    return _handleNotificationResponse(response);
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:attendancepro/core/constants/app_strings.dart';
import 'package:attendancepro/utils/native_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:attendancepro/utils/session_manager.dart';

enum _NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  notDetermined,
}

enum NotificationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _timeZoneInitialized = false;
  static bool? _notificationsPermissionGranted;
  static const String _permissionRequestedKey =
      'notifications_permission_requested';
  static const String _permissionPromptAnsweredKey =
      'notifications_permission_prompt_answered';
  static const String _lastDownloadedReportPathKey =
      'last_downloaded_report_path';
  static const String _pendingDownloadedReportPathKey =
      'pending_downloaded_report_path';

  static const AndroidNotificationChannel _downloadChannel =
  AndroidNotificationChannel(
    'downloads_channel',
    'Downloads',
    description: 'Notifications about saved reports',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _generalChannel =
  AndroidNotificationChannel(
    'general_channel',
    'General',
    description: 'General purpose notifications',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _attendanceReminderChannel =
  AndroidNotificationChannel(
    'attendance_reminder_channel',
    'Attendance Reminders',
    description: 'Daily reminders to mark attendance',
    importance: Importance.high,
  );

  static const int _attendanceReminderNotificationId = 2001;
  static const String _lastAttendanceMarkedKey = 'last_attendance_marked_epoch';
  static const String _attendanceReminderTimeKey = 'attendance_reminder_time';
  static const _ReminderTime _attendanceReminderDefaultTime =
  _ReminderTime(hour: 20, minute: 0);
  static const int _attendanceReminderWindowStartHour = 20;
  static const int _attendanceReminderWindowEndHour = 22;
  static const String _attendanceReminderTitle = 'Attendance Reminder';
  static const String _attendanceReminderBody =
      'Please mark your attendance for today! Tap to open the app.';
  static const String _dashboardDeepLinkTitle = 'AttendancePro';
  static const String _dashboardDeepLinkBody =
      'Tap to jump straight to your dashboard.';
  static const String _payloadTypeKey = 'type';
  static const String _payloadFilePathKey = 'filePath';
  static const String _payloadTypeDownload = 'open_file';
  static const String _payloadTypeAttendanceReminder = 'attendance_reminder';
  static const String _payloadTypeDashboardDeepLink = 'dashboard';
  static const SessionManager _sessionManager = SessionManager();

  static Future<void> Function()? _attendanceReminderTapHandler;
  static int _pendingAttendanceReminderTapCount = 0;
  static Future<void> Function()? _dashboardDeepLinkHandler;
  static int _pendingDashboardTapCount = 0;

  static Future<void> initialize({bool requestPermissionsOnInit = false}) async {
    if (_initialized) {
      return;
    }

    if (kIsWeb) {
      _initialized = true;
      _notificationsPermissionGranted = false;
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
    await _openPendingDownloadedReportIfNeeded();

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_downloadChannel);
    await androidImplementation
        ?.createNotificationChannel(_attendanceReminderChannel);
    await androidImplementation?.createNotificationChannel(_generalChannel);

    if (requestPermissionsOnInit) {
      _notificationsPermissionGranted = await _ensurePermissionsRequested(
        markPromptAnswered: false,
      );
    } else {
      final status = await _currentPermissionStatus();
      _notificationsPermissionGranted =
          status == _NotificationPermissionStatus.granted;
    }

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    var permissionGranted = _isPermissionStatusGranted(status);

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macosPlugin = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    bool? platformGranted;
    if (iosPlugin != null) {
      platformGranted = await iosPlugin.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
    } else if (macosPlugin != null) {
      platformGranted = await macosPlugin.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
    }

    if (platformGranted != null) {
      permissionGranted = permissionGranted || platformGranted;
    }

    _notificationsPermissionGranted = permissionGranted;
  }

  static Future<_NotificationPermissionStatus> _currentPermissionStatus() async {
    final status = await Permission.notification.status;

    if (_isPermissionStatusGranted(status)) {
      _notificationsPermissionGranted = true;
      return _NotificationPermissionStatus.granted;
    }

    final androidEnabled = await _areAndroidNotificationsEnabled();
    if (androidEnabled) {
      _notificationsPermissionGranted = true;
      return _NotificationPermissionStatus.granted;
    }

    if (status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      _notificationsPermissionGranted = false;
      return _NotificationPermissionStatus.permanentlyDenied;
    }

    if (status == PermissionStatus.denied) {
      _notificationsPermissionGranted = false;
      return _NotificationPermissionStatus.denied;
    }

    return _NotificationPermissionStatus.notDetermined;
  }

  static bool _isPermissionStatusGranted(PermissionStatus status) {
    return status.isGranted ||
        status == PermissionStatus.limited ||
        status == PermissionStatus.provisional;
  }

  static Future<bool> _areAndroidNotificationsEnabled() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation == null) {
      return false;
    }
    final enabled = await androidImplementation.areNotificationsEnabled();
    return enabled ?? false;
  }

  static Future<bool> _ensurePermissionsRequested({
    bool markPromptAnswered = true,
  }) async {
    if (kIsWeb) {
      _notificationsPermissionGranted = false;
      return false;
    }

    final status = await _currentPermissionStatus();
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool(_permissionRequestedKey) ?? false;

    if (status == _NotificationPermissionStatus.granted) {
      if (!alreadyRequested) {
        await prefs.setBool(_permissionRequestedKey, true);
      }
      if (markPromptAnswered) {
        await _markPermissionPromptAnswered(prefs: prefs);
      }
      _notificationsPermissionGranted = true;
      return true;
    }

    final shouldRequest =
        status == _NotificationPermissionStatus.notDetermined ||
            status == _NotificationPermissionStatus.denied;

    if (shouldRequest) {
      await _requestPermissions();
      await prefs.setBool(_permissionRequestedKey, true);
      if (markPromptAnswered) {
        await _markPermissionPromptAnswered(prefs: prefs);
      }

      final updatedStatus = await _currentPermissionStatus();
      final granted =
          updatedStatus == _NotificationPermissionStatus.granted;
      _notificationsPermissionGranted = granted;
      return granted;
    }

    if (!alreadyRequested) {
      await prefs.setBool(_permissionRequestedKey, true);
    }
    if (markPromptAnswered) {
      await _markPermissionPromptAnswered(prefs: prefs);
    }
    _notificationsPermissionGranted = false;
    return false;
  }

  static Future<void> markPermissionPromptAnswered() async {
    await _markPermissionPromptAnswered();
  }

  static Future<bool> shouldShowPermissionPrompt() async {
    if (kIsWeb) {
      return false;
    }

    if (!_initialized) {
      await initialize();
    }

    final prefs = await SharedPreferences.getInstance();
    final promptAnswered =
        prefs.getBool(_permissionPromptAnsweredKey) ?? false;

    final status = await _currentPermissionStatus();
    if (status == _NotificationPermissionStatus.granted) {
      await _markPermissionPromptAnswered(prefs: prefs);
      _notificationsPermissionGranted = true;
      return false;
    }

    return !promptAnswered;
  }

  static Future<void> _markPermissionPromptAnswered({
    SharedPreferences? prefs,
  }) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await resolvedPrefs.setBool(_permissionPromptAnsweredKey, true);
  }

  static Future<bool> ensurePermissionsRequested({
    bool markPromptAnswered = true,
  }) async {
    if (kIsWeb) {
      _notificationsPermissionGranted = false;
      return false;
    }

    if (!_initialized) {
      await initialize();
    }

    return _ensurePermissionsRequested(markPromptAnswered: markPromptAnswered);
  }

  static Future<bool> requestPermissions({bool markPromptAnswered = true}) async {
    return ensurePermissionsRequested(markPromptAnswered: markPromptAnswered);
  }

  static Future<bool> hasNotificationPermissions() async {
    if (kIsWeb) {
      return false;
    }

    if (!_initialized) {
      await initialize();
      return _notificationsPermissionGranted ?? false;
    }

    final status = await _currentPermissionStatus();
    final granted = status == _NotificationPermissionStatus.granted;
    _notificationsPermissionGranted = granted;
    return granted;
  }

  static Future<void> showTestNotification({
    String title = 'Notifications ready',
    String body = 'AttendancePro can now send you alerts.',
  }) async {
    if (kIsWeb) {
      return;
    }

    final permissionGranted = await ensurePermissionsRequested();
    if (!permissionGranted) {
      debugPrint(
        '[LocalNotificationService] Notification permission not granted. '
            'Skipping test notification.',
      );
      return;
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _generalChannel.id,
        _generalChannel.name,
        channelDescription: _generalChannel.description,
        importance: Importance.high,
        priority: Priority.high,
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
    final copy = await _resolveDashboardNotificationCopy(
      overrideTitle: title,
      overrideBody: body,
    );
    await _plugin.show(
      id,
      copy.title,
      copy.body,
      notificationDetails,
      payload: _encodePayload(<String, String>{
        _payloadTypeKey: _payloadTypeDashboardDeepLink,
      }),
    );
  }

  static Future<NotificationPermissionResult> showDownloadNotification({
    required String fileName,
    required String filePath,
  }) async {
    if (kIsWeb) {
      return NotificationPermissionResult.denied;
    }

    final permissionGranted = await ensurePermissionsRequested();
    if (!permissionGranted) {
      final status = await _currentPermissionStatus();
      final result = status == _NotificationPermissionStatus.permanentlyDenied
          ? NotificationPermissionResult.permanentlyDenied
          : NotificationPermissionResult.denied;
      debugPrint(
        '[LocalNotificationService] Notification permission not granted. '
            'Skipping download notification for $fileName.',
      );
      return result;
    }

    await _storeLastDownloadedReportPath(filePath);

    final friendlyTitle = 'Download ready';
    final friendlyBody = '$fileName downloaded successfully.';

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _downloadChannel.id,
        _downloadChannel.name,
        channelDescription: _downloadChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          friendlyBody,
          contentTitle: friendlyTitle,
          summaryText: fileName,
        ),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        subtitle: fileName,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        subtitle: fileName,
      ),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(
      id,
      friendlyTitle,
      friendlyBody,
      notificationDetails,
      payload: _encodePayload(<String, String>{
        _payloadTypeKey: _payloadTypeDownload,
        _payloadFilePathKey: filePath,
      }),
    );
    return NotificationPermissionResult.granted;
  }

  static Future<void> openNotificationSettings() async {
    if (kIsWeb) {
      return;
    }
    await openAppSettings();
  }

  static Future<void> _handleNotificationResponse(
      NotificationResponse response,
      ) async {
    if (kIsWeb) {
      return;
    }

    debugPrint(
      '[LocalNotificationService] Notification tapped. '
      'actionId=${response.actionId} payload=${response.payload}',
    );
    final payload = response.payload?.trim();
    if (payload == null || payload.isEmpty) {
      debugPrint(
        '[LocalNotificationService] Empty payload. '
        'Attempting to open last downloaded report or dashboard.',
      );
      final fallbackPath = await _loadLastDownloadedReportPath();
      if (fallbackPath != null && fallbackPath.trim().isNotEmpty) {
        debugPrint(
          '[LocalNotificationService] Opening fallback report: $fallbackPath',
        );
        await _openDownloadedReport(fallbackPath);
        await _clearPendingDownloadedReportPath();
      } else {
        debugPrint(
          '[LocalNotificationService] No report found. Opening dashboard.',
        );
        await _handleDashboardDeepLink();
      }
      return;
    }

    final parsedPayload = _decodePayload(payload);

    if (parsedPayload == null) {
      debugPrint(
        '[LocalNotificationService] Payload is not JSON. '
        'Attempting to open as file path: $payload',
      );
      await _openDownloadedReport(payload);
      await _clearPendingDownloadedReportPath();
      await _handleDashboardDeepLink();
      return;
    }

    final type = parsedPayload[_payloadTypeKey];
    if (type == _payloadTypeDownload) {
      final filePath = parsedPayload[_payloadFilePathKey];
      if (filePath is String && filePath.trim().isNotEmpty) {
        debugPrint(
          '[LocalNotificationService] Opening downloaded report: $filePath',
        );
        await _openDownloadedReport(filePath);
        await _clearPendingDownloadedReportPath();
        return;
      }

      final fallbackPath = await _loadLastDownloadedReportPath();
      if (fallbackPath != null && fallbackPath.trim().isNotEmpty) {
        debugPrint(
          '[LocalNotificationService] Payload missing file path. '
          'Opening fallback report: $fallbackPath',
        );
        await _openDownloadedReport(fallbackPath);
        await _clearPendingDownloadedReportPath();
      }
      return;
    }

    if (type == _payloadTypeAttendanceReminder) {
      debugPrint(
        '[LocalNotificationService] Attendance reminder tapped. '
        'Opening attendance flow and dashboard.',
      );
      await _handleAttendanceReminderDeepLink();
      await _handleDashboardDeepLink();
      return;
    }

    if (type == _payloadTypeDashboardDeepLink) {
      debugPrint(
        '[LocalNotificationService] Dashboard notification tapped. '
        'Opening dashboard.',
      );
      await _handleDashboardDeepLink();
      return;
    }

    debugPrint(
      '[LocalNotificationService] Unknown notification payload type: $type',
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundNotificationResponse(
      NotificationResponse response,
      ) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) {
      return;
    }

    debugPrint(
      '[LocalNotificationService] Notification tapped in background. '
      'actionId=${response.actionId} payload=${response.payload}',
    );
    final payload = response.payload?.trim();
    if (payload == null || payload.isEmpty) {
      final fallbackPath = await _loadLastDownloadedReportPath();
      if (fallbackPath != null && fallbackPath.trim().isNotEmpty) {
        debugPrint(
          '[LocalNotificationService] Storing fallback report path: '
          '$fallbackPath',
        );
        await _storePendingDownloadedReportPath(fallbackPath);
      }
      return;
    }

    final parsedPayload = _decodePayload(payload);
    if (parsedPayload == null) {
      debugPrint(
        '[LocalNotificationService] Storing raw payload as file path: $payload',
      );
      await _storePendingDownloadedReportPath(payload);
      return;
    }

    final type = parsedPayload[_payloadTypeKey];
    if (type == _payloadTypeDownload) {
      final filePath = parsedPayload[_payloadFilePathKey];
      if (filePath is String && filePath.trim().isNotEmpty) {
        debugPrint(
          '[LocalNotificationService] Storing report path from payload: '
          '$filePath',
        );
        await _storePendingDownloadedReportPath(filePath);
        return;
      }

      final fallbackPath = await _loadLastDownloadedReportPath();
      if (fallbackPath != null && fallbackPath.trim().isNotEmpty) {
        debugPrint(
          '[LocalNotificationService] Payload missing file path. '
          'Storing fallback report path: $fallbackPath',
        );
        await _storePendingDownloadedReportPath(fallbackPath);
      }
    }
  }

  /// Backend now manages daily reminders – local scheduling disabled
  static Future<void> scheduleDailyAttendanceReminder() async {
    if (kIsWeb) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    await _plugin.cancel(_attendanceReminderNotificationId);
    debugPrint(
      '[LocalNotificationService] Attendance reminders are now managed by the '
          'backend. Local scheduling has been disabled.',
    );
  }

  static Future<void> onAttendanceMarked({DateTime? timestamp}) async {
    if (kIsWeb) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    await _plugin.cancel(_attendanceReminderNotificationId);
  }

  static Future<void> updateAttendanceReminderTime(TimeOfDay time) async {
    if (kIsWeb) {
      return;
    }
    // Intentionally left empty as backend handles scheduling now
  }

  static Future<TimeOfDay> currentAttendanceReminderTime() async {
    if (kIsWeb) {
      return TimeOfDay(
        hour: _attendanceReminderDefaultTime.hour,
        minute: _attendanceReminderDefaultTime.minute,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final reminderTime = _resolveReminderTime(prefs);
    return TimeOfDay(hour: reminderTime.hour, minute: reminderTime.minute);
  }

  static Future<DateTime?> lastAttendanceMarkedDate() async {
    if (kIsWeb) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final epoch = prefs.getInt(_lastAttendanceMarkedKey);
    if (epoch == null) {
      return null;
    }

    final stored = DateTime.fromMillisecondsSinceEpoch(epoch);
    return DateTime(stored.year, stored.month, stored.day);
  }

  static Future<void> _ensureTimeZoneSetup() async {
    if (_timeZoneInitialized) {
      return;
    }

    tz.initializeTimeZones();

    try {
      final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (error, stackTrace) {
      debugPrint('Failed to obtain local timezone: $error');
      debugPrint('$stackTrace');
      tz.setLocalLocation(tz.UTC);
    }

    _timeZoneInitialized = true;
  }

  static Future<AndroidScheduleMode> _preferredAndroidScheduleMode() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    Future<bool> canScheduleExact() async {
      final result = await androidImplementation.canScheduleExactNotifications();
      return result ?? true;
    }

    if (await canScheduleExact()) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    await androidImplementation.requestExactAlarmsPermission();

    if (await canScheduleExact()) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static _ReminderTime _resolveReminderTime(SharedPreferences prefs) {
    final stored = prefs.getString(_attendanceReminderTimeKey);
    if (stored != null) {
      final parsed = _parseStoredReminderTime(stored);
      if (parsed != null) {
        return _clampReminderTime(parsed);
      }
    }

    return _attendanceReminderDefaultTime;
  }

  static _ReminderTime _clampReminderTime(_ReminderTime time) {
    final reminderDuration = Duration(hours: time.hour, minutes: time.minute);
    final start =
    Duration(hours: _attendanceReminderWindowStartHour, minutes: 0);
    final latestAllowed =
    Duration(hours: _attendanceReminderWindowEndHour, minutes: 0);

    if (reminderDuration < start) {
      return _attendanceReminderDefaultTime;
    }

    if (reminderDuration > latestAllowed) {
      return _ReminderTime(
        hour: _attendanceReminderWindowEndHour,
        minute: 0,
      );
    }

    return time;
  }

  static _ReminderTime? _parseStoredReminderTime(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return _ReminderTime(hour: hour, minute: minute);
  }

  static String _formatStoredReminderTime(int hour, int minute) {
    final hourLabel = hour.toString().padLeft(2, '0');
    final minuteLabel = minute.toString().padLeft(2, '0');
    return '$hourLabel:$minuteLabel';
  }

  static String _formatReminderTimeLabel(_ReminderTime time) {
    final hourLabel = time.hour.toString().padLeft(2, '0');
    final minuteLabel = time.minute.toString().padLeft(2, '0');
    return '$hourLabel:$minuteLabel';
  }

  static tz.TZDateTime _nextReminderTime(
      tz.TZDateTime from, {
        required int hour,
        required int minute,
      }) {
    final scheduled = tz.TZDateTime(
      tz.local,
      from.year,
      from.month,
      from.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(from)) {
      return scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// NOTE: This is currently unused because backend manages reminders,
  /// but it is kept here in case you want to re-enable local scheduling later.
  static Future<void> _scheduleAttendanceReminder({
    required tz.TZDateTime date,
    required NotificationDetails details,
    required AndroidScheduleMode scheduleMode,
    required _AttendanceReminderCopy copy,
  }) async {
    await _plugin.zonedSchedule(
      _attendanceReminderNotificationId,
      copy.title,
      copy.body,
      date,
      details,
      androidScheduleMode: scheduleMode,
      payload: _encodePayload(<String, String>{
        _payloadTypeKey: _payloadTypeAttendanceReminder,
      }),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static String _encodePayload(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  static Map<String, dynamic>? _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<void> _openDownloadedReport(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath, type: 'application/pdf');
      if (result.type != ResultType.done) {
        debugPrint(
          'Failed to open downloaded report from notification: '
          '${result.message} (${result.type})',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to open downloaded report from notification: $error');
      debugPrint('$stackTrace');
    }
  }

  static Future<void> _storeLastDownloadedReportPath(String filePath) async {
    if (filePath.trim().isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDownloadedReportPathKey, filePath);
  }

  static Future<String?> _loadLastDownloadedReportPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDownloadedReportPathKey);
  }

  static Future<void> _storePendingDownloadedReportPath(String filePath) async {
    if (filePath.trim().isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingDownloadedReportPathKey, filePath);
  }

  static Future<String?> _loadPendingDownloadedReportPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingDownloadedReportPathKey);
  }

  static Future<void> _clearPendingDownloadedReportPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingDownloadedReportPathKey);
  }

  static Future<void> _openPendingDownloadedReportIfNeeded() async {
    final pendingPath = await _loadPendingDownloadedReportPath();
    if (pendingPath == null || pendingPath.trim().isEmpty) {
      return;
    }
    await _clearPendingDownloadedReportPath();
    await _openDownloadedReport(pendingPath);
  }

  static Future<_AttendanceReminderCopy> _resolveAttendanceReminderCopy() async {
    final preferredLanguage = await _sessionManager.getPreferredLanguage();
    return _buildAttendanceReminderCopy(preferredLanguage);
  }

  static _AttendanceReminderCopy _buildAttendanceReminderCopy(
      String? languageCode,
      ) {
    final supportedValues = AppString.localizedValues;
    final fallbackValues = supportedValues['en'] ?? const <String, String>{};
    final normalizedLanguage =
    supportedValues.containsKey(languageCode) ? languageCode : 'en';
    final localizedValues =
        supportedValues[normalizedLanguage] ?? fallbackValues;

    final title = localizedValues['attendanceReminderNotificationTitle'] ??
        fallbackValues['attendanceReminderNotificationTitle'] ??
        _attendanceReminderTitle;
    final body = localizedValues['attendanceReminderNotificationBody'] ??
        fallbackValues['attendanceReminderNotificationBody'] ??
        _attendanceReminderBody;

    return _AttendanceReminderCopy(title: title, body: body);
  }

  static Future<void> _handleAttendanceReminderDeepLink() async {
    final handler = _attendanceReminderTapHandler;
    if (handler == null) {
      _pendingAttendanceReminderTapCount++;
      return;
    }
    await handler();
  }

  static void _flushPendingAttendanceReminderTaps() {
    final handler = _attendanceReminderTapHandler;
    if (handler == null || _pendingAttendanceReminderTapCount == 0) {
      return;
    }

    final pending = _pendingAttendanceReminderTapCount;
    _pendingAttendanceReminderTapCount = 0;
    for (var i = 0; i < pending; i++) {
      scheduleMicrotask(() async {
        final activeHandler = _attendanceReminderTapHandler;
        if (activeHandler != null) {
          await activeHandler();
        }
      });
    }
  }

  static void registerAttendanceReminderTapHandler(
      Future<void> Function() handler,
      ) {
    _attendanceReminderTapHandler = handler;
    _flushPendingAttendanceReminderTaps();
  }

  static Future<_DashboardNotificationCopy> _resolveDashboardNotificationCopy({
    String? overrideTitle,
    String? overrideBody,
  }) async {
    final preferredLanguage = await _sessionManager.getPreferredLanguage();
    return _buildDashboardNotificationCopy(
      preferredLanguage,
      overrideTitle: overrideTitle,
      overrideBody: overrideBody,
    );
  }

  static _DashboardNotificationCopy _buildDashboardNotificationCopy(
      String? languageCode, {
        String? overrideTitle,
        String? overrideBody,
      }) {
    final supportedValues = AppString.localizedValues;
    final fallbackValues = supportedValues['en'] ?? const <String, String>{};
    final normalizedLanguage =
    supportedValues.containsKey(languageCode) ? languageCode : 'en';
    final localizedValues =
        supportedValues[normalizedLanguage] ?? fallbackValues;

    final title = overrideTitle ??
        localizedValues['dashboardNotificationTitle'] ??
        fallbackValues['dashboardNotificationTitle'] ??
        _dashboardDeepLinkTitle;
    final body = overrideBody ??
        localizedValues['dashboardNotificationBody'] ??
        fallbackValues['dashboardNotificationBody'] ??
        _dashboardDeepLinkBody;

    return _DashboardNotificationCopy(title: title, body: body);
  }

  static Future<void> _handleDashboardDeepLink() async {
    final handler = _dashboardDeepLinkHandler;
    if (handler == null) {
      _pendingDashboardTapCount++;
      return;
    }
    await handler();
  }

  static void _flushPendingDashboardTaps() {
    final handler = _dashboardDeepLinkHandler;
    if (handler == null || _pendingDashboardTapCount == 0) {
      return;
    }

    final pending = _pendingDashboardTapCount;
    _pendingDashboardTapCount = 0;
    for (var i = 0; i < pending; i++) {
      scheduleMicrotask(() async {
        final activeHandler = _dashboardDeepLinkHandler;
        if (activeHandler != null) {
          await activeHandler();
        }
      });
    }
  }

  static void registerDashboardDeepLinkHandler(
      Future<void> Function() handler,
      ) {
    _dashboardDeepLinkHandler = handler;
    _flushPendingDashboardTaps();
  }

  static Future<bool> _isAttendanceReminderPending() async {
    final pendingRequests = await _plugin.pendingNotificationRequests();
    for (final request in pendingRequests) {
      if (request.id == _attendanceReminderNotificationId) {
        return true;
      }
    }
    return false;
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ReminderTime {
  const _ReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;
}

class _AttendanceReminderCopy {
  const _AttendanceReminderCopy({required this.title, required this.body});

  final String title;
  final String body;
}

class _DashboardNotificationCopy {
  const _DashboardNotificationCopy({required this.title, required this.body});

  final String title;
  final String body;
}

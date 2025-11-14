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

enum _NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  notDetermined,
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
  static const String _attendanceReminderTitle = 'Attendance Reminder';
  static const String _attendanceReminderBody =
      "Don't forget to mark your attendance for today before the day ends! (Stay consistent and keep your records updated.)";

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
    _notificationsPermissionGranted = _isPermissionStatusGranted(status);
  }

  static Future<_NotificationPermissionStatus> _currentPermissionStatus() async {
    final status = await Permission.notification.status;

    if (_isPermissionStatusGranted(status)) {
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
      return _notificationsPermissionGranted ?? false;
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
    await _plugin.show(id, title, body, notificationDetails);
  }

  static Future<void> showDownloadNotification({
    required String fileName,
    required String filePath,
  }) async {
    if (kIsWeb) {
      return;
    }

    final permissionGranted = await ensurePermissionsRequested();
    if (!permissionGranted) {
      debugPrint(
        '[LocalNotificationService] Notification permission not granted. '
        'Skipping download notification for $fileName.',
      );
      return;
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
      await OpenFilex.open(payload, type: 'application/pdf');
    } catch (error, stackTrace) {
      debugPrint('Failed to open downloaded report from notification: $error');
      debugPrint('$stackTrace');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundNotificationResponse(
    NotificationResponse response,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();
    await _handleNotificationResponse(response);
  }

  static Future<void> scheduleDailyAttendanceReminder() async {
    if (kIsWeb) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    final permissionGranted = await hasNotificationPermissions();
    if (!permissionGranted) {
      debugPrint(
        '[LocalNotificationService] Notifications permission not granted. '
        'Attendance reminder scheduling skipped.',
      );
      await _plugin.cancel(_attendanceReminderNotificationId);
      return;
    }

    await _ensureTimeZoneSetup();

    final scheduleMode = await _preferredAndroidScheduleMode();

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _attendanceReminderChannel.id,
        _attendanceReminderChannel.name,
        channelDescription: _attendanceReminderChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final reminderTime = _resolveReminderTime(prefs);
    final lastMarkedEpoch = prefs.getInt(_lastAttendanceMarkedKey);
    final now = tz.TZDateTime.now(tz.local);

    final DateTime? lastMarkedDate = lastMarkedEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastMarkedEpoch);
    final bool markedToday =
        lastMarkedDate != null && _isSameDate(lastMarkedDate, now);

    var scheduledDate = _nextReminderTime(
      now,
      hour: reminderTime.hour,
      minute: reminderTime.minute,
    );
    String schedulingReason =
        'Scheduling reminder for today at the configured time.';
    if (markedToday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      schedulingReason =
          'Attendance already marked today. Scheduling reminder for the next day.';
    } else if (now.isAfter(scheduledDate)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      schedulingReason =
          'Current time is past the configured reminder. Scheduling for tomorrow.';
    } else if (now.isAtSameMomentAs(scheduledDate)) {
      schedulingReason =
          'Current time matches the configured reminder. Scheduling it immediately for today.';
    }

    await _plugin.cancel(_attendanceReminderNotificationId);
    debugPrint(
      '[LocalNotificationService] Cancelled existing attendance reminder (id: '
      '$_attendanceReminderNotificationId).',
    );
    debugPrint(
      '[LocalNotificationService] $schedulingReason\n'
      '  • Configured reminder time: '
          '${_formatReminderTimeLabel(reminderTime)}\n'
      '  • Now: ${now.toString()}\n'
      '  • Last marked date: ${lastMarkedDate?.toIso8601String() ?? 'never'}\n'
      '  • Scheduling mode: $scheduleMode\n'
      '  • Scheduled fire time: ${scheduledDate.toString()}',
    );

    try {
      await _scheduleAttendanceReminder(
        date: scheduledDate,
        details: notificationDetails,
        scheduleMode: scheduleMode,
      );

      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle &&
          !await _isAttendanceReminderPending()) {
        debugPrint(
          '[LocalNotificationService] Exact alarm scheduling appears to be '
          'blocked. Retrying attendance reminder with inexact mode.',
        );
        await _scheduleAttendanceReminder(
          date: scheduledDate,
          details: notificationDetails,
          scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } on PlatformException catch (error, stackTrace) {
      final isExactAlarmError = error.code == 'exact_alarms_not_permitted';
      final alreadyInexact =
          scheduleMode == AndroidScheduleMode.inexactAllowWhileIdle;

      if (!isExactAlarmError || alreadyInexact) {
        debugPrint('Failed to schedule daily attendance reminder: $error');
        debugPrint('$stackTrace');
        rethrow;
      }

      debugPrint(
        'Exact alarm scheduling is not permitted. Falling back to inexact scheduling.',
      );
      debugPrint('$stackTrace');
      debugPrint(
        '[LocalNotificationService] Retrying scheduling with inexact mode for '
        '${scheduledDate.toString()}.',
      );

      await _scheduleAttendanceReminder(
        date: scheduledDate,
        details: notificationDetails,
        scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static Future<void> onAttendanceMarked({DateTime? timestamp}) async {
    if (kIsWeb) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final markTime = timestamp ?? DateTime.now();
    final normalized = DateTime(markTime.year, markTime.month, markTime.day);
    await prefs.setInt(
      _lastAttendanceMarkedKey,
      normalized.millisecondsSinceEpoch,
    );

    await scheduleDailyAttendanceReminder();
  }

  static Future<void> updateAttendanceReminderTime(TimeOfDay time) async {
    if (kIsWeb) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final formatted = _formatStoredReminderTime(time.hour, time.minute);
    await prefs.setString(_attendanceReminderTimeKey, formatted);

    await scheduleDailyAttendanceReminder();
  }

  static Future<TimeOfDay> currentAttendanceReminderTime() async {
    if (kIsWeb) {
      return const TimeOfDay(hour: 20, minute: 0);
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
        return parsed;
      }
    }

    return const _ReminderTime(hour: 20, minute: 0);
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

  static Future<void> _scheduleAttendanceReminder({
    required tz.TZDateTime date,
    required NotificationDetails details,
    required AndroidScheduleMode scheduleMode,
  }) async {
    await _plugin.zonedSchedule(
      _attendanceReminderNotificationId,
      _attendanceReminderTitle,
      _attendanceReminderBody,
      date,
      details,
      // Ensure the reminder still fires even if the device enters doze mode
      // while the app is terminated.
      androidAllowWhileIdle: true,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

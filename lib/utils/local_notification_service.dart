import 'package:attendancepro/utils/native_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _timeZoneInitialized = false;

  static const AndroidNotificationChannel _downloadChannel =
      AndroidNotificationChannel(
    'downloads_channel',
    'Downloads',
    description: 'Notifications about saved reports',
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
  static const String _attendanceReminderTitle = 'Attendance Reminder';
  static const String _attendanceReminderBody =
      "Don't forget to mark your attendance for today before the day ends! (Stay consistent and keep your records updated.)";

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
    await androidImplementation
        ?.createNotificationChannel(_attendanceReminderChannel);
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
    final lastMarkedEpoch = prefs.getInt(_lastAttendanceMarkedKey);
    final now = tz.TZDateTime.now(tz.local);

    final DateTime? lastMarkedDate = lastMarkedEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastMarkedEpoch);
    final bool markedToday =
        lastMarkedDate != null && _isSameDate(lastMarkedDate, now);

    var scheduledDate = _nextEightPm(now);
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

  static tz.TZDateTime _nextEightPm(tz.TZDateTime from) {
    final scheduled = tz.TZDateTime(
      tz.local,
      from.year,
      from.month,
      from.day,
      10,
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

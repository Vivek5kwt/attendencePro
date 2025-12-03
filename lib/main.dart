import 'package:attendancepro/repositories/attendance_repository.dart';
import 'package:attendancepro/utils/local_notification_service.dart';
import 'package:attendancepro/widgets/attendance_pro_app.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.initialize();
  await LocalNotificationService.ensurePermissionsRequested(
    markPromptAnswered: false,
  );
  await LocalNotificationService.scheduleDailyAttendanceReminder();
  await MobileAds.instance.initialize();

  final repo = InMemoryAttendanceRepository();
  runApp(AttendanceProApp(repository: repo));
}

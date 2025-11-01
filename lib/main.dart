import 'package:attendancepro/repositories/attendance_repository.dart';
import 'package:attendancepro/utils/local_notification_service.dart';
import 'package:attendancepro/widgets/attendance_pro_app.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.initialize();

  final repo = InMemoryAttendanceRepository();
  runApp(AttendanceProApp(repository: repo));
}

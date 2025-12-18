import 'package:attendancepro/repositories/attendance_repository.dart';
import 'package:attendancepro/utils/ad_preload_service.dart';
import 'package:attendancepro/widgets/attendance_pro_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  AdPreloadService.instance.preloadDashboardBanner();

  final repo = InMemoryAttendanceRepository();
  runApp(AttendanceProApp(repository: repo));
}

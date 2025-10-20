import 'package:attendancepro/repositories/attendance_repository.dart';
import 'package:attendancepro/widgets/attendance_pro_app.dart';
import 'package:flutter/material.dart';

void main() {
  final repo = InMemoryAttendanceRepository();
  runApp(AttendanceProApp(repository: repo));
}
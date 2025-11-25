import 'package:flutter/material.dart';

import '../models/attendance_history.dart';

double resolveEntryTotalHours(AttendanceHistoryEntryData entry) {
  final recordedHours = entry.hoursWorked + entry.overtimeHours;
  if (recordedHours > 0) {
    return recordedHours;
  }

  final start = _parseTime(entry.startTime);
  final end = _parseTime(entry.endTime);
  if (start == null || end == null) {
    return recordedHours;
  }

  final startMinutes = start.hour * 60 + start.minute;
  final endMinutes = end.hour * 60 + end.minute;
  final difference = endMinutes - startMinutes;
  if (difference <= 0) {
    return recordedHours;
  }

  return double.parse((difference / 60).toStringAsFixed(2));
}

TimeOfDay? _parseTime(String? value) {
  final label = value?.trim();
  if (label == null || label.isEmpty) {
    return null;
  }

  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(label);
  if (match == null) {
    return null;
  }

  var hours = int.tryParse(match.group(1) ?? '');
  final minutes = int.tryParse(match.group(2) ?? '');
  if (hours == null || minutes == null) {
    return null;
  }

  final lowerLabel = label.toLowerCase();
  final hasPm = lowerLabel.contains('pm');
  final hasAm = lowerLabel.contains('am');
  if (hasPm && hours < 12) {
    hours += 12;
  } else if (hasAm && hours == 12) {
    hours = 0;
  }

  hours = hours.clamp(0, 23);
  final resolvedMinutes = minutes.clamp(0, 59);

  return TimeOfDay(hour: hours, minute: resolvedMinutes);
}

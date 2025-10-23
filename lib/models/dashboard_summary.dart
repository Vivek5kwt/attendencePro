class DashboardSummary {
  DashboardSummary({
    required this.workId,
    required this.totalHours,
    required this.totalSalary,
    this.todayEntry,
    Map<String, dynamic>? raw,
  }) : raw = Map.unmodifiable(raw ?? const <String, dynamic>{});

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final data = _extractDataMap(json);
    final today = data['today_entry'] ?? data['todayEntry'];
    return DashboardSummary(
      workId: _parseWorkId(data),
      totalHours: _parseDouble(data['total_hours'] ?? data['totalHours']) ?? 0,
      totalSalary: _parseDouble(data['total_salary'] ?? data['totalSalary']) ?? 0,
      todayEntry: today is Map<String, dynamic>
          ? DashboardAttendanceEntry.fromJson(today)
          : null,
      raw: Map<String, dynamic>.from(data),
    );
  }

  final String workId;
  final double totalHours;
  final double totalSalary;
  final DashboardAttendanceEntry? todayEntry;
  final Map<String, dynamic> raw;

  static Map<String, dynamic> _extractDataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return json;
  }

  static String _parseWorkId(Map<String, dynamic> json) {
    const possibleKeys = ['work_id', 'workId', 'id'];
    for (final key in possibleKeys) {
      final value = json[key];
      if (value == null) continue;
      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty) {
        return stringValue;
      }
    }
    return '';
  }
}

class DashboardAttendanceEntry {
  DashboardAttendanceEntry({
    this.dateText,
    this.startTimeText,
    this.endTimeText,
    this.breakDurationText,
    this.totalHours,
    this.totalSalary,
    this.isLeave,
    Map<String, dynamic>? raw,
  }) : raw = Map.unmodifiable(raw ?? const <String, dynamic>{});

  factory DashboardAttendanceEntry.fromJson(Map<String, dynamic> json) {
    final dateText = _firstString(json, const ['date', 'entry_date', 'attendance_date']);
    final startTimeText =
        _firstString(json, const ['start_time', 'startTime', 'in_time']);
    final endTimeText = _firstString(json, const ['end_time', 'endTime', 'out_time']);
    final breakDurationText = _resolveBreakText(json);
    final totalHours =
        _parseDouble(json['total_hours'] ?? json['hours'] ?? json['totalHours']);
    final totalSalary =
        _parseDouble(json['total_salary'] ?? json['salary'] ?? json['totalSalary']);
    final isLeave = _parseBool(json['is_leave'] ?? json['leave'] ?? json['isLeave']);

    return DashboardAttendanceEntry(
      dateText: dateText,
      startTimeText: startTimeText,
      endTimeText: endTimeText,
      breakDurationText: breakDurationText,
      totalHours: totalHours,
      totalSalary: totalSalary,
      isLeave: isLeave,
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String? dateText;
  final String? startTimeText;
  final String? endTimeText;
  final String? breakDurationText;
  final double? totalHours;
  final double? totalSalary;
  final bool? isLeave;
  final Map<String, dynamic> raw;
}

double? _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final sanitized = value.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.\-]'), '').trim();
    if (sanitized.isEmpty) {
      return null;
    }
    return double.tryParse(sanitized);
  }
  return null;
}

bool? _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (['true', '1', 'yes', 'y'].contains(normalized)) {
      return true;
    }
    if (['false', '0', 'no', 'n'].contains(normalized)) {
      return false;
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

String? _resolveBreakText(Map<String, dynamic> json) {
  final value =
      json['break_time'] ?? json['breakTime'] ?? json['break_minutes'] ?? json['breakMinutes'];
  if (value == null) {
    return null;
  }
  if (value is num) {
    final minutes = value.round();
    if (minutes <= 0) {
      return '0 min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0 && remainingMinutes > 0) {
      return '${hours}h ${remainingMinutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes} min';
  }
  final stringValue = value.toString().trim();
  if (stringValue.isEmpty) {
    return null;
  }
  return stringValue;
}

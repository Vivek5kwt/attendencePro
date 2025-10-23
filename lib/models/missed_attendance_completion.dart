class MissedAttendanceCompletion {
  MissedAttendanceCompletion({
    required this.workId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.breakMinutes,
    this.isLeave = false,
  });

  final Object workId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int breakMinutes;
  final bool isLeave;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'work_id': _normalizeWorkId(workId),
      'date': _formatDate(date),
      'start_time': startTime,
      'end_time': endTime,
      'break_minutes': breakMinutes,
    };
    if (isLeave) {
      payload['is_leave'] = true;
    }
    return payload;
  }

  static dynamic _normalizeWorkId(Object value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final stringValue = value.toString();
    final parsed = int.tryParse(stringValue);
    return parsed ?? stringValue;
  }

  static String _formatDate(DateTime date) {
    final iso = date.toIso8601String();
    final separatorIndex = iso.indexOf('T');
    if (separatorIndex == -1) {
      return iso;
    }
    return iso.substring(0, separatorIndex);
  }
}

class MissedAttendanceCompletionRequest {
  const MissedAttendanceCompletionRequest({required this.items})
      : assert(items.length > 0, 'At least one item is required.');

  final List<MissedAttendanceCompletion> items;

  Map<String, dynamic> toJson() {
    return {
      'missed': items.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

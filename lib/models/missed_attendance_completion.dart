class MissedAttendanceCompletion {
  MissedAttendanceCompletion({
    required this.workId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.breakMinutes,
    this.contractTypeId,
    this.isLeave = false,
  });

  final Object workId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int breakMinutes;
  final Object? contractTypeId;
  final bool isLeave;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'work_id': _normalizeWorkId(workId),
      'date': _formatDate(date),
      'start_time': startTime,
      'end_time': endTime,
      'break_minutes': breakMinutes,
    };
   /* if (contractTypeId != null) {*/
      payload['contract_type_id'] =
          1;
   // }
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

  static dynamic _normalizeContractTypeId(Object value) {
    final resolved = _resolveContractTypeIdentifier(value);
    if (resolved is int) {
      return resolved;
    }
    if (resolved is num) {
      return resolved.toInt();
    }
    if (resolved is String) {
      final trimmed = resolved.trim();
      if (trimmed.isEmpty) {
        return trimmed;
      }
      final parsed = int.tryParse(trimmed);
      return parsed ?? trimmed;
    }
    if (resolved != null) {
      return resolved;
    }

    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is Map) {
      return _resolveContractTypeIdentifier(value) ?? '';
    }
    final stringValue = value.toString();
    final parsed = int.tryParse(stringValue);
    return parsed ?? stringValue.trim();
  }

  static dynamic? _resolveContractTypeIdentifier(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final parsed = int.tryParse(trimmed);
      return parsed ?? trimmed;
    }
    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();
      const candidateKeys = <String>[
        'id',
        'contract_type_id',
        'contractTypeId',
        'contract_type',
        'contractType',
        'value',
      ];
      for (final key in candidateKeys) {
        if (!map.containsKey(key)) {
          continue;
        }
        final resolved = _resolveContractTypeIdentifier(map[key]);
        if (resolved != null) {
          return resolved;
        }
      }
      for (final entry in map.entries) {
        final resolved = _resolveContractTypeIdentifier(entry.value);
        if (resolved != null) {
          return resolved;
        }
      }
    }
    return null;
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

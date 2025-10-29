class AttendanceHistoryData {
  const AttendanceHistoryData({
    required this.entries,
    required this.currencySymbol,
  });

  factory AttendanceHistoryData.fromResponse(
    dynamic response, {
    String? fallbackWorkName,
  }) {
    final root = _ensureMap(response);
    final data = _ensureMap(root?['data']) ?? root;

    final rawEntries = _extractEntriesList(data) ??
        (response is List ? response : const <dynamic>[]);

    final entries = <AttendanceHistoryEntryData>[];
    for (final item in rawEntries) {
      final map = _ensureMap(item);
      if (map == null) {
        continue;
      }
      final entry = AttendanceHistoryEntryData.fromJson(
        map,
        fallbackWorkName: fallbackWorkName,
      );
      if (entry != null) {
        entries.add(entry);
      }
    }

    final explicitCurrency = _extractCurrencySymbol(data);
    final detectedCurrency =
        explicitCurrency ?? _firstNonEmptyCurrency(entries);

    final resolvedEntries = (fallbackWorkName == null ||
            fallbackWorkName.trim().isEmpty)
        ? entries
        : entries
            .map(
              (entry) => entry.workName.trim().isEmpty
                  ? entry.copyWith(workName: fallbackWorkName)
                  : entry,
            )
            .toList(growable: false);

    final currencySymbol = (detectedCurrency ?? '').trim().isEmpty
        ? '€'
        : detectedCurrency!.trim();

    return AttendanceHistoryData(
      entries: resolvedEntries,
      currencySymbol: currencySymbol,
    );
  }

  final List<AttendanceHistoryEntryData> entries;
  final String currencySymbol;
}

class AttendanceHistoryEntryData {
  const AttendanceHistoryEntryData({
    required this.date,
    required this.workName,
    required this.type,
    this.startTime,
    this.endTime,
    this.breakDuration,
    this.hoursWorked = 0,
    this.overtimeHours = 0,
    this.contractType,
    this.unitsCompleted,
    this.ratePerUnit,
    this.leaveReason,
    required this.salary,
    this.detectedCurrencySymbol,
  });

  final DateTime date;
  final String workName;
  final AttendanceHistoryEntryType type;
  final String? startTime;
  final String? endTime;
  final String? breakDuration;
  final double hoursWorked;
  final double overtimeHours;
  final String? contractType;
  final int? unitsCompleted;
  final double? ratePerUnit;
  final String? leaveReason;
  final double salary;
  final String? detectedCurrencySymbol;

  AttendanceHistoryEntryData copyWith({
    DateTime? date,
    String? workName,
    AttendanceHistoryEntryType? type,
    String? startTime,
    String? endTime,
    String? breakDuration,
    double? hoursWorked,
    double? overtimeHours,
    String? contractType,
    int? unitsCompleted,
    double? ratePerUnit,
    String? leaveReason,
    double? salary,
    String? detectedCurrencySymbol,
  }) {
    return AttendanceHistoryEntryData(
      date: date ?? this.date,
      workName: workName ?? this.workName,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakDuration: breakDuration ?? this.breakDuration,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      contractType: contractType ?? this.contractType,
      unitsCompleted: unitsCompleted ?? this.unitsCompleted,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      leaveReason: leaveReason ?? this.leaveReason,
      salary: salary ?? this.salary,
      detectedCurrencySymbol:
          detectedCurrencySymbol ?? this.detectedCurrencySymbol,
    );
  }

  static AttendanceHistoryEntryData? fromJson(
    Map<String, dynamic> json, {
    String? fallbackWorkName,
  }) {
    final date = _parseDate(json);
    if (date == null) {
      return null;
    }

    final workName =
        _parseWorkName(json) ?? fallbackWorkName ?? '';
    final type = _parseType(json);

    final hoursWorked = _parseDouble(json, const [
      'hours_worked',
      'hoursWorked',
      'total_hours',
      'totalHours',
      'hours',
      'worked_hours',
      'workedHours',
    ]);

    final overtimeHours = _parseDouble(json, const [
      'overtime_hours',
      'overtimeHours',
      'overtime',
      'extra_hours',
      'extraHours',
    ]);

    final unitsCompleted = _parseInt(json, const [
      'units_completed',
      'unitsCompleted',
      'units',
      'quantity',
      'unit_count',
      'unitCount',
    ]);

    final rateAmount = _parseAmountFromKeys(json, const [
      'rate_per_unit',
      'ratePerUnit',
      'unit_rate',
      'unitRate',
      'rate',
      'amount_per_unit',
      'amountPerUnit',
    ]);

    final salaryAmount = _parseAmountFromKeys(
      json,
      const [
        'salary',
        'amount',
        'total_salary',
        'totalSalary',
        'earning',
        'earnings',
        'payout',
        'payment',
        'net_salary',
        'netSalary',
      ],
      fallbackSymbol: rateAmount.symbol,
    );

    final leaveReason = _parseString(json, const [
      'leave_reason',
      'leaveReason',
      'reason',
      'note',
      'notes',
      'remarks',
      'remark',
    ]);

    final contractType = _parseString(json, const [
      'contract_type',
      'contractType',
      'unit_type',
      'unitType',
      'work_type',
      'workType',
      'type_label',
      'typeLabel',
    ]);

    return AttendanceHistoryEntryData(
      date: date,
      workName: workName,
      type: type,
      startTime: _parseTimeLabel(json, const [
        'start_time',
        'startTime',
        'clock_in',
        'clockIn',
        'check_in',
        'checkIn',
        'in_time',
        'inTime',
      ]),
      endTime: _parseTimeLabel(json, const [
        'end_time',
        'endTime',
        'clock_out',
        'clockOut',
        'check_out',
        'checkOut',
        'out_time',
        'outTime',
      ]),
      breakDuration: _parseBreakDuration(json),
      hoursWorked: hoursWorked,
      overtimeHours: overtimeHours,
      contractType: contractType,
      unitsCompleted: unitsCompleted,
      ratePerUnit: rateAmount.value,
      leaveReason: leaveReason,
      salary: salaryAmount.value ?? 0,
      detectedCurrencySymbol:
          salaryAmount.symbol ?? rateAmount.symbol,
    );
  }
}

enum AttendanceHistoryEntryType { hourly, contract, leave }

class _ParsedAmount {
  const _ParsedAmount({this.value, this.symbol});

  final double? value;
  final String? symbol;
}

Map<String, dynamic>? _ensureMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, dynamic v) => MapEntry(key.toString(), v),
    );
  }
  return null;
}

List<dynamic>? _extractEntriesList(Map<String, dynamic>? data,
    [int depth = 0]) {
  if (data == null || depth > 4) {
    return null;
  }

  const candidates = <String>[
    'entries',
    'records',
    'items',
    'history',
    'attendance',
    'logs',
    'list',
    'data',
    'results',
    'timeline',
  ];

  for (final key in candidates) {
    final value = data[key];
    if (value is List) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      final nested = _extractEntriesList(value, depth + 1);
      if (nested != null) {
        return nested;
      }
    }
  }

  for (final value in data.values) {
    if (value is List) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      final nested = _extractEntriesList(value, depth + 1);
      if (nested != null) {
        return nested;
      }
    }
  }

  return null;
}

String? _extractCurrencySymbol(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }

  const currencyKeys = <String>[
    'currency_symbol',
    'currencySymbol',
    'currency',
    'currency_sign',
    'currencySign',
    'currency_code',
    'currencyCode',
    'symbol',
  ];

  for (final key in currencyKeys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  const nestedKeys = <String>[
    'meta',
    'summary',
    'totals',
    'settings',
    'config',
  ];

  for (final key in nestedKeys) {
    final nested = _ensureMap(data[key]);
    final result = _extractCurrencySymbol(nested);
    if (result != null && result.trim().isNotEmpty) {
      return result.trim();
    }
  }

  return null;
}

String? _firstNonEmptyCurrency(
    List<AttendanceHistoryEntryData> entries) {
  for (final entry in entries) {
    final symbol = entry.detectedCurrencySymbol;
    if (symbol != null && symbol.trim().isNotEmpty) {
      return symbol.trim();
    }
  }
  return null;
}

AttendanceHistoryEntryType _parseType(Map<String, dynamic> json) {
  final rawType = _parseString(json, const [
        'type',
        'entry_type',
        'entryType',
        'attendance_type',
        'attendanceType',
        'category',
        'kind',
        'mode',
      ])?.toLowerCase() ??
      '';

  if (rawType.contains('leave') ||
      rawType.contains('holiday') ||
      rawType.contains('absent')) {
    return AttendanceHistoryEntryType.leave;
  }
  if (rawType.contains('contract') ||
      rawType.contains('piece') ||
      rawType.contains('unit')) {
    return AttendanceHistoryEntryType.contract;
  }

  final isContract = _parseBool(json, const [
    'is_contract',
    'isContract',
    'contract',
    'is_piecework',
    'isPiecework',
  ]);
  if (isContract == true) {
    return AttendanceHistoryEntryType.contract;
  }

  final isLeave = _parseBool(json, const [
    'is_leave',
    'isLeave',
    'on_leave',
    'onLeave',
  ]);
  if (isLeave == true) {
    return AttendanceHistoryEntryType.leave;
  }

  if (_hasAny(json, const [
    'leave_reason',
    'leaveReason',
    'reason',
    'on_leave',
    'is_leave',
  ])) {
    return AttendanceHistoryEntryType.leave;
  }

  if (_hasAny(json, const [
    'units_completed',
    'unitsCompleted',
    'units',
    'contract_type',
    'contractType',
  ])) {
    return AttendanceHistoryEntryType.contract;
  }

  final numericType = json['type'];
  if (numericType is int) {
    if (numericType == 1) {
      return AttendanceHistoryEntryType.leave;
    }
    if (numericType >= 2) {
      return AttendanceHistoryEntryType.contract;
    }
  }

  return AttendanceHistoryEntryType.hourly;
}

bool _hasAny(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      final value = json[key];
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      if (value is bool && !value) {
        continue;
      }
      return true;
    }
  }
  return false;
}

String? _parseWorkName(Map<String, dynamic> json) {
  final direct = _parseString(json, const [
    'work_name',
    'workName',
    'work',
    'job',
    'job_name',
    'jobName',
    'project',
    'project_name',
    'projectName',
  ]);
  if (direct != null && direct.trim().isNotEmpty) {
    return direct.trim();
  }

  final nestedWork = _ensureMap(json['work']);
  if (nestedWork != null) {
    final nestedName = _parseWorkName(nestedWork);
    if (nestedName != null && nestedName.trim().isNotEmpty) {
      return nestedName.trim();
    }
  }

  return null;
}

DateTime? _parseDate(Map<String, dynamic> json) {
  const keys = <String>[
    'date',
    'attendance_date',
    'attendanceDate',
    'entry_date',
    'entryDate',
    'work_date',
    'workDate',
    'day',
    'log_date',
    'logDate',
    'created_at',
    'createdAt',
    'timestamp',
  ];

  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final parsed = _parseDateValue(json[key]);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

DateTime? _parseDateValue(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.contains('T')
        ? trimmed
        : trimmed.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }

    final numeric = double.tryParse(trimmed);
    if (numeric != null) {
      return _parseEpoch(numeric);
    }

    final parts = trimmed
        .replaceAll('\\', '-')
        .replaceAll('/', '-')
        .split('-');
    if (parts.length >= 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a != null && b != null && c != null) {
        if (a > 1900 && c <= 31) {
          return DateTime(a, b, c);
        }
        if (c > 1900 && a <= 31) {
          return DateTime(c, a, b);
        }
      }
    }

    return null;
  }
  if (value is int) {
    return _parseEpoch(value.toDouble());
  }
  if (value is double) {
    return _parseEpoch(value);
  }
  if (value is Map<String, dynamic>) {
    return _parseDateValue(value['date'] ?? value['value']);
  }
  return null;
}

DateTime? _parseEpoch(double value) {
  if (value > 1000000000000) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value > 1000000000) {
    return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
  }
  return null;
}

String? _parseTimeLabel(
    Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final result = _parseTimeValue(json[key]);
    if (result != null) {
      return result;
    }
  }
  return null;
}

String? _parseTimeValue(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(trimmed.contains('T')
        ? trimmed
        : trimmed.replaceFirst(' ', 'T'));
    if (parsed != null) {
      final two = (int v) => v.toString().padLeft(2, '0');
      return '${two(parsed.hour)}:${two(parsed.minute)}';
    }

    if (trimmed.contains(':')) {
      final segments = trimmed.split(':');
      if (segments.length >= 2) {
        final two = (String v) => v.padLeft(2, '0');
        return '${two(segments[0])}:${two(segments[1])}';
      }
    }

    return trimmed;
  }
  if (value is int) {
    final minutes = value % 60;
    final hours = value ~/ 60;
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(hours)}:${two(minutes)}';
  }
  if (value is double) {
    final minutes = (value % 60).round();
    final hours = value ~/ 60;
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(hours)}:${two(minutes)}';
  }
  if (value is Map<String, dynamic>) {
    return _parseTimeValue(value['time'] ?? value['value']);
  }
  return null;
}

String? _parseBreakDuration(Map<String, dynamic> json) {
  const keys = <String>[
    'break_duration',
    'breakDuration',
    'break_minutes',
    'breakMinutes',
    'break',
    'break_time',
    'breakTime',
  ];

  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final value = json[key];
    if (value == null) {
      continue;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed.contains(':')) {
        final segments = trimmed.split(':');
        if (segments.length >= 2) {
          final hours = int.tryParse(segments[0]) ?? 0;
          final minutes = int.tryParse(segments[1]) ?? 0;
          if (hours > 0 && minutes > 0) {
            return '${hours}h ${minutes}m';
          }
          if (hours > 0) {
            return '${hours}h';
          }
          if (minutes > 0) {
            return '${minutes}m';
          }
        }
      }
      final numeric = int.tryParse(trimmed);
      if (numeric != null) {
        return '${numeric}m';
      }
      return trimmed;
    }

    if (value is int) {
      return value >= 60
          ? _formatDuration(Duration(minutes: value))
          : '${value}m';
    }

    if (value is double) {
      final rounded = value.round();
      return rounded >= 60
          ? _formatDuration(Duration(minutes: rounded))
          : '${rounded}m';
    }
  }

  return null;
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  }
  if (hours > 0) {
    return '${hours}h';
  }
  return '${minutes}m';
}

double _parseDouble(Map<String, dynamic> json, List<String> keys,
    {double defaultValue = 0}) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final parsed = _parseAmount(json[key]);
    if (parsed.value != null) {
      return parsed.value!;
    }
  }
  return defaultValue;
}

int? _parseInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final parsed = int.tryParse(trimmed);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

_ParsedAmount _parseAmountFromKeys(
  Map<String, dynamic> json,
  List<String> keys, {
  String? fallbackSymbol,
}) {
  String? detectedSymbol = fallbackSymbol;
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final parsed = _parseAmount(json[key]);
    if (parsed.symbol != null && parsed.symbol!.trim().isNotEmpty) {
      detectedSymbol = parsed.symbol!.trim();
    }
    if (parsed.value != null) {
      return _ParsedAmount(
        value: parsed.value,
        symbol: detectedSymbol ?? parsed.symbol,
      );
    }
  }
  return _ParsedAmount(value: null, symbol: detectedSymbol);
}

_ParsedAmount _parseAmount(dynamic value) {
  if (value is num) {
    return _ParsedAmount(value: value.toDouble());
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const _ParsedAmount();
    }
    final numericBuffer = StringBuffer();
    final symbolBuffer = StringBuffer();
    for (final rune in trimmed.runes) {
      final ch = String.fromCharCode(rune);
      if ('0123456789.-'.contains(ch)) {
        numericBuffer.write(ch);
      } else if (ch.trim().isNotEmpty) {
        symbolBuffer.write(ch);
      }
    }
    final parsedValue = double.tryParse(numericBuffer.toString());
    final symbol = symbolBuffer.toString().trim();
    return _ParsedAmount(
      value: parsedValue,
      symbol: symbol.isEmpty ? null : symbol,
    );
  }
  if (value is Map<String, dynamic>) {
    return _parseAmount(value['amount'] ?? value['value']);
  }
  return const _ParsedAmount();
}

String? _parseString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool? _parseBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final parsed = _resolveBool(json[key]);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

bool? _resolveBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (['true', '1', 'yes', 'y', 'on'].contains(normalized)) {
      return true;
    }
    if (['false', '0', 'no', 'n', 'off'].contains(normalized)) {
      return false;
    }
  }
  return null;
}

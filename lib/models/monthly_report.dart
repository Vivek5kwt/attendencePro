import 'dart:convert';

enum MonthlyReportType { hourly, fixed, unknown }

MonthlyReportType monthlyReportTypeFromString(String? value) {
  if (value == null) {
    return MonthlyReportType.unknown;
  }
  final normalized = value.toString().trim().toLowerCase();
  switch (normalized) {
    case 'hourly':
    case 'hourly_work':
    case 'hourlywork':
      return MonthlyReportType.hourly;
    case 'fixed':
    case 'fixed_salary':
    case 'salary':
    case 'contract':
      return MonthlyReportType.fixed;
    default:
      return MonthlyReportType.unknown;
  }
}

extension MonthlyReportTypeRequest on MonthlyReportType {
  String get apiValue {
    switch (this) {
      case MonthlyReportType.hourly:
        return 'hourly';
      case MonthlyReportType.fixed:
        return 'fixed';
      case MonthlyReportType.unknown:
        return 'hourly';
    }
  }
}

class MonthlyReport {
  const MonthlyReport({
    required this.monthName,
    required this.year,
    required this.type,
    required this.days,
    this.currencySymbol,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    final data = _ensureMap(json['data']) ?? json;

    final monthName = _parseString(
      data,
      const ['month', 'month_name', 'monthName', 'label'],
    );
    final year = _parseInt(data, const ['year', 'year_number', 'yearNumber'], 0);
    final type = monthlyReportTypeFromString(data['type']);
    final currencySymbol = _parseString(
      data,
      const ['currency_symbol', 'currencySymbol', 'currency'],
    );

    final days = <MonthlyReportDay>[];
    final rawDays = data['days'] ?? data['entries'] ?? data['records'];
    if (rawDays is List) {
      for (final entry in rawDays) {
        final map = _ensureMap(entry);
        if (map == null) {
          continue;
        }
        days.add(MonthlyReportDay.fromJson(map));
      }
    }

    return MonthlyReport(
      monthName: monthName.isNotEmpty ? monthName : 'Month',
      year: year,
      type: type,
      days: days,
      currencySymbol: currencySymbol?.trim().isEmpty ?? true
          ? null
          : currencySymbol?.trim(),
    );
  }

  final String monthName;
  final int year;
  final MonthlyReportType type;
  final List<MonthlyReportDay> days;
  final String? currencySymbol;

  MonthlyReport copyWith({
    MonthlyReportType? type,
    List<MonthlyReportDay>? days,
    String? monthName,
    int? year,
    String? currencySymbol,
  }) {
    return MonthlyReport(
      monthName: monthName ?? this.monthName,
      year: year ?? this.year,
      type: type ?? this.type,
      days: days ?? this.days,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}

class MonthlyReportDay {
  const MonthlyReportDay({
    required this.label,
    this.date,
    this.status,
    this.type,
    this.hoursWorked,
    this.overtimeHours,
    this.salary,
    this.salaryLabel,
    this.currencySymbol,
    this.unitsCompleted,
    this.notes = const <String>[],
    this.details = const <MonthlyReportDayDetail>[],
  });

  factory MonthlyReportDay.fromJson(Map<String, dynamic> json) {
    final date = _parseDate(json);
    final label = _parseString(json, const [
          'label',
          'date_label',
          'day_label',
          'display_date',
          'day',
        ]) ??
        (date != null ? _formatDate(date) : 'Day');

    final status = _parseString(json, const [
      'status',
      'attendance_status',
      'state',
      'result',
    ]);
    final type = _parseString(json, const [
      'type',
      'work_type',
      'category',
      'mode',
    ]);
    final hoursWorked = _parseNullableDouble(json, const [
      'hours_worked',
      'hoursWorked',
      'hours',
      'total_hours',
      'worked_hours',
    ]);
    final overtimeHours = _parseNullableDouble(json, const [
      'overtime',
      'overtime_hours',
      'overtimeHours',
      'extra_hours',
    ]);
    final salary = _parseNullableDouble(json, const [
      'salary',
      'amount',
      'total_salary',
      'totalSalary',
      'earning',
      'earnings',
      'payment',
      'payout',
    ]);
    final salaryLabel = _parseString(json, const [
      'salary_label',
      'amount_label',
      'display_amount',
      'salaryText',
      'salary_text',
    ]);
    final currencySymbol = _parseString(json, const [
      'currency_symbol',
      'currencySymbol',
      'currency',
    ]);
    final unitsCompleted = _parseNullableInt(json, const [
      'units_completed',
      'unitsCompleted',
      'units',
      'quantity',
      'unit_count',
      'unitCount',
    ]);
    final notes = _parseNotes(json);

    final recognizedKeys = <String>{
      'date',
      'date_value',
      'dateValue',
      'day',
      'label',
      'date_label',
      'day_label',
      'display_date',
      'status',
      'attendance_status',
      'state',
      'result',
      'type',
      'work_type',
      'category',
      'mode',
      'hours_worked',
      'hoursWorked',
      'hours',
      'total_hours',
      'worked_hours',
      'overtime',
      'overtime_hours',
      'overtimeHours',
      'extra_hours',
      'salary',
      'amount',
      'total_salary',
      'totalSalary',
      'earning',
      'earnings',
      'payment',
      'payout',
      'salary_label',
      'amount_label',
      'display_amount',
      'salaryText',
      'salary_text',
      'currency_symbol',
      'currencySymbol',
      'currency',
      'units_completed',
      'unitsCompleted',
      'units',
      'quantity',
      'unit_count',
      'unitCount',
      'notes',
      'remarks',
      'comments',
    };

    final details = <MonthlyReportDayDetail>[];
    for (final entry in json.entries) {
      if (recognizedKeys.contains(entry.key)) {
        continue;
      }
      final valueString = _stringify(entry.value);
      if (valueString.isEmpty) {
        continue;
      }
      details.add(
        MonthlyReportDayDetail(
          label: _prettifyKey(entry.key),
          value: valueString,
        ),
      );
    }

    return MonthlyReportDay(
      label: label,
      date: date,
      status: status,
      type: type,
      hoursWorked: hoursWorked,
      overtimeHours: overtimeHours,
      salary: salary,
      salaryLabel: salaryLabel,
      currencySymbol: currencySymbol,
      unitsCompleted: unitsCompleted,
      notes: notes,
      details: details,
    );
  }

  final String label;
  final DateTime? date;
  final String? status;
  final String? type;
  final double? hoursWorked;
  final double? overtimeHours;
  final double? salary;
  final String? salaryLabel;
  final String? currencySymbol;
  final int? unitsCompleted;
  final List<String> notes;
  final List<MonthlyReportDayDetail> details;

  String resolveSalaryLabel(String globalCurrencySymbol) {
    if (salaryLabel != null && salaryLabel!.trim().isNotEmpty) {
      return salaryLabel!.trim();
    }
    if (salary != null) {
      return _formatCurrency(salary!, currencySymbol ?? globalCurrencySymbol);
    }
    return '';
  }

  String? resolveHoursLabel() {
    if (hoursWorked == null) {
      return null;
    }
    final value = hoursWorked!;
    final decimals = value == value.roundToDouble() ? 0 : 2;
    return '${value.toStringAsFixed(decimals)} h';
  }
}

class MonthlyReportDayDetail {
  const MonthlyReportDayDetail({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

Map<String, dynamic>? _ensureMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, dynamic value) => MapEntry(key.toString(), value),
    );
  }
  return null;
}

String _parseString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
  }
  return '';
}

int _parseInt(Map<String, dynamic> json, List<String> keys, [int fallback = 0]) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final sanitized = value.trim();
      if (sanitized.isEmpty) {
        continue;
      }
      final parsed = int.tryParse(sanitized);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
}

double? _parseNullableDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final sanitized = value.replaceAll(',', '').trim();
      if (sanitized.isEmpty) {
        continue;
      }
      final parsed = double.tryParse(sanitized);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

int? _parseNullableInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final sanitized = value.trim();
      if (sanitized.isEmpty) {
        continue;
      }
      final parsed = int.tryParse(sanitized);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

DateTime? _parseDate(Map<String, dynamic> json) {
  final raw = json['date'] ?? json['day'] ?? json['date_value'] ?? json['dateValue'];
  if (raw is DateTime) {
    return raw;
  }
  if (raw is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    } catch (_) {
      return null;
    }
  }
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final isoParsed = DateTime.tryParse(trimmed);
    if (isoParsed != null) {
      return isoParsed;
    }
    final parts = trimmed.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    final slashParts = trimmed.split('/');
    if (slashParts.length == 3) {
      final first = int.tryParse(slashParts[0]);
      final second = int.tryParse(slashParts[1]);
      final third = int.tryParse(slashParts[2]);
      if (first != null && second != null && third != null) {
        // Assume formats like DD/MM/YYYY or YYYY/MM/DD by simple heuristics.
        if (third > 1900) {
          return DateTime(third, second, first);
        }
        return DateTime(first, second, third);
      }
    }
  }
  return null;
}

String _formatDate(DateTime date) {
  const monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final month = monthNames[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

List<String> _parseNotes(Map<String, dynamic> json) {
  final notes = <String>[];
  final rawNotes = json['notes'] ?? json['remarks'] ?? json['comments'];
  if (rawNotes is String) {
    final trimmed = rawNotes.trim();
    if (trimmed.isNotEmpty) {
      notes.add(trimmed);
    }
  } else if (rawNotes is List) {
    for (final entry in rawNotes) {
      if (entry is String) {
        final trimmed = entry.trim();
        if (trimmed.isNotEmpty) {
          notes.add(trimmed);
        }
      }
    }
  }
  return notes;
}

String _formatCurrency(double value, String currencySymbol) {
  final decimals = value == value.roundToDouble() ? 0 : 2;
  final formatted = value.toStringAsFixed(decimals);
  final symbol = currencySymbol.trim();
  if (symbol.isEmpty) {
    return formatted;
  }
  if (symbol.endsWith(' ')) {
    return '$symbol$formatted';
  }
  return '$symbol$formatted';
}

String _stringify(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value.trim();
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

String _prettifyKey(String key) {
  if (key.trim().isEmpty) {
    return key;
  }
  final buffer = StringBuffer();
  bool uppercaseNext = true;
  for (var i = 0; i < key.length; i++) {
    final char = key[i];
    if (char == '_' || char == '-') {
      buffer.write(' ');
      uppercaseNext = true;
      continue;
    }
    if (uppercaseNext) {
      buffer.write(char.toUpperCase());
      uppercaseNext = false;
    } else if (char.toUpperCase() == char && char.toLowerCase() != char) {
      buffer.write(' ');
      buffer.write(char);
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString().trim();
}

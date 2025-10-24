class ReportSummary {
  const ReportSummary({
    required this.combinedSalary,
    required this.hourlySummary,
    required this.contractSummary,
    required this.breakdown,
    required this.currencySymbol,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    final data = _ensureMap(json['data']) ?? json;

    final combinedJson = _ensureMap(
          data['combined_salary'] ??
              data['combinedSalary'] ??
              data['combined_summary'] ??
              data['combinedSummary'] ??
              data['combined'],
        ) ??
        <String, dynamic>{};
    final hourlyJson = _ensureMap(
          data['hourly_summary'] ?? data['hourlySummary'] ?? data['hourly'],
        ) ??
        <String, dynamic>{};
    final contractJson = _ensureMap(
          data['contract_summary'] ??
              data['contractSummary'] ??
              data['contract'],
        ) ??
        <String, dynamic>{};
    final breakdownJson = _ensureMap(
          data['breakdown'] ??
              data['monthly_breakdown'] ??
              data['summary_breakdown'],
        ) ??
        <String, dynamic>{};

    final currencySymbol = _extractCurrencySymbol(
          data,
          combinedJson,
          contractJson,
        ) ??
        '\$';

    return ReportSummary(
      combinedSalary: CombinedSalaryData.fromJson(
        combinedJson.isEmpty ? data : combinedJson,
      ),
      hourlySummary: HourlySummaryData.fromJson(
        hourlyJson.isEmpty ? data : hourlyJson,
      ),
      contractSummary: ContractSummaryData.fromJson(
        contractJson.isEmpty ? data : contractJson,
      ),
      breakdown: SummaryBreakdown.fromJson(
        breakdownJson.isEmpty ? data : breakdownJson,
      ),
      currencySymbol: currencySymbol,
    );
  }

  final CombinedSalaryData combinedSalary;
  final HourlySummaryData hourlySummary;
  final ContractSummaryData contractSummary;
  final SummaryBreakdown breakdown;
  final String currencySymbol;
}

class CombinedSalaryData {
  const CombinedSalaryData({
    required this.amount,
    required this.hoursWorked,
    required this.unitsCompleted,
  });

  factory CombinedSalaryData.fromJson(Map<String, dynamic> json) {
    return CombinedSalaryData(
      amount: _parseDouble(json, const [
        'amount',
        'total',
        'combined_salary',
        'combinedSalary',
        'total_salary',
        'total_combined_salary',
        'grand_total',
        'combined_total',
      ]),
      hoursWorked: _parseDouble(json, const [
        'hours_worked',
        'hoursWorked',
        'total_hours',
        'totalHours',
        'hours',
      ]),
      unitsCompleted: _parseInt(json, const [
        'units_completed',
        'unitsCompleted',
        'total_units',
        'totalUnits',
        'units',
        'completed_units',
        'completedUnits',
      ]),
    );
  }

  final double amount;
  final double hoursWorked;
  final int unitsCompleted;
}

class HourlySummaryData {
  const HourlySummaryData({
    required this.totalHours,
    required this.hourlySalary,
    required this.workingDays,
    required this.averageHoursPerDay,
    required this.lastPayout,
  });

  factory HourlySummaryData.fromJson(Map<String, dynamic> json) {
    return HourlySummaryData(
      totalHours: _parseDouble(json, const [
        'total_hours',
        'totalHours',
        'hours_worked',
        'hoursWorked',
      ]),
      hourlySalary: _parseDouble(json, const [
        'hourly_salary',
        'hourlySalary',
        'hourly_rate',
        'hourlyRate',
        'rate',
        'total_salary',
        'totalSalary',
        'total',
        'salary',
        'amount',
      ]),
      workingDays: _parseInt(json, const [
        'working_days',
        'workingDays',
        'days',
        'days_worked',
        'daysWorked',
      ]),
      averageHoursPerDay: _parseDouble(json, const [
        'average_hours_per_day',
        'averageHoursPerDay',
        'average_hours',
        'averageHours',
      ]),
      lastPayout: _parseDouble(json, const [
        'last_payout',
        'lastPayout',
        'previous_payout',
        'previousPayout',
        'recent_payout',
        'recentPayout',
      ]),
    );
  }

  final double totalHours;
  final double hourlySalary;
  final int workingDays;
  final double averageHoursPerDay;
  final double lastPayout;
}

class ContractSummaryData {
  const ContractSummaryData({
    required this.totalUnits,
    required this.salaryAmount,
    required this.items,
  });

  factory ContractSummaryData.fromJson(Map<String, dynamic> json) {
    final items = <ContractWorkItemData>[];
    final rawItems = json['items'] ?? json['contracts'] ?? json['entries'];
    if (rawItems is List) {
      for (final entry in rawItems) {
        final map = _ensureMap(entry);
        if (map == null) {
          continue;
        }
        items.add(ContractWorkItemData.fromJson(map));
      }
    }

    return ContractSummaryData(
      totalUnits: _parseInt(json, const [
        'total_units',
        'totalUnits',
        'units_completed',
        'unitsCompleted',
        'units',
      ]),
      salaryAmount: _parseDouble(json, const [
        'salary_amount',
        'salaryAmount',
        'total_salary',
        'totalSalary',
        'amount',
      ]),
      items: items,
    );
  }

  final int totalUnits;
  final double salaryAmount;
  final List<ContractWorkItemData> items;
}

class ContractWorkItemData {
  const ContractWorkItemData({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.amountLabel,
    this.indicatorColorValue,
    this.unitsCompleted,
    this.unitsPending,
    this.unitsTotal,
  });

  factory ContractWorkItemData.fromJson(Map<String, dynamic> json) {
    final amountString = _parseString(json, const [
      'amount_label',
      'amountLabel',
      'amount_text',
      'amountText',
      'display_amount',
      'displayAmount',
    ]);

    return ContractWorkItemData(
      title: _parseString(json, const [
        'title',
        'name',
        'label',
      ], fallback: 'Contract Item'),
      subtitle: _parseString(json, const [
        'subtitle',
        'description',
        'details',
        'status_text',
        'statusText',
      ]),
      amount: _parseDouble(json, const [
        'amount',
        'value',
        'salary',
        'earning',
        'earnings',
      ]),
      amountLabel: amountString.isNotEmpty ? amountString : null,
      indicatorColorValue: _parseColorValue(json, const [
        'indicator_color',
        'indicatorColor',
        'color',
      ]),
      unitsCompleted: _parseNullableInt(json, const [
        'units_completed',
        'unitsCompleted',
        'completed_units',
        'completedUnits',
      ]),
      unitsPending: _parseNullableInt(json, const [
        'units_pending',
        'unitsPending',
        'pending_units',
        'pendingUnits',
      ]),
      unitsTotal: _parseNullableInt(json, const [
        'total_units',
        'totalUnits',
        'units',
      ]),
    );
  }

  final String title;
  final String subtitle;
  final double amount;
  final String? amountLabel;
  final int? indicatorColorValue;
  final int? unitsCompleted;
  final int? unitsPending;
  final int? unitsTotal;

  String resolveAmountLabel(String currencySymbol) {
    if (amountLabel != null && amountLabel!.trim().isNotEmpty) {
      return amountLabel!.trim();
    }
    return _formatCurrency(amount, currencySymbol);
  }
}

class SummaryBreakdown {
  const SummaryBreakdown({
    required this.hourlyTotal,
    required this.contractTotal,
    required this.grandTotal,
  });

  factory SummaryBreakdown.fromJson(Map<String, dynamic> json) {
    return SummaryBreakdown(
      hourlyTotal: _parseDouble(json, const [
        'hourly_total',
        'hourlyTotal',
        'hourly_work_total',
        'hourlyWorkTotal',
        'hourly_work',
        'hourlyWork',
      ]),
      contractTotal: _parseDouble(json, const [
        'contract_total',
        'contractTotal',
        'contract_work_total',
        'contractWorkTotal',
        'contract_work',
        'contractWork',
      ]),
      grandTotal: _parseDouble(json, const [
        'grand_total',
        'grandTotal',
        'total',
        'combined_total',
        'combinedTotal',
      ]),
    );
  }

  final double hourlyTotal;
  final double contractTotal;
  final double grandTotal;
}

Map<String, dynamic>? _ensureMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return null;
}

double _parseDouble(Map<String, dynamic> json, List<String> keys,
    [double fallback = 0]) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final cleaned = _sanitizeNumberString(value);
      if (cleaned.isEmpty) {
        continue;
      }
      final parsed = double.tryParse(cleaned);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
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
      final cleaned = _sanitizeNumberString(value, allowDecimal: false);
      if (cleaned.isEmpty) {
        continue;
      }
      final parsed = int.tryParse(cleaned);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
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
      final cleaned = _sanitizeNumberString(value, allowDecimal: false);
      if (cleaned.isEmpty) {
        continue;
      }
      final parsed = int.tryParse(cleaned);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

String _parseString(Map<String, dynamic> json, List<String> keys,
    {String fallback = ''}) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

int? _parseColorValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      var hex = value.trim();
      if (hex.isEmpty) {
        continue;
      }
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      } else if (hex.toLowerCase().startsWith('0x')) {
        hex = hex.substring(2);
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

String? _extractCurrencySymbol(
  Map<String, dynamic> root,
  Map<String, dynamic> combined,
  Map<String, dynamic> contract,
) {
  String? resolve(Map<String, dynamic> json) {
    const keys = [
      'currency_symbol',
      'currencySymbol',
      'currency',
      'symbol',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  return resolve(root) ?? resolve(combined) ?? resolve(contract);
}

String _formatCurrency(double value, String symbol) {
  final absolute = value.abs();
  final isWhole = absolute.floorToDouble() == absolute;
  final precision = isWhole ? 0 : 2;
  final formatted = value.toStringAsFixed(precision);
  if (value < 0) {
    return '-$symbol${formatted.substring(1)}';
  }
  return '$symbol$formatted';
}

String _sanitizeNumberString(String input, {bool allowDecimal = true}) {
  final buffer = <String>[];
  var hasDecimal = false;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    final code = char.codeUnitAt(0);
    final isDigit = code >= 48 && code <= 57;
    if (isDigit) {
      buffer.add(char);
      continue;
    }
    if (char == '-' && buffer.isEmpty) {
      buffer.add(char);
      continue;
    }
    if (char == '.' && allowDecimal && !hasDecimal) {
      buffer.add(char);
      hasDecimal = true;
    }
  }
  return buffer.join();
}

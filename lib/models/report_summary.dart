import 'package:intl/intl.dart';

class ReportSummary {
  const ReportSummary({
    required this.combinedSalary,
    required this.hourlySummary,
    required this.contractSummary,
    required this.breakdown,
    required this.currencySymbol,
    required this.monthlyContractDetails,
    required this.contractDetails,
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

    // Start with whatever the backend places under "hourly" (or aliases)
    Map<String, dynamic> hourlyJson = _ensureMap(
      data['hourly_summary'] ?? data['hourlySummary'] ?? data['hourly'],
    ) ??
        <String, dynamic>{};

    // 🔧 Merge top-level working_days into hourlyJson so HourlySummaryData sees it
    if (data.containsKey('working_days') && hourlyJson['working_days'] == null) {
      hourlyJson = Map<String, dynamic>.from(hourlyJson);
      hourlyJson['working_days'] = data['working_days'];
    }

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
        '€';

    final monthlyContractDetails = _parseMonthlyContractDetails(data);
    final contractDetails = monthlyContractDetails.isNotEmpty
        ? monthlyContractDetails
        : _parseContractDetails(data);

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
      monthlyContractDetails: monthlyContractDetails,
      contractDetails: contractDetails,
    );
  }

  final CombinedSalaryData combinedSalary;
  final HourlySummaryData hourlySummary;
  final ContractSummaryData contractSummary;
  final SummaryBreakdown breakdown;
  final String currencySymbol;
  final List<ContractDetail> monthlyContractDetails;
  final List<ContractDetail> contractDetails;
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
    Iterable<dynamic>? _normalizeItems(dynamic source) {
      if (source == null) return null;
      if (source is List) return source;
      if (source is Set) return source;
      if (source is Iterable) return source;
      if (source is Map) {
        final flattened = <dynamic>[];
        for (final value in source.values) {
          final normalized = _normalizeItems(value);
          if (normalized != null) flattened.addAll(normalized);
        }
        return flattened;
      }
      return null;
    }

    final items = <ContractWorkItemData>[];
    Iterable<dynamic>? rawItems =
    _normalizeItems(json['items'] ?? json['contracts'] ?? json['entries']);

    if (rawItems == null) {
      final contractTypes =
          json['contract_types'] ?? json['contractTypes'] ?? json['types'];
      rawItems = _normalizeItems(contractTypes);
    }

    if (rawItems == null) {
      final monthlyContracts = _normalizeItems(
        json['monthly_contract_summary'] ?? json['monthlyContractSummary'],
      );

      if (monthlyContracts != null) {
        rawItems = monthlyContracts.map((entry) {
          final map = _ensureMap(entry);
          if (map == null) return null;
          return <String, dynamic>{
            'title': map['contract_name'] ?? map['name'],
            'amount': map['salary'] ?? map['amount'],
            'total_units': map['units'] ?? map['total_units'],
            'unit_label': map['unit_label'] ?? 'Unit',
            'rate_per_unit': map['rate_per_unit'],
            'role': map['type'],
          };
        }).whereType<Map<String, dynamic>>();
      }
    }

    if (rawItems == null) {
      final combined = <dynamic>[];
      void append(dynamic source) {
        final normalized = _normalizeItems(source);
        if (normalized != null) combined.addAll(normalized);
      }

      append(json['default_contracts'] ?? json['defaultContracts']);
      append(json['global_contracts'] ?? json['globalContracts']);
      append(json['user_contracts'] ?? json['userContracts']);
      append(json['contract_types'] ?? json['contractTypes']);

      if (combined.isNotEmpty) rawItems = combined;
    }

    if (rawItems != null) {
      for (final entry in rawItems) {
        final map = _ensureMap(entry);
        if (map != null) items.add(ContractWorkItemData.fromJson(map));
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

class ContractDetail {
  const ContractDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.ratePerUnit,
    required this.unitLabel,
    this.totalUnits,
    this.salaryAmount,
    this.date,
  });

  factory ContractDetail.fromJson(Map<String, dynamic> json) {
    final resolvedType = _parseString(
      json,
        const ['type', 'category', 'unit_type', 'unitType', 'contract_type'],
    );
    return ContractDetail(
      id: _parseNullableInt(json, const [
        'id',
        'contract_type_id',
        'contractTypeId',
      ]),
      name: _parseString(
        json,
        const ['name', 'title', 'label'],
        fallback: 'Contract',
      ),
      type: resolvedType.isEmpty ? null : resolvedType,
      ratePerUnit: _parseNullableDouble(json, const [
        'rate_per_unit',
        'ratePerUnit',
        'rate',
        'price_per_unit',
        'pricePerUnit',
      ]),
      unitLabel: _parseString(
        json,
        const ['unit_label', 'unitLabel', 'unit_name', 'unitName', 'unit'],
        fallback: '',
      ),
      totalUnits: _parseNullableDouble(json, const [
        'total_units',
        'units_completed',
        'unitsCompleted',
        'units',
        'quantity',
        'qty',
      ]),
      salaryAmount: _parseNullableDouble(json, const [
        'salary_amount',
        'salaryAmount',
        'salary',
        'amount',
        'total_salary',
        'totalSalary',
        'payment',
      ]),
      date: _parseNullableDate(json, const [
        'date',
        'work_date',
        'workDate',
        'created_at',
        'createdAt',
        'entry_date',
        'entryDate',
      ]),
    );
  }

  final int? id;
  final String name;
  final String? type;
  final double? ratePerUnit;
  final String unitLabel;
  final double? totalUnits;
  final double? salaryAmount;
  final DateTime? date;

  String? get formattedDate {
    if (date == null) return null;
    final formatted = DateFormat('dd/MMM/yyyy').format(date!);
    return formatted.toLowerCase();
  }
}

List<ContractDetail> _parseContractDetails(Map<String, dynamic> json) {
  final source = json['contract_details'] ?? json['contractDetails'];
  final normalized = _normalizeContractDetailSource(source);
  if (normalized == null) {
    return const <ContractDetail>[];
  }

  final details = <ContractDetail>[];
  for (final entry in normalized) {
    final map = _ensureMap(entry);
    if (map != null) {
      details.add(ContractDetail.fromJson(map));
    }
  }
  return details;
}

List<ContractDetail> _parseMonthlyContractDetails(Map<String, dynamic> json) {
  final monthlySource = _normalizeContractDetailSource(
    json['monthly_contract_summary'] ?? json['monthlyContractSummary'],
  );

  if (monthlySource == null || monthlySource.isEmpty) {
    return const <ContractDetail>[];
  }

  final details = <ContractDetail>[];
  for (final entry in monthlySource) {
    final map = _ensureMap(entry);
    if (map == null) {
      continue;
    }

    details.add(
      ContractDetail(
        id: _parseNullableInt(map, const ['id', 'contract_type_id', 'contractTypeId']),
        name: _parseString(
          map,
          const ['contract_name', 'name', 'title'],
          fallback: 'Contract Work',
        ),
        type: _parseString(map, const ['type', 'contract_type', 'contractType']),
        ratePerUnit: _parseNullableDouble(
          map,
          const ['rate_per_unit', 'ratePerUnit', 'rate'],
        ),
        unitLabel: _parseString(
          map,
          const ['unit_label', 'unitLabel', 'unit'],
          fallback: 'Unit',
        ),
        totalUnits: _parseNullableDouble(
          map,
          const ['units', 'total_units', 'totalUnits'],
        ),
        salaryAmount: _parseNullableDouble(
          map,
          const ['salary', 'amount', 'total_salary', 'totalSalary'],
        ),
        date: null,
      ),
    );
  }
  return details;
}

Iterable<dynamic>? _normalizeContractDetailSource(dynamic source) {
  if (source == null) return null;
  if (source is List) return source;
  if (source is Set) return source;
  if (source is Iterable) return source;
  if (source is Map) return source.values;
  return null;
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
    this.unitLabel,
    this.ratePerUnit,
    this.unitCount,
    this.unitRole,
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

    final roleValue = _parseString(json, const [
      'role',
      'unit_role',
      'unitRole',
      'contract_role',
      'contractRole',
      'unit_name',
      'unitName',
      'role_name',
      'roleName',
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
      unitLabel: _parseString(json, const [
        'unit_label',
        'unitLabel',
        'unit',
        'unit_name',
        'unitName',
        'unit_label_display',
        'unitLabelDisplay',
      ]),
      ratePerUnit: _parseNullableDouble(json, const [
        'rate_per_unit',
        'ratePerUnit',
        'rate',
        'unit_rate',
        'unitRate',
        'price',
      ]),
      unitCount: _parseNullableDouble(json, const [
        'count',
        'quantity',
        'qty',
        'unit_count',
        'unitCount',
        'unit_quantity',
        'unitQuantity',
        'per_count',
        'perCount',
      ]),
      unitRole: roleValue.isNotEmpty ? roleValue : null,
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
  final String? unitLabel;
  final double? ratePerUnit;
  final double? unitCount;
  final String? unitRole;

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
  if (value is Map<String, dynamic>) return value;
  return null;
}

double _parseDouble(Map<String, dynamic> json, List<String> keys,
    [double fallback = 0]) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = _sanitizeNumberString(value);
      if (cleaned.isEmpty) continue;
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

int _parseInt(Map<String, dynamic> json, List<String> keys, [int fallback = 0]) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final cleaned = _sanitizeNumberString(value);
      if (cleaned.isEmpty) continue;
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed.round();
    }
  }
  return fallback;
}

int? _parseNullableInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final cleaned = _sanitizeNumberString(value);
      if (cleaned.isEmpty) continue;
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed.round();
    }
  }
  return null;
}

double? _parseNullableDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = _sanitizeNumberString(value);
      if (cleaned.isEmpty) continue;
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

DateTime? _parseNullableDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 0) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) return parsed;
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
    if (value == null) continue;
    if (value is int) return value;
    if (value is String) {
      var hex = value.trim();
      if (hex.isEmpty) continue;
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      } else if (hex.toLowerCase().startsWith('0x')) {
        hex = hex.substring(2);
      }
      if (hex.length == 6) hex = 'FF$hex';
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) return parsed;
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

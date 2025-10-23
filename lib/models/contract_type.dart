class ContractType {
  ContractType({
    required this.id,
    required this.name,
    required this.rate,
    required this.unitLabel,
    required this.isDefault,
    required this.isGlobal,
    this.updatedAt,
    Map<String, dynamic>? rawJson,
  }) : additionalData = Map<String, dynamic>.from(rawJson ?? const {});

  final String id;
  final String name;
  final double rate;
  final String unitLabel;
  final bool isDefault;
  final bool isGlobal;
  final DateTime? updatedAt;
  final Map<String, dynamic> additionalData;

  factory ContractType.fromJson(Map<String, dynamic> json) {
    final id = _parseId(json);
    final name = _parseName(json) ?? 'Unnamed Contract';
    final rate = _parseRate(json);
    final unitLabel = _parseUnitLabel(json) ?? 'per unit';
    final isDefault = _parseFlag(json, const ['is_default', 'isDefault', 'default']);
    final isGlobal = _parseFlag(json, const ['is_global', 'isGlobal', 'global']);
    final updatedAt = _parseUpdatedAt(json);

    return ContractType(
      id: id,
      name: name,
      rate: rate,
      unitLabel: unitLabel,
      isDefault: isDefault,
      isGlobal: isGlobal,
      updatedAt: updatedAt,
      rawJson: json,
    );
  }

  ContractType copyWith({
    String? id,
    String? name,
    double? rate,
    String? unitLabel,
    bool? isDefault,
    bool? isGlobal,
    DateTime? updatedAt,
  }) {
    return ContractType(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      unitLabel: unitLabel ?? this.unitLabel,
      isDefault: isDefault ?? this.isDefault,
      isGlobal: isGlobal ?? this.isGlobal,
      updatedAt: updatedAt ?? this.updatedAt,
      rawJson: additionalData,
    );
  }

  static String _parseId(Map<String, dynamic> json) {
    const possibleKeys = ['id', 'uuid', 'contract_type_id', 'contractTypeId'];
    for (final key in possibleKeys) {
      final value = json[key];
      if (value == null) continue;
      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty) {
        return stringValue;
      }
    }
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static String? _parseName(Map<String, dynamic> json) {
    const possibleKeys = ['name', 'contract_name', 'contractName', 'title'];
    for (final key in possibleKeys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static double _parseRate(Map<String, dynamic> json) {
    const possibleKeys = ['rate', 'rate_per_unit', 'ratePerUnit', 'unit_rate', 'unitRate'];

    for (final key in possibleKeys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final sanitized = value.replaceAll(',', '').trim();
        if (sanitized.isEmpty) continue;
        final parsed = double.tryParse(sanitized);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return 0;
  }

  static String? _parseUnitLabel(Map<String, dynamic> json) {
    const possibleKeys = [
      'unit_label',
      'unitLabel',
      'unit',
      'unit_name',
      'unitName',
      'label',
    ];

    for (final key in possibleKeys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static bool _parseFlag(Map<String, dynamic> json, List<String> keys) {
    bool? resolve(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized.isEmpty) return null;
        if (const ['true', '1', 'yes', 'y'].contains(normalized)) {
          return true;
        }
        if (const ['false', '0', 'no', 'n'].contains(normalized)) {
          return false;
        }
      }
      return null;
    }

    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final resolved = resolve(value);
      if (resolved != null) {
        return resolved;
      }
    }
    return false;
  }

  static DateTime? _parseUpdatedAt(Map<String, dynamic> json) {
    const possibleKeys = [
      'updated_at',
      'updatedAt',
      'last_updated',
      'lastUpdated',
      'modified_at',
      'modifiedAt',
    ];

    DateTime? parse(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
      }
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
      return null;
    }

    for (final key in possibleKeys) {
      final value = json[key];
      final parsed = parse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    final nested = json['timestamps'];
    if (nested is Map<String, dynamic>) {
      DateTime? best;
      for (final value in nested.values) {
        final parsed = parse(value);
        if (parsed == null) continue;
        if (best == null || parsed.isAfter(best)) {
          best = parsed;
        }
      }
      if (best != null) {
        return best;
      }
    }

    return null;
  }
}

class ContractTypeCollection {
  const ContractTypeCollection({
    required this.globalTypes,
    required this.userTypes,
  });

  final List<ContractType> globalTypes;
  final List<ContractType> userTypes;
}

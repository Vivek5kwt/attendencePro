class Work {
  Work({
    required this.id,
    required this.name,
    this.hourlyRate,
    this.isContract = false,
    this.additionalData = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final num? hourlyRate;
  final bool isContract;
  final Map<String, dynamic> additionalData;

  factory Work.fromJson(Map<String, dynamic> json) {
    final normalized = _flattenJson(json);
    return Work(
      id: _parseId(normalized),
      name: _parseName(normalized) ?? 'Unnamed Work',
      hourlyRate: _parseHourlyRate(normalized),
      isContract: _parseIsContract(normalized),
      additionalData: Map<String, dynamic>.from(normalized),
    );
  }

  Work copyWith({
    String? id,
    String? name,
    num? hourlyRate,
    bool? isContract,
    Map<String, dynamic>? additionalData,
  }) {
    return Work(
      id: id ?? this.id,
      name: name ?? this.name,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isContract: isContract ?? this.isContract,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  static Map<String, dynamic> _flattenJson(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        result.addAll(value);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  static String _parseId(Map<String, dynamic> json) {
    const possibleKeys = ['id', 'work_id', 'workId', 'uuid'];
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
    final possibleKeys = ['name', 'title'];
    for (final key in possibleKeys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static num? _parseHourlyRate(Map<String, dynamic> json) {
    final possibleKeys = ['hourly_rate', 'hourlyRate', 'rate'];
    for (final key in possibleKeys) {
      final value = json[key];
      if (value is num) {
        return value;
      }
      if (value is String) {
        final sanitized = value.replaceAll(',', '').trim();
        if (sanitized.isEmpty) continue;
        final parsed = num.tryParse(sanitized);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static bool _parseIsContract(Map<String, dynamic> json) {
    final possibleKeys = ['is_contract', 'isContract'];
    for (final key in possibleKeys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase();
        if (['true', '1', 'yes'].contains(normalized)) {
          return true;
        }
        if (['false', '0', 'no'].contains(normalized)) {
          return false;
        }
      }
    }
    return false;
  }
}

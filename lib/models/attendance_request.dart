class AttendanceRequest {
  const AttendanceRequest({
    required this.workId,
    required this.date,
    this.startTime,
    this.endTime,
    this.breakMinutes,
    this.isContractEntry,
    this.contractTypeId,
    this.units,
    this.ratePerUnit,
    this.bundles,
    this.isLeave = false,
  });

  final Object workId;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final int? breakMinutes;
  final bool? isContractEntry;
  final int? contractTypeId;
  final num? units;
  final num? ratePerUnit;
  final List<AttendanceContractBundle>? bundles;
  final bool isLeave;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'work_id': _normalizeWorkId(workId),
      'date': _formatDate(date),
      'is_leave': isLeave,
    };

    if (!isLeave) {
      final hasBundles = bundles != null && bundles!.isNotEmpty;
      final isBundleContractEntry = isContractEntry == true && hasBundles;

      if (!isBundleContractEntry) {
        if (startTime != null) {
          payload['start_time'] = startTime;
        }
        if (endTime != null) {
          payload['end_time'] = endTime;
        }
        if (breakMinutes != null) {
          payload['break_minutes'] = breakMinutes;
        }
      }

      if (isContractEntry != null) {
        payload['is_contract_entry'] = isContractEntry;
      }

      if (isContractEntry == true) {
        if (hasBundles) {
          payload['bundles'] =
              bundles!.map((bundle) => bundle.toJson()).toList(growable: false);
        } else {
          final normalizedContractTypeId = contractTypeId ?? 1;
          payload['contract_type_id'] = normalizedContractTypeId;
          if (units != null) {
            payload['units'] = units;
          }
          if (ratePerUnit != null) {
            payload['rate_per_unit'] = ratePerUnit;
          }
        }
      }
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

class AttendanceContractBundle {
  const AttendanceContractBundle({
    required this.contractTypeId,
    required this.count,
  });

  final int contractTypeId;
  final int count;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'contract_type_id': contractTypeId,
      'count': count,
    };
  }
}

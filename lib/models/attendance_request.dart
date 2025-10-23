class AttendanceRequest {
  const AttendanceRequest({
    required this.workId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.breakMinutes,
    required this.isContractEntry,
    this.contractTypeId,
    this.units,
    this.ratePerUnit,
  });

  final Object workId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int breakMinutes;
  final bool isContractEntry;
  final int? contractTypeId;
  final num? units;
  final num? ratePerUnit;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'work_id': _normalizeWorkId(workId),
      'date': _formatDate(date),
      'start_time': startTime,
      'end_time': endTime,
      'break_minutes': breakMinutes,
      'is_contract_entry': isContractEntry,
    };

    if (contractTypeId != null) {
      payload['contract_type_id'] = contractTypeId;
    }
    if (units != null) {
      payload['units'] = units;
    }
    if (ratePerUnit != null) {
      payload['rate_per_unit'] = ratePerUnit;
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

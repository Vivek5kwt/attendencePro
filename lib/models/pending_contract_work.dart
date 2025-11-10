class PendingContractWork {
  const PendingContractWork({
    required this.name,
    required this.role,
    required this.ratePerUnit,
    required this.unitLabel,
    required this.contractKind,
  });

  final String name;
  final String role;
  final double ratePerUnit;
  final String unitLabel;
  final String contractKind;

  PendingContractWork copyWith({
    String? name,
    String? role,
    double? ratePerUnit,
    String? unitLabel,
    String? contractKind,
  }) {
    return PendingContractWork(
      name: name ?? this.name,
      role: role ?? this.role,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      unitLabel: unitLabel ?? this.unitLabel,
      contractKind: contractKind ?? this.contractKind,
    );
  }

  Map<String, dynamic> toRequestPayload({required String workId}) {
    return <String, dynamic>{
      'work_id': workId,
      'name': name,
      'role': role,
      'contract_kind': contractKind,
      'rate_per_unit': ratePerUnit,
      'unit_label': unitLabel,
    };
  }
}

const List<String> _kDirectWorkIdKeys = <String>[
  'work_id',
  'workId',
  'work_uuid',
  'workUuid',
  'workID',
  'job_id',
  'jobId',
  'job_uuid',
  'jobUuid',
  'jobID',
  'assignment_work_id',
  'assignmentWorkId',
];

const List<String> _kNestedAssociationKeys = <String>[
  'work',
  'job',
  'work_details',
  'workDetails',
  'work_detail',
  'workDetail',
  'job_details',
  'jobDetails',
  'job_detail',
  'jobDetail',
  'pivot',
  'assignment',
  'assignments',
  'work_assignment',
  'workAssignment',
  'data',
];

const Set<String> _kTreatNestedIdKeys = <String>{
  'work',
  'job',
  'work_details',
  'workDetails',
  'work_detail',
  'workDetail',
  'job_details',
  'jobDetails',
  'job_detail',
  'jobDetail',
};

/// Returns every work identifier that can be resolved from [data].
///
/// The function inspects common key names (`work_id`, `job_id`, `pivot.work_id`,
/// nested `work` objects, etc.) and normalizes numeric identifiers to strings.
Set<String> extractWorkAssociationIds(Map<String, dynamic> data) {
  final ids = <String>{};
  _collectWorkAssociationIdsFromMap(
    data.cast<dynamic, dynamic>(),
    ids,
    treatIdAsWorkId: false,
  );
  return ids;
}

/// Returns `true` when [data] clearly belongs to the work represented by
/// [workId].
bool workDataMatchesId(Map<String, dynamic> data, String workId) {
  final normalizedWorkId = workId.trim();
  if (normalizedWorkId.isEmpty) {
    return false;
  }
  final ids = extractWorkAssociationIds(data);
  return ids.contains(normalizedWorkId);
}

void _collectWorkAssociationIds(
  Object? value,
  Set<String> target, {
  bool treatNestedIdAsWorkId = false,
}) {
  if (value == null) {
    return;
  }
  if (value is Map) {
    _collectWorkAssociationIdsFromMap(
      value.cast<dynamic, dynamic>(),
      target,
      treatIdAsWorkId: treatNestedIdAsWorkId,
    );
    return;
  }
  if (value is Iterable) {
    for (final element in value) {
      _collectWorkAssociationIds(
        element,
        target,
        treatNestedIdAsWorkId: treatNestedIdAsWorkId,
      );
    }
    return;
  }
  final normalized = _normalizeWorkIdValue(value);
  if (normalized != null) {
    target.add(normalized);
  }
}

void _collectWorkAssociationIdsFromMap(
  Map<dynamic, dynamic> map,
  Set<String> target, {
  required bool treatIdAsWorkId,
}) {
  for (final key in _kDirectWorkIdKeys) {
    if (map.containsKey(key)) {
      _collectWorkAssociationIds(map[key], target);
    }
  }

  if (treatIdAsWorkId) {
    if (map.containsKey('id')) {
      _collectWorkAssociationIds(map['id'], target);
    }
    if (map.containsKey('uuid')) {
      _collectWorkAssociationIds(map['uuid'], target);
    }
  }

  for (final key in _kNestedAssociationKeys) {
    if (!map.containsKey(key)) {
      continue;
    }
    final nested = map[key];
    final shouldTreatNestedIdAsWorkId = _kTreatNestedIdKeys.contains(key);
    _collectWorkAssociationIds(
      nested,
      target,
      treatNestedIdAsWorkId: shouldTreatNestedIdAsWorkId,
    );
  }
}

String? _normalizeWorkIdValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num) {
    return value.toInt().toString();
  }
  return null;
}

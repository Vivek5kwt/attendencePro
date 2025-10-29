String normalizeContractSubtype(String subtype) {
  final trimmed = subtype.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final normalized = trimmed.toLowerCase();
  const knownSubtypes = {'bundle', 'fixed'};
  if (knownSubtypes.contains(normalized)) {
    return normalized;
  }

  return trimmed;
}

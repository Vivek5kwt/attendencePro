String normalizeContractType(String type) {
  final trimmed = type.trim();
  if (trimmed.isEmpty) {
    return 'fixed';
  }

  switch (trimmed.toLowerCase()) {
    case 'bundle':
      return 'bundle';
    case 'fixed':
    default:
      return 'fixed';
  }
}

String normalizeContractRole(String role) {
  final trimmed = role.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final normalized = trimmed.toLowerCase();
  switch (normalized) {
    case 'bin':
      return 'Bin';
    case 'crate':
      return 'Crate';
    case 'bunches':
      return 'Bunches';
    default:
      return trimmed;
  }
}

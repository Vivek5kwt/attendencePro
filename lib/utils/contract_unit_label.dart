import '../core/localization/app_localizations.dart';

class _ContractUnitOverride {
  const _ContractUnitOverride({
    required this.label,
    required this.hintNoun,
  });

  final String label;
  final String hintNoun;
}

const Map<String, _ContractUnitOverride> _unitOverrides = <String, _ContractUnitOverride>{
  'orange': _ContractUnitOverride(label: 'per crate', hintNoun: 'Crate'),
  'radish': _ContractUnitOverride(label: 'per bin', hintNoun: 'Bin'),
  'ravanello': _ContractUnitOverride(label: 'per bunch', hintNoun: 'Bunches'),
};

_ContractUnitOverride? _matchUnitOverride(String contractName) {
  final normalizedName = contractName.toLowerCase();
  for (final entry in _unitOverrides.entries) {
    if (normalizedName.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}

String resolveContractUnitLabel({
  required AppLocalizations localizations,
  required String contractName,
  required String unitLabel,
}) {
  final override = _matchUnitOverride(contractName);
  if (override != null) {
    return override.label;
  }

  final trimmedLabel = unitLabel.trim();
  if (trimmedLabel.isEmpty) {
    return localizations.contractWorkUnitFallback;
  }

  if (trimmedLabel.toLowerCase() == 'per unit') {
    // Attempt to derive a more specific label from the contract name.
    final inferred = _deriveLabelFromName(contractName);
    if (inferred != null) {
      return inferred;
    }
  }

  return trimmedLabel;
}

String resolveContractUnitHint({
  required AppLocalizations localizations,
  required String contractName,
  required String unitLabel,
}) {
  final override = _matchUnitOverride(contractName);
  if (override != null) {
    return localizations.contractWorkQuantityHint(override.hintNoun);
  }

  final resolvedLabel = resolveContractUnitLabel(
    localizations: localizations,
    contractName: contractName,
    unitLabel: unitLabel,
  );
  final noun = _extractUnitNoun(resolvedLabel);

  if (noun != null && !_isGenericUnit(noun)) {
    final formatted = _formatUnitNoun(noun);
    return localizations.contractWorkQuantityHint(formatted);
  }

  return localizations.contractWorkUnitsHint;
}

String? _deriveLabelFromName(String contractName) {
  final override = _matchUnitOverride(contractName);
  if (override != null) {
    return override.label;
  }
  return null;
}

String? _extractUnitNoun(String label) {
  var text = label.trim();
  if (text.isEmpty) {
    return null;
  }

  final lower = text.toLowerCase();
  if (lower.startsWith('per ')) {
    text = text.substring(4).trim();
  } else if (lower.startsWith('each ')) {
    text = text.substring(5).trim();
  }

  text = text.replaceFirst(RegExp(r'^[0-9]+(?:[.,][0-9]+)?\s*'), '');
  text = text.trim();

  if (text.isEmpty) {
    return null;
  }
  return text;
}

bool _isGenericUnit(String noun) {
  final normalized = noun.toLowerCase();
  return normalized == 'unit' || normalized == 'units';
}

String _formatUnitNoun(String noun) {
  final parts = noun.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'Units';
  }
  return parts
      .map((word) => word.length == 1
          ? word.toUpperCase()
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

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
  'ravanello':
      _ContractUnitOverride(label: 'Per 100 Bunches', hintNoun: 'Bunches'),
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
  final trimmedLabel = unitLabel.trim();
  if (trimmedLabel.isEmpty) {
    final override = _matchUnitOverride(contractName);
    if (override != null) {
      return override.label;
    }
    return localizations.contractWorkUnitFallback;
  }

  if (trimmedLabel.toLowerCase() == 'per unit') {
    // Attempt to derive a more specific label from the contract name.
    final inferred = _deriveLabelFromName(contractName);
    if (inferred != null) {
      return inferred;
    }
  }

  // Only apply overrides when the unit label is missing or generic so we don't
  // replace explicitly selected unit labels (e.g., crate instead of bunches).
  final override = _matchUnitOverride(contractName);
  if (override != null &&
      (trimmedLabel.isEmpty || trimmedLabel.toLowerCase() == 'per unit')) {
    return override.label;
  }

  return trimmedLabel;
}

String contractUnitQuantityLabel({
  required AppLocalizations localizations,
  required String contractName,
  required String unitLabel,
  num? completedUnits,
  num? totalUnits,
}) {
  final noun = _resolveContractUnitNoun(
    localizations: localizations,
    contractName: contractName,
    unitLabel: unitLabel,
  );

  if (completedUnits != null && totalUnits != null && totalUnits > 0) {
    if (completedUnits == totalUnits) {
      return contractUnitCountLabel(
        localizations: localizations,
        contractName: contractName,
        unitLabel: unitLabel,
        quantity: completedUnits,
      );
    }
    final plural = _pluralizeUnitWord(noun, totalUnits);
    return '$completedUnits / $totalUnits $plural';
  }

  if (completedUnits != null) {
    return contractUnitCountLabel(
      localizations: localizations,
      contractName: contractName,
      unitLabel: unitLabel,
      quantity: completedUnits,
    );
  }

  if (totalUnits != null && totalUnits > 0) {
    final plural = _pluralizeUnitWord(noun, totalUnits);
    return '$totalUnits $plural';
  }

  return localizations.notAvailableLabel;
}

String contractUnitCountLabel({
  required AppLocalizations localizations,
  required String contractName,
  required String unitLabel,
  required num quantity,
}) {
  final noun = _resolveContractUnitNoun(
    localizations: localizations,
    contractName: contractName,
    unitLabel: unitLabel,
  );
  final plural = _pluralizeUnitWord(noun, quantity);
  final displayQuantity = quantity % 1 == 0
      ? quantity.toInt().toString()
      : quantity.toString();
  return '$displayQuantity $plural';
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

String _resolveContractUnitNoun({
  required AppLocalizations localizations,
  required String contractName,
  required String unitLabel,
}) {
  final resolvedLabel = resolveContractUnitLabel(
    localizations: localizations,
    contractName: contractName,
    unitLabel: unitLabel,
  );
  final noun = _extractUnitNoun(resolvedLabel);
  if (noun == null || noun.trim().isEmpty || _isGenericUnit(noun)) {
    return _formatUnitNoun(localizations.contractWorkUnitsLabel);
  }
  return _formatUnitNoun(noun);
}

String _pluralizeUnitWord(String noun, num quantity) {
  if (quantity == 1) {
    return noun;
  }
  final lower = noun.toLowerCase();
  if (lower.endsWith('y') && noun.length > 1 && !_isVowel(noun.codeUnitAt(noun.length - 2))) {
    return '${noun.substring(0, noun.length - 1)}ies';
  }
  if (lower.endsWith('s') ||
      lower.endsWith('x') ||
      lower.endsWith('z') ||
      lower.endsWith('ch') ||
      lower.endsWith('sh')) {
    return '${noun}es';
  }
  if (lower.endsWith('o')) {
    return '${noun}es';
  }
  return '${noun}s';
}

bool _isVowel(int codeUnit) {
  switch (codeUnit) {
    case 65: // A
    case 69: // E
    case 73: // I
    case 79: // O
    case 85: // U
    case 97: // a
    case 101: // e
    case 105: // i
    case 111: // o
    case 117: // u
      return true;
  }
  return false;
}

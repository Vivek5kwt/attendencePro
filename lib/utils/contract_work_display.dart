import '../core/localization/app_localizations.dart';

String _resolveCurrencyPrefix(String? currencySymbol) {
  final trimmed = currencySymbol?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '€';
  }
  return trimmed;
}

num? _tryParseNumeric(String? value) {
  if (value == null) {
    return null;
  }
  final sanitized = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (sanitized.isEmpty) {
    return null;
  }
  final normalized = sanitized.replaceAll(',', '');
  return num.tryParse(normalized);
}

String _sanitizeUnitLabel(AppLocalizations localizations, String text,
    {String? fallback}) {
  final cleaned = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  if (cleaned.isEmpty || cleaned.toLowerCase() == 'per') {
    return fallback ?? localizations.contractWorkUnitFallback;
  }

  return cleaned;
}

String _formatRoleLabel(String role) {
  final normalizedRole = role.trim();
  if (normalizedRole.isEmpty) {
    return normalizedRole;
  }

  return normalizedRole
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) =>
          '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

String formatContractRateValue(num rate) {
  final doubleValue = rate.toDouble();
  final isWholeNumber = doubleValue % 1 == 0;
  if (isWholeNumber) {
    return doubleValue.toStringAsFixed(1);
  }
  final formatted = doubleValue.toStringAsFixed(2);
  final trimmed = formatted.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.replaceFirst(RegExp(r'\.$'), '');
}

String formatContractUnitLabel(
  AppLocalizations localizations, {
  num? count,
  String? role,
  String? fallbackUnitLabel,
}) {
  final normalizedFallback = fallbackUnitLabel?.trim();
  final fallbackLower = normalizedFallback?.toLowerCase();
  final normalizedRole = role?.trim();

  if (count != null && normalizedRole != null && normalizedRole.isNotEmpty) {
    final isWholeNumber = count.roundToDouble() == count;
    final countText = isWholeNumber ? count.toInt().toString() : count.toString();
    final label = 'Per $countText ${_formatRoleLabel(normalizedRole)}';
    return _sanitizeUnitLabel(localizations, label);
  }

  final hasSpecificFallback = normalizedFallback != null &&
      normalizedFallback.isNotEmpty &&
      fallbackLower != 'per unit';

  if (hasSpecificFallback) {
    return _sanitizeUnitLabel(localizations, normalizedFallback);
  }

  if (normalizedRole != null && normalizedRole.isNotEmpty) {
    final lowerRole = normalizedRole.toLowerCase();
    if (lowerRole == 'bunches') {
      return localizations.contractWorkUnitPerHundredBunches;
    }

    return _sanitizeUnitLabel(
      localizations,
      'Per ${_formatRoleLabel(normalizedRole)}',
    );
  }

  if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
    return _sanitizeUnitLabel(localizations, normalizedFallback);
  }

  return _sanitizeUnitLabel(
    localizations,
    localizations.contractWorkUnitFallback,
  );
}

String buildContractRateSubtitle(
  AppLocalizations localizations, {
  num? rate,
  String? rawPrice,
  num? count,
  String? role,
  String? fallbackUnitLabel,
  String? currencySymbol,
}) {
  final unitText = formatContractUnitLabel(
    localizations,
    count: count,
    role: role,
    fallbackUnitLabel: fallbackUnitLabel,
  );

  final resolvedPrefix = _resolveCurrencyPrefix(currencySymbol);

  final parsedRate = rate ?? _tryParseNumeric(rawPrice);
  if (parsedRate != null) {
    final rateText = formatContractRateValue(parsedRate);
    final label = '$resolvedPrefix$rateText / $unitText';
    return _sanitizeUnitLabel(localizations, label,
        fallback: '$resolvedPrefix$rateText');
  }

  final rawPriceText = rawPrice?.trim();
  if (rawPriceText != null && rawPriceText.isNotEmpty) {
    final normalizedUnit = unitText.trim();
    final containsUnit = normalizedUnit.isNotEmpty &&
        rawPriceText.toLowerCase().contains(normalizedUnit.toLowerCase());
    if (containsUnit) {
      return _sanitizeUnitLabel(localizations, rawPriceText,
          fallback: normalizedUnit.isNotEmpty ? normalizedUnit : null);
    }
    return normalizedUnit.isNotEmpty
        ? _sanitizeUnitLabel(
            localizations,
            '$rawPriceText $normalizedUnit'.trim(),
            fallback: rawPriceText,
          )
        : _sanitizeUnitLabel(
            localizations,
            rawPriceText,
          );
  }

  return unitText;
}

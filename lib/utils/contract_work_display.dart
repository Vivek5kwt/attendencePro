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
    return 'per $countText ${normalizedRole.toLowerCase()}';
  }

  final hasSpecificFallback = normalizedFallback != null &&
      normalizedFallback.isNotEmpty &&
      fallbackLower != 'per unit';

  if (hasSpecificFallback) {
    return normalizedFallback;
  }

  if (normalizedRole != null && normalizedRole.isNotEmpty) {
    return 'per ${normalizedRole.toLowerCase()}';
  }

  if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
    return normalizedFallback;
  }

  return localizations.contractWorkUnitFallback;
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
    return '$resolvedPrefix$rateText / $unitText';
  }

  final rawPriceText = rawPrice?.trim();
  if (rawPriceText != null && rawPriceText.isNotEmpty) {
    final normalizedUnit = unitText.trim();
    final containsUnit = normalizedUnit.isNotEmpty &&
        rawPriceText.toLowerCase().contains(normalizedUnit.toLowerCase());
    if (containsUnit) {
      return rawPriceText;
    }
    return normalizedUnit.isNotEmpty
        ? '$rawPriceText $normalizedUnit'.trim()
        : rawPriceText;
  }

  return unitText;
}

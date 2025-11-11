import '../core/localization/app_localizations.dart';

String resolveContractUnitLabel({
  required AppLocalizations localizations,
  required String contractName,
  required String unitLabel,
}) {
  final normalizedName = contractName.toLowerCase();
  if (normalizedName.contains('ravanello')) {
    return localizations.contractWorkUnitPerHundredBunches;
  }

  final trimmedLabel = unitLabel.trim();
  if (trimmedLabel.isEmpty) {
    return localizations.contractWorkUnitFallback;
  }

  return trimmedLabel;
}

import 'package:attendencePro/core/localization/app_localizations.dart';
import 'package:attendencePro/utils/contract_work_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations localizations;

  setUp(() {
    localizations = AppLocalizations(const Locale('en'));
  });

  group('formatContractUnitLabel', () {
    test('removes bunches from count-based labels', () {
      final label = formatContractUnitLabel(
        localizations,
        count: 100,
        role: 'Bunches',
      );

      expect(label, equals('per 100'));
    });

    test('falls back when only bunches role is provided', () {
      final label = formatContractUnitLabel(
        localizations,
        role: 'Bunches',
      );

      expect(label, equals(localizations.contractWorkUnitFallback));
    });

    test('removes bunches from fallback labels', () {
      final label = formatContractUnitLabel(
        localizations,
        fallbackUnitLabel: 'Price Per 100 Bunches',
      );

      expect(label, equals('Price Per 100'));
    });
  });

  group('buildContractRateSubtitle', () {
    test('omits bunches in formatted subtitle when rate is provided', () {
      final subtitle = buildContractRateSubtitle(
        localizations,
        rate: 250,
        count: 100,
        role: 'Bunches',
        currencySymbol: '₹',
      );

      expect(subtitle, equals('₹250.0 / per 100'));
    });

    test('sanitizes raw price text containing bunches', () {
      final subtitle = buildContractRateSubtitle(
        localizations,
        rawPrice: '₹450 per 100 Bunches',
        count: 100,
        role: 'Bunches',
      );

      expect(subtitle, equals('₹450 per 100'));
    });
  });
}

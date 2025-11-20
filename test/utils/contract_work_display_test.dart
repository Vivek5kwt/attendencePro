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
    test('keeps bunches in count-based labels', () {
      final label = formatContractUnitLabel(
        localizations,
        count: 100,
        role: 'Bunches',
      );

      expect(label, equals('Per 100 Bunches'));
    });

    test('shows bunches unit when only role is provided', () {
      final label = formatContractUnitLabel(
        localizations,
        role: 'Bunches',
      );

      expect(label, equals('per 100 bunches'));
    });

    test('keeps bunches in fallback labels', () {
      final label = formatContractUnitLabel(
        localizations,
        fallbackUnitLabel: 'Price Per 100 Bunches',
      );

      expect(label, equals('Price Per 100 Bunches'));
    });
  });

  group('buildContractRateSubtitle', () {
    test('keeps bunches in formatted subtitle when rate is provided', () {
      final subtitle = buildContractRateSubtitle(
        localizations,
        rate: 250,
        count: 100,
        role: 'Bunches',
        currencySymbol: '₹',
      );

      expect(subtitle, equals('₹250.0 / Per 100 Bunches'));
    });

    test('keeps bunches in raw price text containing bunches', () {
      final subtitle = buildContractRateSubtitle(
        localizations,
        rawPrice: '₹450 per 100 Bunches',
        count: 100,
        role: 'Bunches',
      );

      expect(subtitle, equals('₹450 per 100 Bunches'));
    });
  });
}

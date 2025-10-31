import 'package:flutter_test/flutter_test.dart';

import 'package:attendancepro/utils/contract_type_normalizer.dart';

void main() {
  group('normalizeContractType', () {
    test('returns bundle for mixed case bundle input', () {
      expect(normalizeContractType('Bundle'), equals('bundle'));
    });

    test('defaults to fixed when input is blank', () {
      expect(normalizeContractType('   '), equals('fixed'));
    });

    test('returns fixed for any non bundle value', () {
      expect(normalizeContractType('custom'), equals('fixed'));
    });
  });

  group('normalizeContractRole', () {
    test('capitalizes known roles', () {
      expect(normalizeContractRole('bin'), equals('Bin'));
      expect(normalizeContractRole('Crate'), equals('Crate'));
      expect(normalizeContractRole(' BUNCHES '), equals('Bunches'));
    });

    test('trims but preserves unknown casing', () {
      expect(normalizeContractRole('  Custom Role  '), equals('Custom Role'));
    });

    test('returns empty string for blank input', () {
      expect(normalizeContractRole('   '), isEmpty);
    });
  });
}

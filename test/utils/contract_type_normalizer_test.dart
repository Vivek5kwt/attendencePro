import 'package:flutter_test/flutter_test.dart';

import 'package:attendancepro/utils/contract_type_normalizer.dart';

void main() {
  group('normalizeContractSubtype', () {
    test('returns lowercase for default bundle subtype', () {
      expect(normalizeContractSubtype('Bundle'), equals('bundle'));
    });

    test('returns lowercase for default fixed subtype', () {
      expect(normalizeContractSubtype('  Fixed  '), equals('fixed'));
    });

    test('trims but preserves casing for custom subtype', () {
      expect(normalizeContractSubtype('  Custom Type  '), equals('Custom Type'));
    });

    test('returns empty string for blank input', () {
      expect(normalizeContractSubtype('   '), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:attendancepro/utils/work_contract_filter.dart';

void main() {
  group('extractWorkAssociationIds', () {
    test('returns direct work_id values', () {
      final ids = extractWorkAssociationIds({'work_id': 'abc'});
      expect(ids, contains('abc'));
    });

    test('normalizes numeric identifiers', () {
      final ids = extractWorkAssociationIds({'workId': 42});
      expect(ids, contains('42'));
    });

    test('inspects nested work objects', () {
      final ids = extractWorkAssociationIds({
        'work': {
          'id': 'work-9',
        },
      });
      expect(ids, contains('work-9'));
    });

    test('inspects pivot objects', () {
      final ids = extractWorkAssociationIds({
        'pivot': {'work_id': 77},
      });
      expect(ids, contains('77'));
    });

    test('handles job detail fallbacks', () {
      final ids = extractWorkAssociationIds({
        'job_details': {'uuid': 'job-12'},
      });
      expect(ids, contains('job-12'));
    });

    test('returns empty set when nothing matches', () {
      final ids = extractWorkAssociationIds({'name': 'Tomato'});
      expect(ids, isEmpty);
    });
  });

  group('workDataMatchesId', () {
    test('returns true when work id matches', () {
      final matches = workDataMatchesId({'work_id': 'alpha'}, 'alpha');
      expect(matches, isTrue);
    });

    test('returns false when id does not match', () {
      final matches = workDataMatchesId({'work_id': 'alpha'}, 'beta');
      expect(matches, isFalse);
    });
  });
}

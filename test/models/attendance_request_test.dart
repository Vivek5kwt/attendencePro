import 'package:attendancepro/models/attendance_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceRequest', () {
    test('serializes hourly attendance with numeric work id', () {
      final request = AttendanceRequest(
        workId: '42',
        date: DateTime(2025, 10, 23, 10, 30),
        startTime: '09:00',
        endTime: '17:00',
        breakMinutes: 45,
        isContractEntry: false,
      );

      final json = request.toJson();

      expect(json['work_id'], 42);
      expect(json['date'], '2025-10-23');
      expect(json['is_leave'], isFalse);
      expect(json['start_time'], '09:00');
      expect(json['end_time'], '17:00');
      expect(json['break_minutes'], 45);
      expect(json['is_contract_entry'], isFalse);
      expect(json.containsKey('contract_type_id'), isFalse);
      expect(json.containsKey('units'), isFalse);
      expect(json.containsKey('rate_per_unit'), isFalse);
    });

    test('serializes contract attendance with optional values', () {
      final request = AttendanceRequest(
        workId: 7,
        date: DateTime(2024, 6, 1),
        startTime: '08:00',
        endTime: '12:00',
        breakMinutes: 15,
        isContractEntry: true,
        contractTypeId: 3,
        units: 120,
        ratePerUnit: 2.5,
      );

      final json = request.toJson();

      expect(json['work_id'], 7);
      expect(json['date'], '2024-06-01');
      expect(json['is_leave'], isFalse);
      expect(json['start_time'], '08:00');
      expect(json['end_time'], '12:00');
      expect(json['break_minutes'], 15);
      expect(json['is_contract_entry'], isTrue);
      expect(json['contract_type_id'], 3);
      expect(json['units'], 120);
      expect(json['rate_per_unit'], 2.5);
    });

    test('defaults contract type id to 1 for contract entries when missing', () {
      final request = AttendanceRequest(
        workId: 9,
        date: DateTime(2025, 10, 27),
        startTime: '10:25',
        endTime: '14:35',
        breakMinutes: 10,
        isContractEntry: true,
        units: 10,
        ratePerUnit: 5,
      );

      final json = request.toJson();

      expect(json['contract_type_id'], 1);
      expect(json['is_leave'], isFalse);
    });

    test('serializes leave attendance with minimal payload', () {
      final request = AttendanceRequest(
        workId: 3,
        date: DateTime(2025, 10, 26),
        isLeave: true,
      );

      final json = request.toJson();

      expect(json['work_id'], 3);
      expect(json['date'], '2025-10-26');
      expect(json['is_leave'], isTrue);
      expect(json.containsKey('start_time'), isFalse);
      expect(json.containsKey('end_time'), isFalse);
      expect(json.containsKey('break_minutes'), isFalse);
      expect(json.containsKey('is_contract_entry'), isFalse);
      expect(json.containsKey('contract_type_id'), isFalse);
      expect(json.containsKey('units'), isFalse);
      expect(json.containsKey('rate_per_unit'), isFalse);
    });
  });
}

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/attendance_request.dart';
import 'auth_api.dart' show ApiException;
import 'logging_client.dart';

class AttendanceApi {
  AttendanceApi({
    this.baseUrl = 'https://attendancepro.shauryacoder.com',
    http.Client? httpClient,
  }) : _client = LoggingClient(httpClient);

  final String baseUrl;
  final http.Client _client;

  Future<List<DateTime>> fetchMissedAttendanceDates({
    required String workId,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/attendance/missed').replace(
      queryParameters: <String, String>{
        'work_id': workId,
      },
    );
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.get(uri, headers: headers);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseMissedAttendanceDates(decoded);
      }

      throw ApiException(_extractErrorMessage(decoded, response.statusCode));
    } on SocketException {
      throw ApiException(
        'Unable to reach the server. Please check your connection.',
      );
    } on HttpException {
      throw ApiException('A network error occurred while contacting the server.');
    } on FormatException {
      throw ApiException('Received an invalid response from the server.');
    }
  }

  Future<Map<String, dynamic>?> previewAttendance({
    required AttendanceRequest request,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/attendance/preview');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode(request.toJson());

    try {
      final response = await _client.post(uri, headers: headers, body: body);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      throw ApiException(_extractErrorMessage(decoded, response.statusCode));
    } on SocketException {
      throw ApiException('Unable to reach the server. Please check your connection.');
    } on HttpException {
      throw ApiException('A network error occurred while contacting the server.');
    } on FormatException {
      throw ApiException('Received an invalid response from the server.');
    }
  }

  Future<Map<String, dynamic>?> submitAttendance({
    required AttendanceRequest request,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/attendance');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode(request.toJson());

    try {
      final response = await _client.post(uri, headers: headers, body: body);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      throw ApiException(_extractErrorMessage(decoded, response.statusCode));
    } on SocketException {
      throw ApiException('Unable to reach the server. Please check your connection.');
    } on HttpException {
      throw ApiException('A network error occurred while contacting the server.');
    } on FormatException {
      throw ApiException('Received an invalid response from the server.');
    }
  }

  Map<String, dynamic>? _decodeBody(String body) {
    if (body.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(Map<String, dynamic>? decoded, int statusCode) {
    if (decoded == null) {
      return 'Request failed with status: $statusCode';
    }

    const keys = ['message', 'error', 'detail', 'status'];
    for (final key in keys) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Request failed with status: $statusCode';
  }

  List<DateTime> _parseMissedAttendanceDates(Map<String, dynamic>? decoded) {
    if (decoded == null) {
      return const <DateTime>[];
    }

    final items = _findDateList(decoded);
    if (items == null) {
      return const <DateTime>[];
    }

    final dates = SplayTreeSet<DateTime>();
    for (final item in items) {
      final date = _parseDateItem(item);
      if (date != null) {
        dates.add(date);
      }
    }

    return dates.toList(growable: false);
  }

  List<dynamic>? _findDateList(dynamic data) {
    if (data is List) {
      final hasDateLikeValue = data.any((element) => _parseDateItem(element) != null);
      if (hasDateLikeValue) {
        return data;
      }
      return null;
    }

    if (data is Map<String, dynamic>) {
      const prioritizedKeys = <String>[
        'dates',
        'missed_dates',
        'missedDates',
        'pending_dates',
        'pendingDates',
        'items',
        'data',
      ];

      for (final key in prioritizedKeys) {
        if (data.containsKey(key)) {
          final nested = _findDateList(data[key]);
          if (nested != null) {
            return nested;
          }
        }
      }

      for (final value in data.values) {
        final nested = _findDateList(value);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  DateTime? _parseDateItem(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return _normalizeDate(value);
    }

    if (value is num) {
      return _parseDateItem(value.toString());
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final directParse = DateTime.tryParse(trimmed);
      if (directParse != null) {
        return _normalizeDate(directParse.toLocal());
      }
      final match = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(trimmed);
      if (match != null) {
        final matched = match.group(0);
        if (matched != null) {
          final parsed = DateTime.tryParse(matched);
          if (parsed != null) {
            return _normalizeDate(parsed.toLocal());
          }
        }
      }
      return null;
    }

    if (value is Map<String, dynamic>) {
      const candidateKeys = <String>[
        'date',
        'missed_date',
        'missedDate',
        'attendance_date',
        'attendanceDate',
        'entry_date',
        'entryDate',
        'day',
      ];
      for (final key in candidateKeys) {
        final candidate = value[key];
        final parsed = _parseDateItem(candidate);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

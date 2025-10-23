import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart' show ApiException;
import 'logging_client.dart';

class AttendanceApi {
  AttendanceApi({
    this.baseUrl = 'https://attendancepro.shauryacoder.com',
    http.Client? httpClient,
  }) : _client = LoggingClient(httpClient);

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>?> submitAttendance({
    required dynamic workId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int breakMinutes,
    required bool isContractEntry,
    int? contractTypeId,
    num? units,
    num? ratePerUnit,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/attendance');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final bodyMap = <String, dynamic>{
      'work_id': workId,
      'date': date.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
      'break_minutes': breakMinutes,
      'is_contract_entry': isContractEntry,
      'contract_type_id': contractTypeId,
      'units': units,
      'rate_per_unit': ratePerUnit,
    }..removeWhere((_, value) => value == null);

    final body = jsonEncode(bodyMap);

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
}

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/dashboard_summary.dart';
import 'auth_api.dart' show ApiException;
import 'logging_client.dart';

class DashboardApi {
  DashboardApi({
    this.baseUrl = 'https://attendancepro.shauryacoder.com',
    http.Client? httpClient,
  }) : _client = LoggingClient(httpClient);

  final String baseUrl;
  final http.Client _client;

  Future<DashboardSummary> fetchSummary({
    required String workId,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/dashboard').replace(
      queryParameters: {
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
        return DashboardSummary.fromJson(decoded ?? <String, dynamic>{});
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

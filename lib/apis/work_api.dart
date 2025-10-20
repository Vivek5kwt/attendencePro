import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart' show ApiException;
import 'logging_client.dart';

class WorkApi {
  WorkApi({
    this.baseUrl = 'https://attendancepro.shauryacoder.com',
    http.Client? httpClient,
  }) : _client = LoggingClient(httpClient);

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> createWork({
    required String name,
    required num hourlyRate,
    required bool isContract,
  }) async {
    final uri = Uri.parse('$baseUrl/api/works');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'name': name,
      'hourly_rate': hourlyRate,
      'is_contract': isContract,
    });

    try {
      final response = await _client.post(uri, headers: headers, body: body);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded ?? <String, dynamic>{};
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
    if (body.isEmpty) return null;
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

    final possibleKeys = ['message', 'error', 'detail', 'status'];
    for (final key in possibleKeys) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final errors = decoded['errors'];
    if (errors is Map) {
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
        } else if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    return decoded.toString();
  }
}

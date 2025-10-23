import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/policy_content.dart';
import 'auth_api.dart' show ApiException;
import 'logging_client.dart';

class ContentApi {
  ContentApi({
    this.baseUrl = 'https://attendancepro.shauryacoder.com',
    http.Client? httpClient,
  }) : _client = LoggingClient(httpClient);

  final String baseUrl;
  final http.Client _client;

  Future<PolicyContent> fetchTerms() => _fetchPolicy('/api/terms');

  Future<PolicyContent> fetchPrivacy() => _fetchPolicy('/api/privacy');

  Future<PolicyContent> _fetchPolicy(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Accept': 'application/json',
    };

    try {
      final response = await _client.get(uri, headers: headers);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded?['data'];
        if (data is Map<String, dynamic>) {
          return PolicyContent.fromJson(data);
        }
        throw ApiException('Response missing policy content.');
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

    return 'Request failed with status: $statusCode';
  }
}

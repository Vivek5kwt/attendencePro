import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/work.dart';
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
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/works');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
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

  Future<Map<String, dynamic>> updateWork({
    required String id,
    required String name,
    required num hourlyRate,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/works/$id');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'name': name,
      'hourly_rate': hourlyRate,
    });

    try {
      final response = await _client.put(uri, headers: headers, body: body);
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

  Future<List<Work>> fetchWorks({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/works');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.get(uri, headers: headers);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final workItems = _extractWorkItems(decoded);
        return workItems.map(Work.fromJson).toList();
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

  Future<Map<String, dynamic>?> deleteWork({
    required String id,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/works/$id');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.delete(uri, headers: headers);
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

  List<Map<String, dynamic>> _extractWorkItems(Map<String, dynamic>? decoded) {
    if (decoded == null) {
      return const [];
    }

    final queue = Queue<dynamic>()..add(decoded);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      if (current is List) {
        final maps = <Map<String, dynamic>>[];
        for (final element in current) {
          if (element is Map) {
            maps.add(
              element.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            );
          }
        }
        if (maps.isNotEmpty) {
          return maps;
        }
      } else if (current is Map<String, dynamic>) {
        queue.addAll(current.values);
      } else if (current is Map) {
        queue.addAll((current as Map).values);
      }
    }

    return const [];
  }
}

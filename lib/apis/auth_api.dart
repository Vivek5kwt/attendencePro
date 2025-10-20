import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'logging_client.dart';

/// Exception thrown when an API request fails.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

/// Simple API client for authentication endpoints.
class AuthApi {
  /// Base URL of the backend. Adjust if needed.
  final String baseUrl;

  /// HTTP client used for requests (helpful for testing/mockability).
  final http.Client _httpClient;

  AuthApi({
    this.baseUrl = 'https://attendancepro.shauryacoder.com',
    http.Client? httpClient,
  }) : _httpClient = LoggingClient(httpClient);

  /// Login using the API: POST /api/auth/login
  /// Expects a JSON body: {"login": "string", "password": "string"}
  ///
  /// On success returns the decoded JSON response as a Map.
  /// On failure throws an [ApiException] with a readable message.
  Future<Map<String, dynamic>> login(String login, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    final body = jsonEncode({'login': login, 'password': password});

    return _sendPost(uri, headers: headers, body: body);
  }

  /// Register a new user using the API: POST /api/auth/register
  /// Body: {
  ///   "name": "string",
  ///   "email": "string",
  ///   "username": "string",
  ///   "password": "string",
  ///   "password_confirmation": "string"
  /// }
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String username,
    required String password,
    required String confirm,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    final body = jsonEncode({
      'name': name,
      'email': email,
      'username': username,
      'password': password,
      'password_confirmation': confirm,
    });

    return _sendPost(uri, headers: headers, body: body);
  }

  /// Logout the currently authenticated user: POST /api/auth/logout
  Future<Map<String, dynamic>> logout(String token) async {
    final uri = Uri.parse('$baseUrl/api/auth/logout');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    return _sendPost(uri, headers: headers, body: jsonEncode({}));
  }

  /// Trigger forgot password OTP email: POST /api/auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/api/auth/forgot-password');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({'email': email});

    return _sendPost(uri, headers: headers, body: body);
  }

  /// Verify the OTP sent to the user's email: POST /api/auth/verify-otp
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required int otp,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/verify-otp');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'otp': otp,
    });

    return _sendPost(uri, headers: headers, body: body);
  }

  Future<Map<String, dynamic>> _sendPost(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    try {
      final response = await _httpClient.post(uri, headers: headers, body: body);
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

    // Handle nested error maps like {"errors": {"email": ["The email has already been taken."]}}
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

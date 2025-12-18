import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'logging_client.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class AuthApi {
  final String baseUrl;

  final http.Client _httpClient;

  AuthApi({
    this.baseUrl = 'https://attendencepro.com',
    http.Client? httpClient,
  }) : _httpClient = LoggingClient(httpClient);


  Future<Map<String, dynamic>> login(
    String login,
    String password, {
    String? countryCode,
    String? fcmToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    final payload = <String, dynamic>{
      'login': login,
      'password': password,
    };
    if (countryCode != null && countryCode.trim().isNotEmpty) {
      payload['country_code'] = countryCode.trim();
    }
    if (fcmToken != null && fcmToken.trim().isNotEmpty) {
      payload['fcm_token'] = fcmToken.trim();
    }
    final body = jsonEncode(payload);

    return _sendPost(uri, headers: headers, body: body);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirm,
    required String phone,
    required String countryCode,
    required String language,
    String? fcmToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': confirm,
      'phone': phone,
      'country_code': countryCode,
      'language': language,
      if (fcmToken != null && fcmToken.trim().isNotEmpty) 'fcm_token': fcmToken.trim(),
    });
    print('djsjd $body');
    return _sendPost(uri, headers: headers, body: body);
  }

  Future<Map<String, dynamic>> logout(String token) async {
    final uri = Uri.parse('$baseUrl/api/auth/logout');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    return _sendPost(uri, headers: headers, body: jsonEncode({}));
  }

  Future<Map<String, dynamic>?> deleteAccount(String token) async {
    final uri = Uri.parse('$baseUrl/api/account/delete');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _httpClient.delete(uri, headers: headers);
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

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/api/auth/forgot-password');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({'email': email});

    return _sendPost(uri, headers: headers, body: body);
  }

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

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String verifyToken,
    required String password,
    required String confirm,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/reset-password');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'verify_token': verifyToken,
      'password': password,
      'password_confirmation': confirm,
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

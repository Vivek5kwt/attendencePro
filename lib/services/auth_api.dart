import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple API client for authentication endpoints.
class AuthApi {
  /// Base URL of the backend. Adjust if needed.
  final String baseUrl;

  AuthApi({this.baseUrl = 'http://127.0.0.1:8000'});

  /// Login using the API: POST /api/auth/login
  /// Expects a JSON body: {"login": "string", "password": "string"}
  ///
  /// On success returns the decoded JSON response as a Map.
  /// On failure throws an Exception with a readable message.
  Future<Map<String, dynamic>> login(String login, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'login': login, 'password': password});

    final response = await http.post(uri, headers: headers, body: body);

    // Try to decode the response body (if any)
    Map<String, dynamic>? decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      }
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded ?? <String, dynamic>{};
    } else {
      // Try to extract a useful message
      final message = decoded != null
          ? (decoded['message'] ??
          decoded['error'] ??
          decoded['detail'] ??
          decoded.toString())
          : 'Login failed with status ${response.statusCode}';
      throw Exception(message);
    }
  }
}
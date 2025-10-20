import 'package:shared_preferences/shared_preferences.dart';

/// Centralized helper for persisting authentication/session data locally.
class SessionManager {
  const SessionManager();

  static const _tokenKey = 'auth_token';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _usernameKey = 'user_username';

  /// Save the session details returned from the login API response.
  Future<void> saveSession({
    required String token,
    String? name,
    String? email,
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (name != null) {
      await prefs.setString(_nameKey, name);
    }
    if (email != null) {
      await prefs.setString(_emailKey, email);
    }
    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }
  }

  /// Returns the stored token if available.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  /// Returns a map containing the stored user details.
  Future<Map<String, String?>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
      'username': prefs.getString(_usernameKey),
    };
  }

  /// Clears all persisted session data.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
  }
}

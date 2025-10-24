import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  const SessionManager();

  static const _tokenKey = 'auth_token';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _usernameKey = 'user_username';
  static const _languageKey = 'user_language';

  Future<void> saveSession({
    required String token,
    String? name,
    String? email,
    String? username,
    String? language,
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
    if (language != null && language.isNotEmpty) {
      await prefs.setString(_languageKey, language);
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<Map<String, String?>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
      'username': prefs.getString(_usernameKey),
    };
  }

  Future<void> savePreferredLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  Future<String?> getPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString(_languageKey);
    if (language == null || language.isEmpty) {
      return null;
    }
    return language;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_languageKey);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  const SessionManager();

  static const _tokenKey = 'auth_token';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _usernameKey = 'user_username';
  static const _phoneKey = 'user_phone';
  static const _countryCodeKey = 'user_country_code';
  static const _languageKey = 'user_language';

  Future<void> saveSession({
    required String token,
    String? name,
    String? email,
    String? username,
    String? phone,
    String? countryCode,
    String? language,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await _setOptionalString(prefs, _nameKey, name);
    await _setOptionalString(prefs, _emailKey, email);
    await _setOptionalString(prefs, _usernameKey, username);
    await _setOptionalString(prefs, _phoneKey, phone);
    await _setOptionalString(prefs, _countryCodeKey, countryCode);
    await _setOptionalString(prefs, _languageKey, language);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<Map<String, String?>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
      'username': prefs.getString(_usernameKey),
      'phone': prefs.getString(_phoneKey),
      'country_code': prefs.getString(_countryCodeKey),
      'language': prefs.getString(_languageKey),
    };
  }

  Future<void> saveUserProfile({
    String? name,
    String? email,
    String? username,
    String? phone,
    String? countryCode,
    String? language,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _setOptionalString(prefs, _nameKey, name);
    await _setOptionalString(prefs, _emailKey, email);
    await _setOptionalString(prefs, _usernameKey, username);
    await _setOptionalString(prefs, _phoneKey, phone);
    await _setOptionalString(prefs, _countryCodeKey, countryCode);
    await _setOptionalString(prefs, _languageKey, language);
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
    await prefs.remove(_phoneKey);
    await prefs.remove(_countryCodeKey);
    await prefs.remove(_languageKey);
  }

  Future<void> _setOptionalString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null) {
      return;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, trimmed);
  }
}

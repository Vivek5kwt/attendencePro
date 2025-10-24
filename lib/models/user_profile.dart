class UserProfile {
  const UserProfile({
    this.name,
    this.email,
    this.username,
    this.phone,
    this.countryCode,
    this.language,
  });

  factory UserProfile.fromSession(Map<String, String?> raw) {
    String? read(String key) {
      final value = raw[key];
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return UserProfile(
      name: read('name'),
      email: read('email'),
      username: read('username'),
      phone: read('phone'),
      countryCode: read('country_code'),
      language: read('language'),
    );
  }

  factory UserProfile.fromApiResponse(
    Map<String, dynamic> response, {
    UserProfile? fallback,
  }) {
    Map<String, dynamic>? userMap;

    Map<String, dynamic>? asStringMap(dynamic input) {
      if (input is Map<String, dynamic>) {
        return input;
      }
      if (input is Map) {
        return Map<String, dynamic>.from(
          input.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      return null;
    }

    void consider(dynamic candidate) {
      final map = asStringMap(candidate);
      if (map != null && map.isNotEmpty) {
        userMap = map;
      }
    }

    consider(response['user']);

    final data = response['data'];
    if (data is Map || data is Map<String, dynamic>) {
      final dataMap = asStringMap(data);
      if (dataMap != null) {
        if (dataMap.containsKey('user')) {
          consider(dataMap['user']);
        } else {
          consider(dataMap);
        }
      }
    }

    final map = userMap;
    if (map == null || map.isEmpty) {
      return fallback ?? const UserProfile();
    }

    String? read(String key) {
      final value = map[key];
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      return null;
    }

    final derivedLanguage = read('language') ?? read('locale');

    return UserProfile(
      name: read('name') ?? fallback?.name,
      email: read('email') ?? fallback?.email,
      username: read('username') ?? fallback?.username,
      phone: read('phone') ?? fallback?.phone,
      countryCode:
          read('country_code') ?? read('countryCode') ?? fallback?.countryCode,
      language: derivedLanguage ?? fallback?.language,
    );
  }

  final String? name;
  final String? email;
  final String? username;
  final String? phone;
  final String? countryCode;
  final String? language;

  UserProfile copyWith({
    String? name,
    String? email,
    String? username,
    String? phone,
    String? countryCode,
    String? language,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      language: language ?? this.language,
    );
  }

  Map<String, String?> toSessionMap() {
    return {
      'name': name,
      'email': email,
      'username': username,
      'phone': phone,
      'country_code': countryCode,
      'language': language,
    };
  }

  String? get displayContact {
    for (final value in [email, phone, username]) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}

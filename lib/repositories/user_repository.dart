import '../apis/auth_api.dart' show ApiException;
import '../apis/user_api.dart';
import '../models/user_profile.dart';
import '../utils/session_manager.dart';

class UserRepository {
  UserRepository({UserApi? api, SessionManager? sessionManager})
      : _api = api ?? UserApi(),
        _sessionManager = sessionManager ?? const SessionManager();

  final UserApi _api;
  final SessionManager _sessionManager;

  Future<UserProfile> loadProfile() async {
    final raw = await _sessionManager.getUserProfile();
    return UserProfile.fromSession(raw);
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String username,
    required String phone,
    required String countryCode,
    required String language,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const UserAuthException();
    }

    final existing = await loadProfile();

    try {
      final response = await _api.updateProfile(
        token: token,
        name: name,
        username: username,
        phone: phone,
        countryCode: countryCode,
        language: language,
      );

      final fallback = existing.copyWith(
        name: name,
        username: username,
        phone: phone,
        countryCode: countryCode,
        language: language,
      );

      final updated = UserProfile.fromApiResponse(response, fallback: fallback);

      await _sessionManager.saveUserProfile(
        name: updated.name,
        email: updated.email ?? existing.email,
        username: updated.username,
        phone: updated.phone,
        countryCode: updated.countryCode,
        language: updated.language,
      );

      return updated;
    } on ApiException catch (e) {
      throw UserRepositoryException(e.message);
    }
  }
}

class UserRepositoryException implements Exception {
  const UserRepositoryException(this.message);

  final String message;
}

class UserAuthException extends UserRepositoryException {
  const UserAuthException() : super('Authentication required');
}

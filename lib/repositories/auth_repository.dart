import '../apis/auth_api.dart';

class AuthRepository {
  final AuthApi _api;

  AuthRepository({AuthApi? api}) : _api = api ?? AuthApi();

  Future<Map<String, dynamic>> login(String login, String password) {
    return _api.login(login, password);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirm,
    required String phone,
    required String countryCode,
    required String language,
  }) {
    return _api.register(
      name: name,
      email: email,
      password: password,
      confirm: confirm,
      phone: phone,
      countryCode: countryCode,
      language: language,
    );
  }

  Future<Map<String, dynamic>> logout(String token) {
    return _api.logout(token);
  }

  Future<Map<String, dynamic>?> deleteAccount(String token) {
    return _api.deleteAccount(token);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) {
    return _api.forgotPassword(email);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required int otp,
  }) {
    return _api.verifyOtp(email: email, otp: otp);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String verifyToken,
    required String password,
    required String confirm,
  }) {
    return _api.resetPassword(
      email: email,
      verifyToken: verifyToken,
      password: password,
      confirm: confirm,
    );
  }
}

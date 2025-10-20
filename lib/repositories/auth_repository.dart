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
    required String username,
    required String password,
    required String confirm,
  }) {
    return _api.register(
      name: name,
      email: email,
      username: username,
      password: password,
      confirm: confirm,
    );
  }

  Future<Map<String, dynamic>> logout(String token) {
    return _api.logout(token);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) {
    return _api.forgotPassword(email);
  }
}

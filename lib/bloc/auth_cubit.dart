import 'package:flutter_bloc/flutter_bloc.dart';

import '../apis/auth_api.dart';
import '../repositories/auth_repository.dart';
import '../utils/session_manager.dart';

abstract class AuthState {}

class AuthPhoneInput extends AuthState {
  final bool isSignup;
  final String? name;
  AuthPhoneInput({this.isSignup = false, this.name});
}

class AuthVerifyNumber extends AuthState {
  final String phone;
  final bool isSignup;
  AuthVerifyNumber(this.phone, {this.isSignup = false});
}

class AuthCreatePassword extends AuthState {
  final String phone;
  AuthCreatePassword(this.phone);
}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic>? data;
  AuthAuthenticated({this.data});
}

class AuthLoading extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  final SessionManager _sessionManager;

  AuthCubit({AuthRepository? repository, SessionManager? sessionManager})
      : _repository = repository ?? AuthRepository(),
        _sessionManager = sessionManager ?? const SessionManager(),
        super(AuthPhoneInput(isSignup: false));

  String? _pendingPhone; // used by phone flows
  bool _isSignup = false;
  bool _isReset = false;
  String? _pendingName;
  String? _pendingPassword;
  String? _pendingConfirm;

  void showPhone({bool isSignup = false, String? name}) {
    _isSignup = isSignup;
    _isReset = false;
    _pendingName = name;
    emit(AuthPhoneInput(isSignup: isSignup, name: name));
  }


  Future<void> submitPhone(String phone,
      {bool isSignup = false, String? name, String? password, String? confirm}) async
  {
    if (phone.trim().isEmpty) {
      emit(AuthError('Please enter a phone number.'));
      emit(AuthPhoneInput(isSignup: isSignup, name: name));
      return;
    }
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 400));
    _pendingPhone = phone;
    _isSignup = isSignup;
    _isReset = false;
    _pendingName = name;
    _pendingPassword = password;
    _pendingConfirm = confirm;
    emit(AuthVerifyNumber(phone, isSignup: isSignup));
  }

  /// REGISTER using provided API:
  /// POST https://attendancepro.shauryacoder.com/api/auth/register
  /// body: { "name", "email", "username", "password", "password_confirmation" }
  Future<void> register({
    required String name,
    required String email,
    required String username,
    required String password,
    required String confirm,
  })
  async {
    if (name.trim().isEmpty) {
      emit(AuthError('Name is required.'));
      return;
    }
    if (email.trim().isEmpty) {
      emit(AuthError('Email is required.'));
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
      emit(AuthError('Invalid email address.'));
      return;
    }
    if (password.isEmpty || confirm.isEmpty) {
      emit(AuthError('Please enter and confirm your password.'));
      return;
    }
    if (password != confirm) {
      emit(AuthError('Passwords do not match.'));
      return;
    }

    emit(AuthLoading());
    try {
      final response = await _repository.register(
        name: name,
        email: email,
        username: username,
        password: password,
        confirm: confirm,
      );
      await _persistSessionFromResponse(response);
      emit(AuthAuthenticated(data: response));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Network error: $e'));
    }
  }

  /// LOGIN FUNCTION (Backend API)
  Future<void> login(String login, String password) async {
    if (login.trim().isEmpty) {
      emit(AuthError('Please enter your email/username.'));
      return;
    }
    if (password.isEmpty) {
      emit(AuthError('Please enter your password.'));
      return;
    }

    emit(AuthLoading());
    try {
      final response = await _repository.login(login, password);
      await _persistSessionFromResponse(response);
      emit(AuthAuthenticated(data: response));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Network error: $e'));
    }
  }

  /// FORGOT PASSWORD FLOW
  Future<void> forgotPassword(String emailOrPhone) async {
    if (emailOrPhone.isEmpty) {
      emit(AuthError('Please enter your email or phone.'));
      emit(AuthPhoneInput());
      return;
    }
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    _pendingPhone = emailOrPhone;
    _isReset = true;
    emit(AuthVerifyNumber(emailOrPhone));
  }
  Future<void> verifyCode(String code) async {
    if (_pendingPhone == null) {
      emit(AuthError('No phone submitted.'));
      emit(AuthPhoneInput(isSignup: _isSignup, name: _pendingName));
      return;
    }
    if (code.trim().isEmpty) {
      emit(AuthError('Please enter the verification code.'));
      emit(AuthVerifyNumber(_pendingPhone!, isSignup: _isSignup));
      return;
    }

    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 400));

    if (_isSignup) {
      if (_pendingPassword != null && _pendingConfirm != null) {
        final password = _pendingPassword!;
        final confirm = _pendingConfirm!;
        if (password.isEmpty || confirm.isEmpty) {
          emit(AuthError('Please enter and confirm your password.'));
          emit(AuthCreatePassword(_pendingPhone!));
          return;
        }
        if (password != confirm) {
          emit(AuthError('Passwords do not match.'));
          emit(AuthCreatePassword(_pendingPhone!));
          return;
        }
        await Future.delayed(const Duration(milliseconds: 400));
        emit(AuthAuthenticated(data: {'phone': _pendingPhone}));
      } else {
        emit(AuthCreatePassword(_pendingPhone!));
      }
    } else if (_isReset) {
      emit(AuthCreatePassword(_pendingPhone!));
    } else {
      emit(AuthAuthenticated(data: {'phone': _pendingPhone}));
    }
  }

  Future<void> createPassword(String password, String confirm) async {
    if (_pendingPhone == null) {
      emit(AuthError('No phone submitted.'));
      emit(AuthPhoneInput(isSignup: _isSignup, name: _pendingName));
      return;
    }
    if (password.isEmpty || confirm.isEmpty) {
      emit(AuthError('Please enter and confirm your password.'));
      emit(AuthCreatePassword(_pendingPhone!));
      return;
    }
    if (password != confirm) {
      emit(AuthError('Passwords do not match.'));
      emit(AuthCreatePassword(_pendingPhone!));
      return;
    }

    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 400));
    emit(AuthAuthenticated(data: {'phone': _pendingPhone}));
    _isReset = false;
    _isSignup = false;
  }

  void backToPhone() {
    _isReset = false;
    emit(AuthPhoneInput(isSignup: _isSignup, name: _pendingName));
  }

  void logout() => emit(AuthPhoneInput());

  Future<void> _persistSessionFromResponse(Map<String, dynamic> response) async {
    try {
      final data = response['data'];
      if (data is! Map<String, dynamic>) return;

      final token = data['token'];
      if (token is! String || token.isEmpty) return;

      String? name;
      String? email;
      String? username;

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final potentialName = user['name'];
        if (potentialName is String && potentialName.isNotEmpty) {
          name = potentialName;
        }
        final potentialEmail = user['email'];
        if (potentialEmail is String && potentialEmail.isNotEmpty) {
          email = potentialEmail;
        }
        final potentialUsername = user['username'];
        if (potentialUsername is String && potentialUsername.isNotEmpty) {
          username = potentialUsername;
        }
      }

      await _sessionManager.saveSession(
        token: token,
        name: name,
        email: email,
        username: username,
      );
    } catch (_) {
      // Ignore storage errors to avoid impacting the login flow.
    }
  }
}

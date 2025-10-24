import 'package:flutter_bloc/flutter_bloc.dart';

import '../apis/auth_api.dart';
import '../repositories/auth_repository.dart';
import '../utils/session_manager.dart';

abstract class AuthState {}

class AuthPhoneInput extends AuthState {
  final bool isSignup;
  final String? name;
  final String? infoMessage;
  AuthPhoneInput({this.isSignup = false, this.name, this.infoMessage});
}

class AuthVerifyNumber extends AuthState {
  final String phone;
  final bool isSignup;
  final String? infoMessage;
  AuthVerifyNumber(
    this.phone, {
    this.isSignup = false,
    this.infoMessage,
  });
}

class AuthCreatePassword extends AuthState {
  final String phone;
  final String? infoMessage;
  AuthCreatePassword(this.phone, {this.infoMessage});
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

  String? _pendingPhone;
  bool _isSignup = false;
  bool _isReset = false;
  String? _pendingName;
  String? _pendingPassword;
  String? _pendingConfirm;
  String? _verifyToken;

  String? get verifyToken => _verifyToken;

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
    _verifyToken = null;
    emit(AuthVerifyNumber(phone, isSignup: isSignup));
  }


  Future<void> register({
    required String name,
    required String email,
    required String username,
    required String password,
    required String confirm,
    required String phone,
    required String countryCode,
    required String language,
  })
  async {
    if (name.trim().isEmpty) {
      emit(AuthError('Name is required.'));
      return;
    }
    if (username.trim().isEmpty) {
      emit(AuthError('Username is required.'));
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
    if (phone.trim().isEmpty) {
      emit(AuthError('Please enter your phone number.'));
      return;
    }
    if (countryCode.trim().isEmpty) {
      emit(AuthError('Please select a country code.'));
      return;
    }
    if (language.trim().isEmpty) {
      emit(AuthError('Please select your preferred language.'));
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
        phone: phone,
        countryCode: countryCode,
        language: language,
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
  Future<void> forgotPassword(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      emit(AuthError('Please enter your email.'));
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmedEmail)) {
      emit(AuthError('Please enter a valid email address.'));
      return;
    }

    emit(AuthLoading());
    try {
      final response = await _repository.forgotPassword(trimmedEmail);
      final message =
          _extractReadableMessage(response) ?? 'OTP sent successfully to your email.';

      _pendingPhone = trimmedEmail;
      _isReset = true;
      _isSignup = false;
      _verifyToken = null;
      emit(AuthVerifyNumber(trimmedEmail, infoMessage: message));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Network error: $e'));
    }
  }
  Future<void> verifyCode(String code) async {
    if (_pendingPhone == null) {
      emit(AuthError('No phone submitted.'));
      emit(AuthPhoneInput(isSignup: _isSignup, name: _pendingName));
      return;
    }
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      emit(AuthError('Please enter the verification code.'));
      emit(AuthVerifyNumber(_pendingPhone!, isSignup: _isSignup));
      return;
    }

    emit(AuthLoading());
    try {
      if (_isReset) {
        final otpValue = int.tryParse(trimmedCode);
        if (otpValue == null) {
          emit(AuthVerifyNumber(
            _pendingPhone!,
            isSignup: _isSignup,
            infoMessage: 'Invalid verification code format.',
          ));
          return;
        }

        final response = await _repository.verifyOtp(
          email: _pendingPhone!,
          otp: otpValue,
        );

        final message =
            _extractReadableMessage(response) ?? 'OTP verified successfully.';
        final token = _extractVerifyToken(response);
        if (token != null) {
          _verifyToken = token;
        }
        emit(AuthCreatePassword(
          _pendingPhone!,
          infoMessage: message,
        ));
        return;
      }

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
          emit(AuthAuthenticated(data: {'phone': _pendingPhone}));
        } else {
          emit(AuthCreatePassword(_pendingPhone!));
        }
      } else {
        emit(AuthAuthenticated(data: {'phone': _pendingPhone}));
      }
    } on ApiException catch (e) {
      emit(AuthVerifyNumber(
        _pendingPhone!,
        isSignup: _isSignup,
        infoMessage: e.message,
      ));
    } catch (e) {
      emit(AuthVerifyNumber(
        _pendingPhone!,
        isSignup: _isSignup,
        infoMessage: 'Network error: $e',
      ));
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
    if (_isReset) {
      final email = _pendingPhone!;
      final token = _verifyToken;
      if (token == null || token.isEmpty) {
        emit(AuthCreatePassword(
          email,
          infoMessage: 'Missing verification token. Please request a new code.',
        ));
        return;
      }

      try {
        final response = await _repository.resetPassword(
          email: email,
          verifyToken: token,
          password: password,
          confirm: confirm,
        );

        final message =
            _extractReadableMessage(response) ?? 'Password reset successfully.';

        _isReset = false;
        _isSignup = false;
        _pendingPhone = null;
        _pendingPassword = null;
        _pendingConfirm = null;
        _verifyToken = null;

        emit(AuthPhoneInput(infoMessage: message));
      } on ApiException catch (e) {
        emit(AuthCreatePassword(
          email,
          infoMessage: e.message,
        ));
      } catch (e) {
        emit(AuthCreatePassword(
          email,
          infoMessage: 'Network error: $e',
        ));
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 400));
    emit(AuthAuthenticated(data: {'phone': _pendingPhone}));
    _isReset = false;
    _isSignup = false;
  }

  String? _extractVerifyToken(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final potentialToken = data['verify_token'];
      if (potentialToken is String && potentialToken.isNotEmpty) {
        return potentialToken;
      }
    }
    return null;
  }

  void backToPhone() {
    _isReset = false;
    emit(AuthPhoneInput(isSignup: _isSignup, name: _pendingName));
  }

  void logout() => emit(AuthPhoneInput());

  String? _extractReadableMessage(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['message'],
      response['msg'],
      response['status'],
      if (response['data'] is Map<String, dynamic>)
        (response['data'] as Map<String, dynamic>)['message'],
    ];

    for (final candidate in candidates) {
      if (candidate is String) {
        final trimmed = candidate.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.toLowerCase() == 'success') continue;
        return trimmed;
      }
    }

    return null;
  }

  Future<void> _persistSessionFromResponse(Map<String, dynamic> response) async {
    try {
      final data = response['data'];
      if (data is! Map<String, dynamic>) return;

      final token = data['token'];
      if (token is! String || token.isEmpty) return;

      String? name;
      String? email;
      String? username;
      String? language;

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
        final potentialLanguage = user['language'];
        if (potentialLanguage is String && potentialLanguage.isNotEmpty) {
          language = potentialLanguage;
        }
      }

      await _sessionManager.saveSession(
        token: token,
        name: name,
        email: email,
        username: username,
        language: language,
      );
    } catch (_) {
    }
  }
}

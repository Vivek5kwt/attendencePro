import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../services/auth_api.dart';

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
  final String _baseUrl = 'https://attendancepro.shauryacoder.com';

  AuthCubit() : super(AuthPhoneInput(isSignup: false));

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
    final uri = Uri.parse('$_baseUrl/api/auth/register');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'username': username,
          'password': password,
          'password_confirmation': confirm,
        }),
      );

      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {
        body = null;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // API sample returns: { "status":"success", "message":"User registered successfully", "data": {...} }
        if (body != null) {
          emit(AuthAuthenticated(data: body));
        } else {
          emit(AuthAuthenticated(data: {'raw': response.body}));
        }
      } else {
        // try to extract message
        String message = 'Registration failed with status: ${response.statusCode}';
        if (body != null) {
          if (body['message'] != null) {
            message = body['message'].toString();
          } else if (body['errors'] != null) {
            // errors may be a map of lists
            final errors = body['errors'];
            if (errors is Map) {
              final firstKey = errors.keys.isNotEmpty ? errors.keys.first : null;
              if (firstKey != null) {
                final val = errors[firstKey];
                if (val is List && val.isNotEmpty) message = val.first.toString();
                else message = val.toString();
              }
            } else {
              message = errors.toString();
            }
          }
        }
        emit(AuthError(message));
      }
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
    final uri = Uri.parse('$_baseUrl/api/auth/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      );

      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        emit(AuthAuthenticated(data: body ?? {'raw': response.body}));
      } else {
        final String message = (body != null && body['message'] != null)
            ? body['message'].toString()
            : 'Request failed with status: ${response.statusCode}';
        emit(AuthError(message));
      }
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
}
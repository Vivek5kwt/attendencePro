import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/auth_repository.dart';
import '../utils/session_manager.dart';

abstract class AppState {}

class AppSplash extends AppState {}

class AppWalkthrough extends AppState {}

class AppAuth extends AppState {}

class AppHome extends AppState {}

class AppCubit extends Cubit<AppState> {
  final SessionManager _sessionManager;
  final AuthRepository _authRepository;

  AppCubit({SessionManager? sessionManager, AuthRepository? authRepository})
      : _sessionManager = sessionManager ?? const SessionManager(),
        _authRepository = authRepository ?? AuthRepository(),
        super(AppSplash()) {
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(seconds: 2));

    if (isClosed) return;

    final storedToken = await _sessionManager.getToken();
    if (storedToken != null) {
      emit(AppHome());
    } else {
      emit(AppWalkthrough());
    }
  }

  void showWalkthrough() => emit(AppWalkthrough());

  void showAuth() => emit(AppAuth());

  void showHome() => emit(AppHome());

  Future<bool> logout() async {
    final token = await _sessionManager.getToken();
    var wasSuccessful = token == null;
    if (token != null) {
      try {
        await _authRepository.logout(token);
        wasSuccessful = true;
      } catch (_) {
        wasSuccessful = false;
      }
    }
    await _sessionManager.clearSession();
    emit(AppAuth());
    return wasSuccessful;
  }

  Future<bool> deleteAccount() async {
    final token = await _sessionManager.getToken();
    if (token == null) {
      return false;
    }

    try {
      await _authRepository.deleteAccount(token);
      await _sessionManager.clearSession();
      emit(AppAuth());
      return true;
    } catch (_) {
      return false;
    }
  }
}

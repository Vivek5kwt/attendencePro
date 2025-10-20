import 'package:flutter_bloc/flutter_bloc.dart';

/// Base abstract class representing app-level navigation states.
abstract class AppState {}

/// Shown when the app is starting up.
class AppSplash extends AppState {}

/// Shown the first time the app runs (intro or tutorial).
class AppWalkthrough extends AppState {}

/// Shown when the user needs to log in or sign up.
class AppAuth extends AppState {}

/// Shown after the user is authenticated.
class AppHome extends AppState {}

/// The main Cubit that manages which screen (state) the app should show.
class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppSplash()) {
    _startSplash();
  }

  /// Handles the splash screen duration and then moves to the next screen.
  Future<void> _startSplash() async {
    // Keep splash visible for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Normally, check persistent storage (e.g., SharedPreferences) here
    // For now, just go to Walkthrough for demonstration
    emit(AppWalkthrough());
  }

  /// Show the Walkthrough (intro/tutorial)
  void showWalkthrough() => emit(AppWalkthrough());

  /// Show the Authentication flow (login/signup)
  void showAuth() => emit(AppAuth());

  /// Show the Home screen (main app)
  void showHome() => emit(AppHome());

  /// Perform logout and return to Auth screen
  void logout() {
    // In a real app, clear user tokens, prefs, etc. here
    emit(AppAuth());
  }
}
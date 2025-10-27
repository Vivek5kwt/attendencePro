import 'package:attendancepro/screens/signup_screen.dart';
import 'package:attendancepro/screens/verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/app_cubit.dart';
import '../bloc/work_bloc.dart';
import '../bloc/locale_cubit.dart';
import '../bloc/work_event.dart';
import 'create_password_screen.dart';
import 'login_phone_screen.dart';
import '../utils/responsive.dart';

class AuthFlow extends StatefulWidget {
  const AuthFlow({Key? key}) : super(key: key);

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  AuthState? _lastNonLoadingState;

  @override
  void initState() {
    super.initState();
    _lastNonLoadingState = context.read<AuthCubit>().state;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final languageCode = _extractLanguageCode(state.data);
          if (languageCode != null && languageCode.isNotEmpty) {
            context.read<LocaleCubit>().setLocale(Locale(languageCode));
          }
          context.read<WorkBloc>().add(const WorkStarted());
          context.read<AppCubit>().showHome(openDashboardOnLogin: true);
        } else if (state is AuthVerifyNumber) {
          final message = state.infoMessage;
          if (message != null && message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message.trim()),
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (state is AuthPhoneInput) {
          final message = state.infoMessage;
          if (message != null && message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message.trim()),
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (state is AuthCreatePassword) {
          final message = state.infoMessage;
          if (message != null && message.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message.trim()),
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final responsive = context.responsive;
        final bool isLoading = state is AuthLoading;
        if (!isLoading && state is! AuthError) {
          _lastNonLoadingState = state;
        }

        final AuthState effectiveState;
        if (state is AuthError && _lastNonLoadingState != null) {
          effectiveState = _lastNonLoadingState!;
        } else if (isLoading && _lastNonLoadingState != null) {
          effectiveState = _lastNonLoadingState!;
        } else {
          effectiveState = state;
        }

        Widget child;
        if (effectiveState is AuthPhoneInput) {
          child = effectiveState.isSignup
              ? SignupScreen(initialName: effectiveState.name)
              : const LoginPhoneScreen();
        } else if (effectiveState is AuthVerifyNumber) {
          child =
              VerifyScreen(phone: effectiveState.phone, isSignup: effectiveState.isSignup);
        } else if (effectiveState is AuthCreatePassword) {
          child = CreatePasswordScreen(phone: effectiveState.phone);
        } else {
          child = const LoginPhoneScreen();
        }

        return Stack(
          children: [
            child,
            IgnorePointer(
              ignoring: !isLoading,
              child: AnimatedOpacity(
                opacity: isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: responsive.scale(48),
                    height: responsive.scale(48),
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String? _extractLanguageCode(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }
  final payload = data['data'];
  if (payload is Map<String, dynamic>) {
    final user = payload['user'];
    if (user is Map<String, dynamic>) {
      final language = user['language'];
      if (language is String) {
        return language;
      }
    }
    final language = payload['language'];
    if (language is String) {
      return language;
    }
  }
  final language = data['language'];
  if (language is String) {
    return language;
  }
  return null;
}

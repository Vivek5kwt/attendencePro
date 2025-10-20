import 'package:attendancepro/screens/signup_screen.dart';
import 'package:attendancepro/screens/verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/app_cubit.dart';
import 'create_password_screen.dart';
import 'login_phone_screen.dart';

class AuthFlow extends StatelessWidget {
  const AuthFlow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // When authenticated, move app to home
          context.read<AppCubit>().showHome();
        } else if (state is AuthError) {
          // Show error message in SnackBar instead of a full screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // After showing error, return to phone input screen
          context.read<AuthCubit>().showPhone();
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is AuthPhoneInput) {
            if (state.isSignup) {
              return SignupScreen(initialName: state.name);
            } else {
              return const LoginPhoneScreen();
            }
          } else if (state is AuthVerifyNumber) {
            return VerifyScreen(phone: state.phone, isSignup: state.isSignup);
          } else if (state is AuthCreatePassword) {
            return CreatePasswordScreen(phone: state.phone);
          } else {
            // Default to login screen
            return const LoginPhoneScreen();
          }
        },
      ),
    );
  }
}

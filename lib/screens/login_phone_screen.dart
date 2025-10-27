import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/locale_cubit.dart';
import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../core/localization/app_localizations.dart';
import '../core/navigation/routes.dart';
import '../widgets/app_dialogs.dart';
import 'forgot_password_screen.dart';

class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({Key? key}) : super(key: key);

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _submitLogin(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rawLoginValue = _loginController.text.trim();
    final password = _passwordController.text;

    if (rawLoginValue.isEmpty) {
      _showSnack(l.snackEnterLoginIdentifier);
      return;
    }

    final preparedLoginValue = _prepareLoginValue(rawLoginValue);
    if (preparedLoginValue == null) {
      _showSnack(l.snackEnterValidLoginIdentifier);
      return;
    }
    if (password.isEmpty) {
      _showSnack(l.snackEnterPassword);
      return;
    }

    FocusScope.of(context).unfocus();
    final authCubit = context.read<AuthCubit>();
    authCubit.login(preparedLoginValue, password.trim());
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _prepareLoginValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.contains('@')) {
      return _isValidEmail(trimmed) ? trimmed : null;
    }

    final normalizedPhone = _normalizePhone(trimmed);
    if (normalizedPhone == null) {
      return null;
    }

    return _isValidPhone(normalizedPhone) ? normalizedPhone : null;
  }

  String? _normalizePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('+')) {
      final digits = trimmed.substring(1).replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) {
        return null;
      }
      return '+$digits';
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.isEmpty ? null : digitsOnly;
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(trimmed);
  }

  bool _isValidPhone(String phone) {
    if (phone.isEmpty) {
      return false;
    }

    final digits = phone.startsWith('+') ? phone.substring(1) : phone;
    if (digits.length < 7 || digits.length > 15) {
      return false;
    }

    final regex = RegExp(r'^\+?\d+$');
    return regex.hasMatch(phone);
  }


  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final languageOptions = {
      'en': l.languageEnglish,
      'hi': l.languageHindi,
      'pa': l.languagePunjabi,
      'it': l.languageItalian,
    };
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showSnack(state.message);
          return;
        }

        if (state is AuthVerifyNumber) {
          final message = state.infoMessage;
          if (message != null && message.trim().isNotEmpty) {
            _showSnack(message.trim());
          }
          if (mounted) context.go(Routes.auth);
          return;
        }

        if (state is AuthCreatePassword) {
          if (mounted) context.go(Routes.auth);
          return;
        }

        if (state is AuthAuthenticated) {
          String message = l.snackLoginSuccess;
          final data = state.data;

          if (data != null) {
            dynamic apiMessage;
            if (data['message'] is String) {
              apiMessage = data['message'];
            } else if (data['msg'] is String) {
              apiMessage = data['msg'];
            } else if (data['status'] is String &&
                data['status'].toString().toLowerCase() != 'success') {
              apiMessage = data['status'];
            } else if (data['data'] is Map &&
                data['data']['message'] is String) {
              apiMessage = data['data']['message'];
            }

            if (apiMessage is String && apiMessage.trim().isNotEmpty) {
              message = apiMessage.trim();
            }
          }

          _showSnack(message);

          context.read<WorkBloc>().add(const WorkStarted());

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) context.go(Routes.home);
          });
        }
      },
      child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        l.loginTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      l.loginIdentifierLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _loginController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: l.loginIdentifierHint,
                        hintStyle: const TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l.passwordLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: l.passwordHint,
                        hintStyle: const TextStyle(color: Colors.black26),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<AuthCubit, AuthState>(
                      buildWhen: (previous, current) =>
                          previous is AuthLoading || current is AuthLoading,
                      builder: (context, state) {
                        final isProcessing = state is AuthLoading;
                        return SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007BFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () => _submitLogin(context),
                            child: Text(
                              l.loginButton,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l.forgotPassword,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: InkWell(
                        onTap: () {
                          final authCubit = context.read<AuthCubit>();
                          authCubit.showPhone(isSignup: true);
                          context.go(Routes.auth);
                        },
                        child: RichText(
                          text: TextSpan(
                            text: l.signupPromptPrefix,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: l.signupPromptAction,
                                style: const TextStyle(
                                  color: Color(0xFF007BFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () async {
                          final currentCode =
                              context.read<LocaleCubit>().state.languageCode;
                          final selected = await showCreativeLanguageDialog(
                            context,
                            options: languageOptions,
                            currentSelection: currentCode,
                            localizations: l,
                          );

                          if (selected != null &&
                              languageOptions.containsKey(selected)) {
                            context
                                .read<LocaleCubit>()
                                .setLocale(Locale(selected));
                            final updatedLocalization =
                                AppLocalizations(Locale(selected));
                            final updatedNames = {
                              'en': updatedLocalization.languageEnglish,
                              'hi': updatedLocalization.languageHindi,
                              'pa': updatedLocalization.languagePunjabi,
                              'it': updatedLocalization.languageItalian,
                            };
                            final label =
                                updatedNames[selected] ?? languageOptions[selected]!;
                            _showSnack(
                                updatedLocalization.languageSelection(label));
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.language, color: Color(0xFF007BFF)),
                            const SizedBox(width: 8),
                            Text(
                              l.changeLanguage,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

    );
  }
}

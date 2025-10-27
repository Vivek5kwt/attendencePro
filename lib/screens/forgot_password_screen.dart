import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../utils/responsive.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(trimmed);
  }

  void _submit() {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack(l.snackResetEmail);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack(l.snackForgotInvalidEmail);
      return;
    }

    FocusScope.of(context).unfocus();
    _submitted = true;
    context.read<AuthCubit>().forgotPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!_submitted) {
          return;
        }

        if (state is AuthError) {
          _showSnack(state.message);
          _submitted = false;
          return;
        }

        if (state is AuthVerifyNumber) {
          final message = state.infoMessage;
          if (message != null && message.trim().isNotEmpty) {
            _showSnack(message.trim());
          }
          _submitted = false;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.scale(24),
                vertical: responsive.scale(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: responsive.scale(20),
                    ),
                    color: Colors.black87,
                  ),
                  SizedBox(height: responsive.scale(12)),
                  Text(
                    l.forgotPassword,
                    style: TextStyle(
                      fontSize: responsive.scaleText(28),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: responsive.scale(12)),
                  Text(
                    l.forgotPasswordSubtitle,
                    style: TextStyle(
                      fontSize: responsive.scaleText(15),
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: responsive.scale(32)),
                  Text(
                    l.forgotPasswordFieldLabel,
                    style: TextStyle(
                      fontSize: responsive.scaleText(15),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: responsive.scale(8)),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: l.forgotPasswordFieldHint,
                      hintStyle: TextStyle(
                        color: Colors.black38,
                        fontSize: responsive.scaleText(14),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsive.scale(16),
                        vertical: responsive.scale(14),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(responsive.scale(32)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.scale(28)),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isProcessing = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: responsive.scale(55),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(responsive.scale(32)),
                            ),
                          ),
                          onPressed: isProcessing ? null : _submit,
                          child: isProcessing
                              ? SizedBox(
                                  height: responsive.scale(24),
                                  width: responsive.scale(24),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  l.sendOtpButton,
                                  style: TextStyle(
                                    fontSize: responsive.scaleText(18),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: responsive.scale(24)),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l.backToLogin,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: responsive.scaleText(15),
                          fontWeight: FontWeight.w500,
                        ),
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

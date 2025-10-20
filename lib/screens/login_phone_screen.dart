import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';
import '../core/navigation/routes.dart';

class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({Key? key}) : super(key: key);

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _submitLogin(BuildContext context) {
    final emailToUse = _emailController.text.trim();
    final password = _passwordController.text;

    if (emailToUse.isEmpty) {
      _showSnack('Please enter your email.');
      return;
    }
    if (!_isValidEmail(emailToUse)) {
      _showSnack('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showSnack('Please enter your password.');
      return;
    }

    FocusScope.of(context).unfocus();
    final authCubit = context.read<AuthCubit>();
    authCubit.login(emailToUse, password.trim());
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

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(trimmed);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showSnack(state.message);
          return;
        }

        if (state is AuthVerifyNumber || state is AuthCreatePassword) {
          if (mounted) context.go(Routes.auth);
          return;
        }

        if (state is AuthAuthenticated) {
          String message = 'Logged in successfully';
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

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) context.go(Routes.home);
          });
        }
      },
      child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: SafeArea(
            child: SingleChildScrollView( // ✅ Fix overflow
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "you@example.com",
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
                    const Text(
                      "Password",
                      style: TextStyle(
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
                        hintText: "********",
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
                            child: const Text(
                              "Login",
                              style: TextStyle(
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
                          final emailToUse = _emailController.text.trim();
                          final authCubit = context.read<AuthCubit>();
                          if (emailToUse.isEmpty) {
                            _showSnack('Please enter your email to reset.');
                            return;
                          }
                          if (emailToUse.contains('@') &&
                              !_isValidEmail(emailToUse)) {
                            _showSnack('Please enter a valid email address.');
                            return;
                          }
                          authCubit.forgotPassword(emailToUse);
                        },
                        child: const Text(
                          "Forgot Your Password?",
                          style: TextStyle(
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
                          text: const TextSpan(
                            text: "Don’t Have an Account? ",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign Up",
                                style: TextStyle(
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
                        onTap: () {
                          showDialog<String>(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              title: const Text('Select Language'),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(ctx, 'en'),
                                  child: const Text('English'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(ctx, 'hi'),
                                  child: const Text('Hindi'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(ctx, 'pa'),
                                  child: const Text('Punjabi'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(ctx, 'it'),
                                  child: const Text('Italian'),
                                ),
                              ],
                            ),
                          ).then((selected) {
                            if (selected != null) {
                              const languageNames = {
                                'en': 'English',
                                'hi': 'Hindi',
                                'pa': 'Punjabi',
                                'it': 'Italian',
                              };
                              final languageName = languageNames[selected] ?? selected;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Language: $languageName')),
                              );
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.language, color: Color(0xFF007BFF)),
                            SizedBox(width: 8),
                            Text(
                              "Change Language",
                              style: TextStyle(
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

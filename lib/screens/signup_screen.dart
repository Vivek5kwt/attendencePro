import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import '../core/localization/app_localizations.dart';
import 'policy_screen.dart';

class SignupScreen extends StatefulWidget {
  final String? initialName;
  const SignupScreen({Key? key, this.initialName}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _agreed = false;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _submitSignup() {
    final l = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.termsAgreement)),
      );
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    String username = email;
    if (email.contains('@')) {
      username = email.split('@').first;
      if (username.isEmpty) username = name.replaceAll(' ', '').toLowerCase();
    } else {
      username = name.replaceAll(' ', '').toLowerCase();
    }

    context.read<AuthCubit>().register(
      name: name,
      email: email,
      username: username,
      password: password,
      confirm: confirm,
    );
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PolicyScreen(type: PolicyType.terms),
      ),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PolicyScreen(type: PolicyType.privacy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthAuthenticated) {
          final msg = state.data?['message'] ??
              state.data?['status'] ??
              AppLocalizations.of(context).operationSuccessful;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    l.signupTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.fullNameLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(l.fullNameLabel),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.nameRequired
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.emailAddressLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(l.emailAddressLabel),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l.emailRequired;
                      final email = v.trim();
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email))
                        return l.emailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.passwordLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: _inputDecoration(l.passwordLabel).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.passwordRequired;
                      if (v.length < 6) return l.passwordMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.confirmPasswordLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: !_confirmVisible,
                    decoration: _inputDecoration(l.confirmPasswordLabel).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _confirmVisible = !_confirmVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return l.confirmPasswordRequired;
                      if (v != _passwordController.text)
                        return l.confirmPasswordMismatch;
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        activeColor: const Color(0xFF007BFF),
                        value: _agreed,
                        onChanged: (v) =>
                            setState(() => _agreed = v ?? false),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: l.agreeTextPrefix,
                            style: const TextStyle(color: Colors.black87),
                            children: [
                              TextSpan(
                                text: l.userAgreement,
                                style: const TextStyle(color: Color(0xFF007BFF)),
                                recognizer: _termsRecognizer,
                              ),
                              TextSpan(text: l.and),
                              TextSpan(
                                text: l.privacyPolicy,
                                style: const TextStyle(color: Color(0xFF007BFF)),
                                recognizer: _privacyRecognizer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  BlocBuilder<AuthCubit, AuthState>(
                    buildWhen: (previous, current) =>
                        previous is AuthLoading || current is AuthLoading,
                    builder: (context, state) {
                      final isProcessing = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isProcessing ? null : _submitSignup,
                          child: Text(
                            l.signupButton,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.alreadyAccountPrompt),
                      GestureDetector(
                        onTap: () =>
                            context.read<AuthCubit>().showPhone(isSignup: false),
                        child: Text(
                          l.loginAction,
                          style: const TextStyle(
                            color: Color(0xFF007BFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF007BFF)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/app_cubit.dart';
import '../bloc/auth_cubit.dart';
import '../core/localization/app_localizations.dart';

/// The CreatePasswordScreen allows the user to create/reset a password.
/// The back button behavior has been updated so that if there is no
/// previous route to pop to (which could result in a blank/black screen),
/// it will instead try to route the app via AppCubit to a safe state
/// (e.g., showAuth). If AppCubit is not available in the context, it will
/// simply do nothing rather than popping into a blank screen.
class CreatePasswordScreen extends StatefulWidget {
  final String phone;
  const CreatePasswordScreen({super.key, required this.phone});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorText;

  void _resetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().createPassword(
            _passController.text,
            _confirmController.text,
          );
    }
  }

  /// Improved back behavior:
  /// - If Navigator can pop, pop as usual.
  /// - If there's nothing to pop to (popping would reveal a blank/black screen),
  ///   try to use AppCubit to navigate to a safe app state (e.g., Auth screen).
  /// - If AppCubit is not available, do nothing (prevents showing a black screen).
  void _back() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    try {
      context.read<AppCubit>().showAuth();
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                ),
                const SizedBox(height: 16),
                Text(
                  l.createPasswordTitle,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  l.newPasswordLabel,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passController,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: l.newPasswordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePass = !_obscurePass);
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      setState(() {
                        _errorText = l.passwordMinEight;
                      });
                      return '';
                    }
                    if (_errorText != null) {
                      setState(() {
                        _errorText = null;
                      });
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l.confirmPasswordLabel,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: l.confirmPasswordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passController.text) {
                      setState(() {
                        _errorText = l.passwordsDoNotMatch;
                      });
                      return '';
                    }
                    if (_errorText != null) {
                      setState(() {
                        _errorText = null;
                      });
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (_errorText != null)
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      l.resetPasswordButton,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



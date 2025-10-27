import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/app_cubit.dart';
import '../bloc/auth_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../utils/responsive.dart';

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

  void _resetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().createPassword(
            _passController.text.trim(),
            _confirmController.text.trim(),
          );
    }
  }

  /// Improved back behavior:
  /// - If Navigator can pop, pop as usual.
  /// - If there's nothing to pop to (popping would reveal a blank/black screen),
  ///   try to use AppCubit to navigate to a safe app state (e.g., Auth screen).
  /// - If AppCubit is not available, do nothing (prevents showing a black screen).
  Future<void> _back() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final didPop = await navigator.maybePop();
    if (didPop) {
      return;
    }

    try {
      final appCubit = context.read<AppCubit>();
      appCubit.showAuth();
    } on ProviderNotFoundException {
      // If AppCubit is not available in the widget tree, just stay on the
      // current screen instead of navigating to a blank page.
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
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F9FC),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: responsive.scale(22),
          ),
          onPressed: _back,
        ),
        title: Text(
          l.createPasswordTitle,
          style: TextStyle(
            color: Colors.black,
            fontSize: responsive.scaleText(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.scaledSymmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: responsive.scale(24)),
                Text(
                  l.newPasswordLabel,
                  style: TextStyle(
                    fontSize: responsive.scaleText(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsive.scale(8)),
                TextFormField(
                  controller: _passController,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: l.newPasswordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                        size: responsive.scale(20),
                      ),
                      onPressed: () {
                        setState(() => _obscurePass = !_obscurePass);
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(responsive.scale(12)),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(responsive.scale(12)),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    final password = value?.trim() ?? '';
                    if (password.isEmpty) {
                      return l.passwordRequired;
                    }
                    if (password.length < 6) {
                      return l.passwordMinEight;
                    }
                    return null;
                  },
                ),
                SizedBox(height: responsive.scale(16)),
                Text(
                  l.confirmPasswordLabel,
                  style: TextStyle(
                    fontSize: responsive.scaleText(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsive.scale(8)),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _resetPassword(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: l.confirmPasswordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                        size: responsive.scale(20),
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(responsive.scale(12)),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(responsive.scale(12)),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    final confirmPassword = value?.trim() ?? '';
                    if (confirmPassword.isEmpty) {
                      return l.passwordRequired;
                    }
                    if (confirmPassword.length < 6) {
                      return l.passwordMinEight;
                    }
                    if (confirmPassword != _passController.text.trim()) {
                      return l.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                SizedBox(height: responsive.scale(30)),
                SizedBox(
                  width: double.infinity,
                  height: responsive.scale(55),
                  child: ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(responsive.scale(30)),
                      ),
                    ),
                    child: Text(
                      l.resetPasswordButton,
                      style: TextStyle(
                        fontSize: responsive.scaleText(18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.scale(16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



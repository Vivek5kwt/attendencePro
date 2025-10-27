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
import '../data/country_codes.dart';

enum _LoginMode { phone, email }

class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({Key? key}) : super(key: key);

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  _LoginMode _loginMode = _LoginMode.phone;
  late final List<CountryCodeOption> _countryCodeOptions;
  late CountryCodeOption _selectedCountry;
  String _selectedCountryCode = '+39';

  @override
  void initState() {
    super.initState();
    _countryCodeOptions = CountryCodes.all;
    final languageCode = context.read<LocaleCubit>().state.languageCode;
    if (languageCode == 'hi' || languageCode == 'pa') {
      _selectedCountryCode = '+91';
    } else if (languageCode == 'en') {
      _selectedCountryCode = '+1';
    } else {
      _selectedCountryCode = '+39';
    }
    _selectedCountry = _countryCodeOptions.firstWhere(
      (country) => country.dialCode == _selectedCountryCode,
      orElse: () => _countryCodeOptions.first,
    );
    _selectedCountryCode = _selectedCountry.dialCode;
  }

  void _submitLogin(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rawLoginValue = _loginController.text.trim();
    final password = _passwordController.text;
    final isPhoneMode = _loginMode == _LoginMode.phone;

    if (rawLoginValue.isEmpty) {
      _showSnack(isPhoneMode ? l.snackEnterPhone : l.snackEnterEmail);
      return;
    }

    final preparedLoginValue = _prepareLoginValue(rawLoginValue);
    if (preparedLoginValue == null) {
      _showSnack(
          isPhoneMode ? l.snackEnterValidPhone : l.snackEnterValidEmail);
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

  void _updateLoginMode(_LoginMode mode) {
    if (_loginMode == mode) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loginMode = mode;
      _loginController.clear();
    });
  }

  String? _prepareLoginValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (_loginMode == _LoginMode.email) {
      return _isValidEmail(trimmed) ? trimmed : null;
    }

    final normalizedPhone = _normalizePhone(trimmed);
    if (normalizedPhone == null) {
      return null;
    }

    return _isValidPhone(normalizedPhone) ? normalizedPhone : null;
  }

  Widget _buildLoginModeSelector(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.transparent),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _buildLoginModeButton(l.loginPhoneTab, _LoginMode.phone),
          ),
          Expanded(
            child: _buildLoginModeButton(l.loginEmailTab, _LoginMode.email),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginModeButton(String label, _LoginMode mode) {
    final isSelected = _loginMode == mode;
    return GestureDetector(
      onTap: () => _updateLoginMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x33007BFF),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? const Color(0xFF007BFF) : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLoginField(String hint) {
    final dialCodeStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        );

    return Row(
      children: [
        _buildCountrySelector(dialCodeStyle),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _loginController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: Colors.black38,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailLoginField(String hint) {
    return TextField(
      controller: _loginController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Colors.black38,
        ),
      ),
    );
  }

  Widget _buildCountrySelector(TextStyle dialCodeStyle) {
    return SizedBox(
      width: 118,
      child: GestureDetector(
        onTap: _showCountryPicker,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD9E2EF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(
                countryFlag(_selectedCountry.isoCode),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _selectedCountryCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dialCodeStyle,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCountryPicker() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<CountryCodeOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _countryCodeOptions.where((country) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return country.name.toLowerCase().contains(q) ||
                  country.dialCode.contains(query) ||
                  country.isoCode.toLowerCase().contains(q);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: l.searchCountryCodes,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          onChanged: (value) => setModalState(() {
                            query = value.trim();
                          }),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Text(
                                    l.noCountryCodeResults,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                itemBuilder: (context, index) {
                                  final country = filtered[index];
                                  final isActive =
                                      country.dialCode == _selectedCountryCode;
                                  return ListTile(
                                    onTap: () =>
                                        Navigator.of(sheetContext).pop(country),
                                    leading: Text(
                                      countryFlag(country.isoCode),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    title: Text(country.name),
                                    subtitle: Text(country.dialCode),
                                    trailing: isActive
                                        ? const Icon(Icons.check,
                                            color: Color(0xFF007BFF))
                                        : null,
                                  );
                                },
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  indent: 72,
                                ),
                                itemCount: filtered.length,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedCountry = selected;
      _selectedCountryCode = selected.dialCode;
    });
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
    if (digitsOnly.isEmpty) {
      return null;
    }

    final countryDigits =
        _selectedCountryCode.replaceAll(RegExp(r'\D'), '').trim();

    if (countryDigits.isEmpty) {
      return digitsOnly;
    }

    return '+$countryDigits$digitsOnly';
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
    final isPhoneMode = _loginMode == _LoginMode.phone;
    final loginLabel =
        isPhoneMode ? l.loginPhoneLabel : l.loginEmailLabel;
    final loginHint = isPhoneMode ? l.loginPhoneHint : l.loginEmailHint;
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
                    const SizedBox(height: 24),
                    _buildLoginModeSelector(l),
                    const SizedBox(height: 32),
                    Text(
                      loginLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    isPhoneMode
                        ? _buildPhoneLoginField(loginHint)
                        : _buildEmailLoginField(loginHint),
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

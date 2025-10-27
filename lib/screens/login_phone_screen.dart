import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/locale_cubit.dart';
import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../core/navigation/routes.dart';
import '../utils/responsive.dart';
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
    _selectedCountry = _countryCodeOptions.firstWhere(
      (country) => country.isoCode == 'IT',
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
    final responsive = context.responsive;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        borderRadius: BorderRadius.circular(responsive.scale(32)),
        border: Border.all(color: Colors.transparent),
      ),
      padding: EdgeInsets.all(responsive.scale(6)),
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
    final responsive = context.responsive;
    return GestureDetector(
      onTap: () => _updateLoginMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        height: responsive.scale(44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.scale(26)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0x33007BFF),
                    blurRadius: responsive.scale(12),
                    offset: Offset(0, responsive.scale(6)),
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
            fontSize: responsive.scaleText(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLoginField(String hint) {
    final responsive = context.responsive;
    final dialCodeStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: Colors.black87,
          fontSize: responsive.scaleText(
            Theme.of(context).textTheme.titleMedium?.fontSize ?? 16,
          ),
        ) ??
        TextStyle(
          fontWeight: FontWeight.w400,
          color: Colors.black87,
          fontSize: responsive.scaleText(16),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.scale(36)),
        border: Border.all(color: const Color(0xFFD9E2EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: responsive.scale(12),
            offset: Offset(0, responsive.scale(4)),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(12),
        vertical: responsive.scale(6),
      ),
      child: Row(
        children: [
          _buildCountrySelector(dialCodeStyle),
          SizedBox(width: responsive.scale(12)),
          Container(
            width: responsive.scale(1),
            height: responsive.scale(32),
            color: const Color(0xFFE5E7EB),
          ),
          SizedBox(width: responsive.scale(12)),
          Expanded(
            child: TextField(
              controller: _loginController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: responsive.scaleText(16),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: responsive.scale(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailLoginField(String hint) {
    final responsive = context.responsive;
    return TextField(
      controller: _loginController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.black38,
          fontSize: responsive.scaleText(16),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: responsive.scale(16),
          vertical: responsive.scale(14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.scale(32)),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: Colors.black38,
          size: responsive.scale(20),
        ),
      ),
    );
  }

  Widget _buildCountrySelector(TextStyle dialCodeStyle) {
    final responsive = context.responsive;
    return InkWell(
      onTap: _showCountryPicker,
      borderRadius: BorderRadius.circular(responsive.scale(32)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.scale(4),
          vertical: responsive.scale(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: responsive.scale(12),
              height: responsive.scale(12),
              alignment: Alignment.center,
              child: Image.asset(
                AppAssets.dropDownIcon,
                width: responsive.scale(12),
                height: responsive.scale(12),
              ),
            ),
            SizedBox(width: responsive.scale(8)),
            Text(
              countryFlag(_selectedCountry.isoCode),
              style: TextStyle(fontSize: responsive.scaleText(20)),
            ),
            SizedBox(width: responsive.scale(6)),
            Text(
              _selectedCountryCode,
              style: dialCodeStyle,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCountryPicker() async {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<CountryCodeOption>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(responsive.scale(16))),
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
                  height:
                      MediaQuery.of(context).size.height * (responsive.scale(0.75)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: responsive.scale(36),
                        height: responsive.scale(4),
                        margin: EdgeInsets.symmetric(
                          vertical: responsive.scale(12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius:
                              BorderRadius.circular(responsive.scale(2)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.scale(20),
                          vertical: responsive.scale(8),
                        ),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: l.searchCountryCodes,
                            prefixIcon: Icon(
                              Icons.search,
                              size: responsive.scale(20),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                responsive.scale(28),
                              ),
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
                      SizedBox(height: responsive.scale(4)),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: responsive.scale(24)),
                                  child: Text(
                                    l.noCountryCodeResults,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(
                                    horizontal: responsive.scale(12),
                                    vertical: responsive.scale(8)),
                                itemBuilder: (context, index) {
                                  final country = filtered[index];
                                  final isActive =
                                      country.isoCode == _selectedCountry.isoCode;
                                  return ListTile(
                                    onTap: () =>
                                        Navigator.of(sheetContext).pop(country),
                                    leading: Text(
                                      countryFlag(country.isoCode),
                                      style: TextStyle(
                                        fontSize: responsive.scaleText(20),
                                      ),
                                    ),
                                    title: Text(
                                      country.name,
                                      style: TextStyle(
                                        fontSize: responsive.scaleText(16),
                                      ),
                                    ),
                                    subtitle: Text(
                                      country.dialCode,
                                      style: TextStyle(
                                        fontSize: responsive.scaleText(14),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    trailing: isActive
                                        ? Icon(
                                            Icons.check,
                                            color: const Color(0xFF007BFF),
                                            size: responsive.scale(20),
                                          )
                                        : null,
                                  );
                                },
                                separatorBuilder: (_, __) => Divider(
                                  height: responsive.scale(1),
                                  indent: responsive.scale(72),
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
    final responsive = context.responsive;
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
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.scale(24),
                  vertical: responsive.scale(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.scale(10)),
                    Center(
                      child: Text(
                        l.loginTitle,
                        style: TextStyle(
                          fontSize: responsive.scaleText(28),
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.scale(24)),
                    _buildLoginModeSelector(l),
                    SizedBox(height: responsive.scale(32)),
                    Text(
                      loginLabel,
                      style: TextStyle(
                        fontSize: responsive.scaleText(15),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: responsive.scale(8)),
                    isPhoneMode
                        ? _buildPhoneLoginField(loginHint)
                        : _buildEmailLoginField(loginHint),
                    SizedBox(height: responsive.scale(20)),
                    Text(
                      l.passwordLabel,
                      style: TextStyle(
                        fontSize: responsive.scaleText(15),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: responsive.scale(8)),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: l.passwordHint,
                        hintStyle: TextStyle(
                          color: Colors.black26,
                          fontSize: responsive.scaleText(14),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: responsive.scale(16),
                          vertical: responsive.scale(14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(responsive.scale(32)),
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
                    SizedBox(height: responsive.scale(20)),
                    BlocBuilder<AuthCubit, AuthState>(
                      buildWhen: (previous, current) =>
                          previous is AuthLoading || current is AuthLoading,
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
                            onPressed: isProcessing
                                ? null
                                : () => _submitLogin(context),
                            child: Text(
                              l.loginButton,
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
                    SizedBox(height: responsive.scale(20)),
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
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: responsive.scaleText(14),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.scale(8)),
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
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: responsive.scaleText(14),
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: l.signupPromptAction,
                                style: TextStyle(
                                  fontSize: responsive.scaleText(14),
                                  color: Color(0xFF007BFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.scale(40)),
                    Center(
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(responsive.scale(24)),
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
                            Image.asset(
                              AppAssets.language,
                              height: responsive.scale(28),
                              width: responsive.scale(28),
                            ),
                            SizedBox(width: responsive.scale(8)),
                            Text(
                              l.changeLanguage,
                              style: TextStyle(
                                fontSize: responsive.scaleText(14),
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
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

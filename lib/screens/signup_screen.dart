import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/locale_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../data/country_codes.dart';
import '../data/phone_number_metadata.dart';
import 'policy_screen.dart';
import '../utils/responsive.dart';
import '../utils/snackbar.dart';
import '../widgets/primary_cta_button.dart';

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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _countrySearchController = TextEditingController();
  final FocusNode _countrySearchFocusNode = FocusNode();

  late final List<CountryCodeOption> _countryCodeOptions;
  late CountryCodeOption _selectedCountry;
  String _selectedCountryCode = '+39';
  late String _selectedLanguage;
  bool _showInlineCountryPicker = false;
  String _countrySearchQuery = '';

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _agreed = false;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _countryCodeOptions = CountryCodes.all;
    _selectedLanguage = context.read<LocaleCubit>().state.languageCode;
    if (!const ['en', 'hi', 'pa', 'it'].contains(_selectedLanguage)) {
      _selectedLanguage = 'en';
    }
    _selectedCountry = _countryCodeOptions.firstWhere(
      (country) => country.isoCode == 'IT',
      orElse: () => _countryCodeOptions.first,
    );
    _selectedCountryCode = _selectedCountry.dialCode;
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
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _countrySearchController.dispose();
    _countrySearchFocusNode.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _submitSignup() {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreed) {
      _showSnack(l.termsAgreement);
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final countryCode = _selectedCountryCode;
    final language = _resolveLanguage();

    context.read<AuthCubit>().register(
      name: name,
      email: email,
      password: password,
      confirm: confirm,
      phone: phone,
      countryCode: countryCode,
      language: language,
    );
  }

  String _resolveLanguage() {
    const supported = {'en', 'hi', 'pa', 'it'};
    return supported.contains(_selectedLanguage) ? _selectedLanguage : 'en';
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

  void _showSnack(String message) {
    if (!mounted) return;
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;
    final languageOptions = <String, String>{
      'en': l.languageEnglish,
      'hi': l.languageHindi,
      'pa': l.languagePunjabi,
      'it': l.languageItalian,
    };
    final selectedLanguage = _resolveLanguage();
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state is AuthError) {
          _showSnack(state.message);
        } else if (state is AuthAuthenticated) {
          final msg = state.data?['message'] ??
              state.data?['status'] ??
              AppLocalizations.of(context).operationSuccessful;
          _showSnack(msg);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.scale(24),
              vertical: responsive.scale(10),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        size: responsive.scale(24),
                      ),
                      color: Colors.black87,
                      onPressed: () =>
                          context.read<AuthCubit>().showPhone(isSignup: false),
                    ),
                  ),
                  SizedBox(height: responsive.scale(10)),
                  Text(
                    l.signupTitle,
                    style: TextStyle(
                      fontSize: responsive.scaleText(28),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: responsive.scale(40)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.fullNameLabel,
                      style: TextStyle(
                        fontSize: responsive.scaleText(16),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.scale(8)),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(l.fullNameLabel, responsive),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.nameRequired
                        : null,
                  ),
                  SizedBox(height: responsive.scale(20)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.emailAddressLabel,
                      style: TextStyle(
                        fontSize: responsive.scaleText(16),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.scale(8)),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        _inputDecoration(l.emailAddressLabel, responsive),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l.emailRequired;
                      final email = v.trim();
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email))
                        return l.emailInvalid;
                      return null;
                    },
                  ),
                  SizedBox(height: responsive.scale(20)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.phoneNumberLabel,
                      style: TextStyle(
                        fontSize: responsive.scaleText(16),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.scale(8)),
                  _buildPhoneNumberField(l, responsive),
                  SizedBox(height: responsive.scale(20)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.languageLabel,
                      style: TextStyle(
                        fontSize: responsive.scaleText(16),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.scale(8)),
                  DropdownButtonFormField<String>(
                    value: selectedLanguage,
                    decoration: _inputDecoration(l.languageLabel, responsive),
                    items: languageOptions.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style:
                                  TextStyle(fontSize: responsive.scaleText(16)),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                  ),
                  SizedBox(height: responsive.scale(20)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.passwordLabel,
                      style: TextStyle(
                        fontSize: responsive.scaleText(16),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.scale(8)),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration:
                        _inputDecoration(l.passwordLabel, responsive).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                          size: responsive.scale(22),
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
                  SizedBox(height: responsive.scale(20)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.confirmPasswordLabel,
                      style: TextStyle(
                        fontSize: responsive.scaleText(16),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.scale(8)),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: !_confirmVisible,
                    decoration:
                        _inputDecoration(l.confirmPasswordLabel, responsive)
                            .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                          size: responsive.scale(22),
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
                  SizedBox(height: responsive.scale(20)),
                  Row(
                    children: [
                      Checkbox(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(responsive.scale(4))),
                        activeColor: const Color(0xFF007BFF),
                        value: _agreed,
                        onChanged: (v) =>
                            setState(() => _agreed = v ?? false),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: l.agreeTextPrefix,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: responsive.scaleText(14),
                            ),
                            children: [
                              TextSpan(
                                text: l.userAgreement,
                                style: TextStyle(
                                  color: const Color(0xFF007BFF),
                                  fontSize: responsive.scaleText(14),
                                ),
                                recognizer: _termsRecognizer,
                              ),
                              TextSpan(
                                text: l.and,
                                style:
                                    TextStyle(fontSize: responsive.scaleText(14)),
                              ),
                              TextSpan(
                                text: l.privacyPolicy,
                                style: TextStyle(
                                  color: const Color(0xFF007BFF),
                                  fontSize: responsive.scaleText(14),
                                ),
                                recognizer: _privacyRecognizer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.scale(25)),
                  BlocBuilder<AuthCubit, AuthState>(
                    buildWhen: (previous, current) =>
                        previous is AuthLoading || current is AuthLoading,
                    builder: (context, state) {
                      final isProcessing = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: PrimaryCtaButton(
                          label: l.signupButton,
                          height: responsive.scale(56),
                          isLoading: isProcessing,
                          onPressed: isProcessing ? null : _submitSignup,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: responsive.scale(25)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.alreadyAccountPrompt,
                        style: TextStyle(fontSize: responsive.scaleText(14)),
                      ),
                      GestureDetector(
                        onTap: () =>
                            context.read<AuthCubit>().showPhone(isSignup: false),
                        child: Text(
                          l.loginAction,
                          style: TextStyle(
                            color: const Color(0xFF007BFF),
                            fontWeight: FontWeight.w500,
                            fontSize: responsive.scaleText(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.scale(20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField(
      AppLocalizations l, Responsive responsive) {
    final dialCodeStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: Colors.black87,
          fontSize: responsive.scaleText(
              Theme.of(context).textTheme.titleMedium?.fontSize ?? 16),
        ) ??
        TextStyle(
          fontWeight: FontWeight.w400,
          color: Colors.black87,
          fontSize: responsive.scaleText(16),
        );

    final metadata = metadataForDialCode(_selectedCountry.dialCode);
    return TapRegion(
      onTapOutside: (_) => _closeInlineCountryPicker(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                _buildCountrySelector(dialCodeStyle, responsive),
                SizedBox(width: responsive.scale(12)),
                Container(
                  width: responsive.scale(1),
                  height: responsive.scale(32),
                  color: const Color(0xFFE5E7EB),
                ),
                SizedBox(width: responsive.scale(12)),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(metadata.maxLength),
                    ],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: responsive.scale(12),
                      ),
                      hintText: l.phoneNumberHint,
                      hintStyle: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: responsive.scaleText(16),
                      ),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return l.phoneRequired;
                      if (trimmed.length < metadata.minLength ||
                          trimmed.length > metadata.maxLength) {
                        return l.phoneInvalid;
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
                        return l.phoneInvalid;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: _showInlineCountryPicker
                ? _buildInlineCountryPicker(l, responsive)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySelector(TextStyle dialCodeStyle, Responsive responsive) {
    return InkWell(
      onTap: _toggleInlineCountryPicker,
      borderRadius: BorderRadius.circular(responsive.scale(32)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.scale(4),
          vertical: responsive.scale(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _showInlineCountryPicker ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: responsive.scale(20),
                color: const Color(0xFF007BFF),
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

  void _toggleInlineCountryPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showInlineCountryPicker = !_showInlineCountryPicker;
      if (!_showInlineCountryPicker) {
        _countrySearchQuery = '';
        _countrySearchController.clear();
      }
    });
    if (_showInlineCountryPicker) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _countrySearchFocusNode.requestFocus();
        }
      });
    }
  }

  void _closeInlineCountryPicker() {
    if (!_showInlineCountryPicker) return;
    setState(() {
      _showInlineCountryPicker = false;
      _countrySearchQuery = '';
      _countrySearchController.clear();
    });
  }

  void _onCountrySearchChanged(String value) {
    setState(() {
      _countrySearchQuery = value.trim();
    });
  }

  List<CountryCodeOption> get _visibleCountryOptions {
    if (_countrySearchQuery.isEmpty) {
      return _countryCodeOptions;
    }
    final query = _countrySearchQuery.toLowerCase();
    return _countryCodeOptions.where((country) {
      final name = country.name.toLowerCase();
      return name.contains(query) ||
          country.dialCode.contains(_countrySearchQuery) ||
          country.isoCode.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildInlineCountryPicker(
      AppLocalizations l, Responsive responsive) {
    final filtered = _visibleCountryOptions;
    return Container(
      key: const ValueKey('signup-inline-country-picker'),
      width: double.infinity,
      margin: EdgeInsets.only(top: responsive.scale(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.scale(24)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: responsive.scale(16),
            offset: Offset(0, responsive.scale(8)),
          ),
        ],
      ),
      padding: EdgeInsets.all(responsive.scale(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _countrySearchController,
            focusNode: _countrySearchFocusNode,
            onChanged: _onCountrySearchChanged,
            decoration: InputDecoration(
              hintText: l.searchCountryCodes,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade600,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.scale(12),
                vertical: responsive.scale(12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.scale(16)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: responsive.scale(12)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: responsive.scale(260),
            ),
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: responsive.scale(24)),
                      child: Text(
                        l.noCountryCodeResults,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final country = filtered[index];
                      final isActive =
                          country.isoCode == _selectedCountry.isoCode;
                      return InkWell(
                        onTap: () => _handleCountrySelected(country),
                        borderRadius:
                            BorderRadius.circular(responsive.scale(16)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.scale(10),
                            horizontal: responsive.scale(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                countryFlag(country.isoCode),
                                style: TextStyle(
                                  fontSize: responsive.scaleText(20),
                                ),
                              ),
                              SizedBox(width: responsive.scale(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      country.name,
                                      style: TextStyle(
                                        fontSize: responsive.scaleText(16),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: responsive.scale(2)),
                                    Text(
                                      country.dialCode,
                                      style: TextStyle(
                                        fontSize: responsive.scaleText(14),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF22C55E),
                                  size: responsive.scale(20),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => Divider(
                      height: responsive.scale(1),
                      color: const Color(0xFFE5E7EB),
                    ),
                    itemCount: filtered.length,
                  ),
          ),
        ],
      ),
    );
  }

  void _handleCountrySelected(CountryCodeOption selected) {
    final metadata = metadataForDialCode(selected.dialCode);
    setState(() {
      _selectedCountry = selected;
      _selectedCountryCode = selected.dialCode;
      _showInlineCountryPicker = false;
      _countrySearchQuery = '';
      _countrySearchController.clear();
      final current = _phoneController.text;
      if (current.length > metadata.maxLength) {
        final truncated = current.substring(0, metadata.maxLength);
        _phoneController
          ..text = truncated
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: truncated.length),
          );
      }
    });
  }

  InputDecoration _inputDecoration(String hint, Responsive responsive) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.scale(20),
        vertical: responsive.scale(16),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.scale(30)),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.scale(30)),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.scale(30)),
        borderSide: const BorderSide(color: Color(0xFF007BFF)),
      ),
    );
  }
}

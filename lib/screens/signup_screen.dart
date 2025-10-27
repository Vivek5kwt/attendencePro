import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/locale_cubit.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../data/country_codes.dart';
import 'policy_screen.dart';
import '../utils/responsive.dart';

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

  late final List<CountryCodeOption> _countryCodeOptions;
  late CountryCodeOption _selectedCountry;
  String _selectedCountryCode = '+39';
  late String _selectedLanguage;

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
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _submitSignup() {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreed) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l.termsAgreement)),
      );
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
        final messenger = ScaffoldMessenger.of(context);
        if (state is AuthError) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthAuthenticated) {
          final msg = state.data?['message'] ??
              state.data?['status'] ??
              AppLocalizations.of(context).operationSuccessful;
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text(msg)),
          );
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
                        height: responsive.scale(52),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(responsive.scale(30)),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isProcessing ? null : _submitSignup,
                          child: Text(
                            l.signupButton,
                            style: TextStyle(
                              fontSize: responsive.scaleText(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                if (trimmed.length < 6 || trimmed.length > 15) {
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
    );
  }

  Widget _buildCountrySelector(TextStyle dialCodeStyle, Responsive responsive) {
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
                      MediaQuery.of(context).size.height * responsive.scale(0.75),
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

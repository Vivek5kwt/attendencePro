import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/locale_cubit.dart';
import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../core/localization/app_localizations.dart';
import '../repositories/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController();

  late final UserRepository _repository;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _languageCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = UserRepository();
    _languageCode = context.read<LocaleCubit>().state.languageCode;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repository.loadProfile();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _nameController.text = profile.name ?? '';
        _usernameController.text = profile.username ?? '';
        _phoneController.text = profile.phone ?? '';
        _countryCodeController.text = profile.countryCode ?? '';
        if ((profile.language ?? '').isNotEmpty) {
          _languageCode = profile.language;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context).profileLoadingFailed;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final l = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final countryCode = _countryCodeController.text.trim();
    final languageCode = _languageCode?.trim();

    if (languageCode == null || languageCode.isEmpty) {
      setState(() {
        _errorMessage = l.profileValidationLanguage;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await _repository.updateProfile(
        name: name,
        username: username,
        phone: phone,
        countryCode: countryCode,
        language: languageCode,
      );

      if (!mounted) return;

      final localeToApply = updated.language ?? languageCode;
      context.read<LocaleCubit>().setLocale(Locale(localeToApply));
      context.read<WorkBloc>().add(const WorkProfileRefreshed());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.profileUpdateSuccess)),
      );

      setState(() {
        _isSaving = false;
      });
    } on UserAuthException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = l.profileAuthRequired;
      });
    } on UserRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.message.isNotEmpty ? e.message : l.profileUpdateFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = l.profileUpdateFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final languageOptions = {
      'en': l.languageEnglish,
      'hi': l.languageHindi,
      'pa': l.languagePunjabi,
      'it': l.languageItalian,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.alphaBlend(
                      colorScheme.primary.withOpacity(0.08),
                      colorScheme.surface,
                    ),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Form(
                        key: _formKey,
                        child: AbsorbPointer(
                          absorbing: _isSaving,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ProfileHeader(
                                title: l.profileTitle,
                                subtitle: l.profileLabel,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                              ),
                              const SizedBox(height: 24),
                              Material(
                                elevation: 3,
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        child: _errorMessage == null
                                            ? const SizedBox.shrink()
                                            : _ErrorBanner(
                                                message: _errorMessage!,
                                              ),
                                      ),
                                      if (_errorMessage != null)
                                        const SizedBox(height: 12),
                                      _ProfileField(
                                        controller: _nameController,
                                        label: l.profileNameLabel,
                                        hint: l.profileNameHint,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return l.profileValidationName;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      _ProfileField(
                                        controller: _usernameController,
                                        label: l.profileUsernameLabel,
                                        hint: l.profileUsernameHint,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return l.profileValidationUsername;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      _ProfileField(
                                        controller: _phoneController,
                                        label: l.profilePhoneLabel,
                                        hint: l.profilePhoneHint,
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return l.profileValidationPhone;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      _ProfileField(
                                        controller: _countryCodeController,
                                        label: l.profileCountryCodeLabel,
                                        hint: l.profileCountryCodeHint,
                                        keyboardType: TextInputType.text,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return l.profileValidationCountryCode;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        l.profileLanguageLabel,
                                        style: textTheme.labelLarge?.copyWith(
                                              color: textTheme
                                                      .labelLarge?.color ??
                                                  theme
                                                      .textTheme.bodyMedium?.color,
                                              fontWeight: FontWeight.w600,
                                            ) ??
                                            const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _languageCode,
                                        items: languageOptions.entries
                                            .map(
                                              (entry) => DropdownMenuItem<
                                                  String>(
                                                value: entry.key,
                                                child: Text(entry.value),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _languageCode = value;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Color.alphaBlend(
                                            colorScheme.primary
                                                .withOpacity(0.04),
                                            colorScheme.surface,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.expand_more_rounded,
                                          color: colorScheme.primary,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return l.profileValidationLanguage;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 28),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isSaving ? null : _submit,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            textStyle:
                                                textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          child: _isSaving
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text(l.profileSaveButton),
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
                ),
              ),
            ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.validator,
    this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Color.alphaBlend(
              colorScheme.primary.withOpacity(0.04),
              colorScheme.surface,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.6,
              ),
            ),
          ),
          validator: validator,
          style: textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.textTheme,
  });

  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                Color.alphaBlend(
                  colorScheme.primary.withOpacity(0.4),
                  colorScheme.surface,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.person_rounded,
            size: 32,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ??
                    const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                      color: textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ) ??
                    TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: ValueKey(message),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

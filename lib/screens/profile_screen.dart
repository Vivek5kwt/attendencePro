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
    final languageOptions = {
      'en': l.languageEnglish,
      'hi': l.languageHindi,
      'pa': l.languagePunjabi,
      'it': l.languageItalian,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: AbsorbPointer(
                    absorbing: _isSaving,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFF3B30),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        _ProfileField(
                          controller: _nameController,
                          label: l.profileNameLabel,
                          hint: l.profileNameHint,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l.profileValidationName;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          controller: _usernameController,
                          label: l.profileUsernameLabel,
                          hint: l.profileUsernameHint,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l.profileValidationUsername;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          controller: _phoneController,
                          label: l.profilePhoneLabel,
                          hint: l.profilePhoneHint,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l.profileValidationPhone;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          controller: _countryCodeController,
                          label: l.profileCountryCodeLabel,
                          hint: l.profileCountryCodeHint,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l.profileValidationCountryCode;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.profileLanguageLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _languageCode,
                          items: languageOptions.entries
                              .map(
                                (entry) => DropdownMenuItem<String>(
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
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l.profileValidationLanguage;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    l.profileSaveButton,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

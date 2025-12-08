import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/locale_cubit.dart';
import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../core/localization/app_localizations.dart';
import '../data/country_codes.dart';
import '../repositories/user_repository.dart';
import '../utils/snackbar.dart';
import '../widgets/app_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _countrySearchController = TextEditingController();
  final FocusNode _countrySearchFocusNode = FocusNode();

  late final List<CountryCodeOption> _countryCodeOptions;
  late CountryCodeOption _selectedCountry;

  late final UserRepository _repository;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _languageCode;
  String? _errorMessage;
  bool _showInlineCountryPicker = false;
  String _countrySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = UserRepository();
    _countryCodeOptions = CountryCodes.all;
    _selectedCountry = _countryCodeOptions.firstWhere(
      (country) => country.isoCode == 'IT',
      orElse: () => _countryCodeOptions.first,
    );
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
        if (profile.countryCode != null && profile.countryCode!.isNotEmpty) {
          _selectedCountry = _countryCodeOptions.firstWhere(
            (country) => country.dialCode == profile.countryCode,
            orElse: () => _selectedCountry,
          );
          _countryCodeController.text = _selectedCountry.dialCode;
        } else {
          _countryCodeController.text = _selectedCountry.dialCode;
        }
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
    _countrySearchController.dispose();
    _countrySearchFocusNode.dispose();
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

      AppSnackBar.show(context, l.profileUpdateSuccess);

      setState(() {
        _isSaving = false;
      });

      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;
      await Navigator.of(context).maybePop(true);
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

  void _handleCountrySelected(CountryCodeOption country) {
    setState(() {
      _selectedCountry = country;
      _countryCodeController.text = country.dialCode;
      _showInlineCountryPicker = false;
      _countrySearchQuery = '';
      _countrySearchController.clear();
    });
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
        title: Text(l.profileTitle,style: TextStyle(color: Colors.white),),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: AppLoader())
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
                                      _CountryCodePicker(
                                        label: l.profileCountryCodeLabel,
                                        hint: l.profileCountryCodeHint,
                                        selectedCountry: _selectedCountry,
                                        countryCodeController:
                                            _countryCodeController,
                                        countrySearchController:
                                            _countrySearchController,
                                        countrySearchFocusNode:
                                            _countrySearchFocusNode,
                                        countryOptions: _countryCodeOptions,
                                        showInlinePicker:
                                            _showInlineCountryPicker,
                                        onTogglePicker: _toggleInlineCountryPicker,
                                        onClosePicker: _closeInlineCountryPicker,
                                        onSearchChanged: _onCountrySearchChanged,
                                        searchQuery: _countrySearchQuery,
                                        onCountrySelected: _handleCountrySelected,
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
                                                  child: AppLoader(size: 22),
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

class _CountryCodePicker extends StatelessWidget {
  const _CountryCodePicker({
    required this.label,
    required this.hint,
    required this.selectedCountry,
    required this.countryCodeController,
    required this.countrySearchController,
    required this.countrySearchFocusNode,
    required this.countryOptions,
    required this.showInlinePicker,
    required this.onTogglePicker,
    required this.onClosePicker,
    required this.onSearchChanged,
    required this.searchQuery,
    required this.onCountrySelected,
    required this.validator,
  });

  final String label;
  final String hint;
  final CountryCodeOption selectedCountry;
  final TextEditingController countryCodeController;
  final TextEditingController countrySearchController;
  final FocusNode countrySearchFocusNode;
  final List<CountryCodeOption> countryOptions;
  final bool showInlinePicker;
  final VoidCallback onTogglePicker;
  final VoidCallback onClosePicker;
  final ValueChanged<String> onSearchChanged;
  final String searchQuery;
  final ValueChanged<CountryCodeOption> onCountrySelected;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dialCodeStyle = textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return TapRegion(
      onTapOutside: (_) => onClosePicker(),
      child: Column(
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
          FormField<String>(
            initialValue: countryCodeController.text,
            validator: validator,
            builder: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onTogglePicker,
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          colorScheme.primary.withOpacity(0.04),
                          colorScheme.surface,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: state.hasError
                              ? colorScheme.error
                              : colorScheme.outline.withOpacity(0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  countryFlag(selectedCountry.isoCode),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(selectedCountry.dialCode, style: dialCodeStyle),
                              ],
                            ),
                            Icon(
                              showInlinePicker
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (showInlinePicker) ...[
                    const SizedBox(height: 12),
                    _InlineCountryPicker(
                      searchHint: hint,
                      searchController: countrySearchController,
                      searchFocusNode: countrySearchFocusNode,
                      onSearchChanged: onSearchChanged,
                      searchQuery: searchQuery,
                      countryOptions: countryOptions,
                      selectedCountry: selectedCountry,
                      onCountrySelected: (country) {
                        countryCodeController.text = country.dialCode;
                        state.didChange(country.dialCode);
                        onCountrySelected(country);
                      },
                    ),
                  ],
                  if (state.hasError) ...[
                    const SizedBox(height: 6),
                    Text(
                      state.errorText ?? '',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InlineCountryPicker extends StatelessWidget {
  const _InlineCountryPicker({
    required this.searchHint,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.searchQuery,
    required this.countryOptions,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  final String searchHint;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final String searchQuery;
  final List<CountryCodeOption> countryOptions;
  final CountryCodeOption selectedCountry;
  final ValueChanged<CountryCodeOption> onCountrySelected;

  List<CountryCodeOption> get _visibleCountryOptions {
    if (searchQuery.isEmpty) return countryOptions;
    final query = searchQuery.toLowerCase();
    return countryOptions.where((country) {
      final name = country.name.toLowerCase();
      return name.contains(query) ||
          country.dialCode.contains(searchQuery) ||
          country.isoCode.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filtered = _visibleCountryOptions;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Color.alphaBlend(
                colorScheme.primary.withOpacity(0.03),
                colorScheme.surface,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppLocalizations.of(context).noCountryCodeResults,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final country = filtered[index];
                      final isActive =
                          country.isoCode == selectedCountry.isoCode;
                      return InkWell(
                        onTap: () => onCountrySelected(country),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          child: Row(
                            children: [
                              Text(
                                countryFlag(country.isoCode),
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      country.name,
                                      style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ) ??
                                          const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      country.dialCode,
                                      style: textTheme.bodySmall?.copyWith(
                                            color: textTheme.bodySmall?.color
                                                ?.withOpacity(0.7),
                                          ) ??
                                          const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF22C55E),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                    itemCount: filtered.length,
                  ),
          ),
        ],
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

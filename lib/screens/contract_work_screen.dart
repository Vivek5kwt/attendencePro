import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_strings.dart';
import '../core/localization/app_localizations.dart';
import '../models/contract_type.dart' as models;
import '../repositories/contract_type_repository.dart';
import '../utils/responsive.dart';

class ContractWorkScreen extends StatefulWidget {
  const ContractWorkScreen({super.key});

  @override
  State<ContractWorkScreen> createState() => _ContractWorkScreenState();
}

class _ContractWorkScreenState extends State<ContractWorkScreen> {
  final ContractTypeRepository _repository = ContractTypeRepository();

  final List<_ContractType> _defaultContractTypes = <_ContractType>[];
  final List<_ContractType> _userContractTypes = <_ContractType>[];
  final List<String> _availableSubtypes = <String>[];
  static const List<String> _defaultSubtypeOptions = <String>[
    'Fixed',
    'Bundle',
  ];

  final List<_ContractEntry> _recentEntries = <_ContractEntry>[

  ];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContractTypes();
  }

  Future<void> _loadContractTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.fetchContractTypes();
      if (!mounted) return;
      setState(() {
        _defaultContractTypes
          ..clear()
          ..addAll(result.globalTypes
              .map((type) => _ContractType.fromModel(type: type)));
        _userContractTypes
          ..clear()
          ..addAll(result.userTypes.map((type) => _ContractType.fromModel(
                type: type,
                isUserDefined: true,
              )));
        _syncAvailableSubtypes();
        _isLoading = false;
      });
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  List<_ContractType> get _allContractTypes => <_ContractType>[
        ..._defaultContractTypes,
        ..._userContractTypes,
      ];

  void _upsertContractType(_ContractType type) {
    final targetList =
        type.isUserDefined ? _userContractTypes : _defaultContractTypes;
    final index = targetList.indexWhere((item) => item.id == type.id);
    setState(() {
      if (index == -1) {
        targetList.add(type);
      } else {
        targetList[index] = type;
      }
      _syncAvailableSubtypes();
    });
  }

  void _syncAvailableSubtypes() {
    final unique = <String, String>{};

    void addSubtype(String? rawValue) {
      final value = rawValue?.trim();
      if (value == null || value.isEmpty) {
        return;
      }
      final key = value.toLowerCase();
      unique.putIfAbsent(key, () => _formatSubtypeDisplay(value));
    }

    for (final type in _defaultContractTypes) {
      addSubtype(type.subtype);
    }
    for (final type in _userContractTypes) {
      addSubtype(type.subtype);
    }

    final sorted = unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _availableSubtypes
      ..clear()
      ..addAll(sorted);
  }

  String _formatSubtypeDisplay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    switch (trimmed.toLowerCase()) {
      case 'fixed':
        return 'Fixed';
      case 'bundle':
        return 'Bundle';
      default:
        return trimmed;
    }
  }

  void _removeContractType(_ContractType type) {
    setState(() {
      _userContractTypes.removeWhere((item) => item.id == type.id);
      _syncAvailableSubtypes();
    });
  }

  Future<bool?> _confirmDeleteContractType(_ContractType type) async {
    final l = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.contractWorkDeleteConfirmationTitle),
          content: Text(l.contractWorkDeleteConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
              child: Text(l.contractWorkDeleteButton),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return false;
    }

    try {
      await _repository.deleteContractType(id: type.id);
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) {
        return false;
      }
      final message = error.message.isEmpty
          ? l.contractWorkTypeDeleteFailedMessage
          : error.message;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.contractWorkTypeDeleteFailedMessage)),
      );
      return false;
    }

    if (!mounted) {
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.contractWorkTypeDeletedMessage)),
    );
    return true;
  }

  void _showComingSoonSnackBar(BuildContext context) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.helpSupportComingSoon)),
    );
  }

  double get _totalUnits =>
      _recentEntries.fold<double>(0, (sum, entry) => sum + entry.unitsCompleted);

  double get _totalContractSalary =>
      _recentEntries.fold<double>(0, (sum, entry) => sum + entry.totalAmount);


  Future<void> _showContractTypeDialog({
    _ContractType? type,
  }) async {
    final l = AppLocalizations.of(context);
    final rootContext = context;
    final nameController = TextEditingController(text: type?.name ?? '');
    final rateController =
        TextEditingController(text: type != null ? type.rate.toStringAsFixed(2) : '');
    final unitController =
        TextEditingController(text: type?.unitLabel ?? '');
    final isEditing = type != null;
    final isNameEditable = !(type?.isDefault ?? false);

    final seenSubtypeOptions = <String>{};
    final subtypeOptions = <String>[];

    void addSubtypeOption(String option, {bool prepend = false}) {
      final formatted = _formatSubtypeDisplay(option);
      if (formatted.isEmpty) {
        return;
      }
      final key = formatted.toLowerCase();
      if (seenSubtypeOptions.contains(key)) {
        if (prepend) {
          final existingIndex =
              subtypeOptions.indexWhere((item) => item.toLowerCase() == key);
          if (existingIndex > 0) {
            final existingValue = subtypeOptions.removeAt(existingIndex);
            subtypeOptions.insert(0, existingValue);
          }
        }
        return;
      }

      seenSubtypeOptions.add(key);
      if (prepend) {
        subtypeOptions.insert(0, formatted);
      } else {
        subtypeOptions.add(formatted);
      }
    }

    final existingSubtype = type?.subtype?.trim();
    final existingSubtypeDisplay =
        existingSubtype != null && existingSubtype.isNotEmpty
            ? _formatSubtypeDisplay(existingSubtype)
            : null;
    if (existingSubtypeDisplay != null) {
      addSubtypeOption(existingSubtypeDisplay, prepend: true);
    }

    for (final option in _defaultSubtypeOptions) {
      addSubtypeOption(option);
    }
    for (final option in _availableSubtypes) {
      addSubtypeOption(option);
    }

    String? selectedSubtypeValue = existingSubtypeDisplay;
    selectedSubtypeValue ??=
        subtypeOptions.isNotEmpty ? subtypeOptions.first : null;

    bool isSaving = false;
    bool isSelected = true;

    final result = await showModalBottomSheet<_ContractType>(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final mediaQuery = MediaQuery.of(context);
            final textTheme = Theme.of(context).textTheme;
            final headerTitle =
                isEditing ? l.contractWorkEditTypeTitle : l.contractWorkAddTypeTitle;
            final dropdownValue = (selectedSubtypeValue != null &&
                    subtypeOptions.contains(selectedSubtypeValue))
                ? selectedSubtypeValue
                : null;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: SafeArea(
                top: false,
                child: Container(
                  color: Colors.transparent,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: mediaQuery.size.height * 0.95,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Semantics(
                                button: true,
                                label: l.contractWorkCloseSheetLabel,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    Navigator.of(context).maybePop();
                                  },
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Container(
                                      width: 44,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1D5DB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7E6),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Text(
                                    '🤝',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        headerTitle,
                                        style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF111827),
                                            ) ??
                                            const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF111827),
                                              fontSize: 18,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l.contractWorkSetupSubtitle,
                                        style: textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFF6B7280),
                                            ) ??
                                            const TextStyle(
                                              color: Color(0xFF6B7280),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x10000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Transform.translate(
                                        offset: const Offset(-4, 0),
                                        child: Checkbox(
                                          value: isSelected,
                                          activeColor: const Color(0xFF2563EB),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          onChanged: (value) {
                                            setSheetState(() {
                                              isSelected = value ?? true;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF9FAFB),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(0xFFE5E7EB),
                                                ),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFF1F2),
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      '📦',
                                                      style: TextStyle(fontSize: 20),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: nameController,
                                                      enabled: isNameEditable,
                                                      decoration: InputDecoration(
                                                        border: InputBorder.none,
                                                        hintText: AppString.contractNameHint,
                                                        hintStyle: textTheme.bodyMedium?.copyWith(
                                                              color: const Color(0xFF9CA3AF),
                                                            ) ??
                                                            const TextStyle(
                                                              color: Color(0xFF9CA3AF),
                                                            ),
                                                      ),
                                                      style: textTheme.bodyLarge?.copyWith(
                                                            fontWeight: FontWeight.w600,
                                                            color: const Color(0xFF111827),
                                                          ) ??
                                                          const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF111827),
                                                            fontSize: 16,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            Text(
                                              l.contractWorkContractTypeLabel,
                                              style: textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF1F2937),
                                                  ) ??
                                                  const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                            ),
                                            const SizedBox(height: 10),
                                            DropdownButtonFormField<String>(
                                              value: dropdownValue,
                                              items: subtypeOptions
                                                  .map(
                                                    (option) => DropdownMenuItem(
                                                      value: option,
                                                      child: Text(option),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (value) {
                                                setSheetState(() {
                                                  selectedSubtypeValue = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: l.contractWorkSubtypeHint,
                                                filled: true,
                                                fillColor: const Color(0xFFF9FAFB),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                              ),
                                              icon: const Icon(Icons.arrow_drop_down),
                                            ),
                                            if (subtypeOptions.isEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(top: 12),
                                                child: Text(
                                                  l.contractWorkSubtypeRequiredMessage,
                                                  style: textTheme.bodySmall?.copyWith(
                                                        color:
                                                            const Color(0xFF6B7280),
                                                      ) ??
                                                      const TextStyle(
                                                        color: Color(0xFF6B7280),
                                                      ),
                                                ),
                                              ),
                                            const SizedBox(height: 20),
                                            Text(
                                              '${l.contractWorkRateLabel} (${AppString.euroPrefix.trim()})',
                                              style: textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF1F2937),
                                                  ) ??
                                                  const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF9FAFB),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(0xFFE5E7EB),
                                                ),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    AppString.euroPrefix,
                                                    style: textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.w700,
                                                          color: const Color(0xFF1D4ED8),
                                                        ) ??
                                                        const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFF1D4ED8),
                                                        ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: rateController,
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                        signed: false,
                                                      ),
                                                      decoration: const InputDecoration(
                                                        border: InputBorder.none,
                                                        hintText:
                                                            AppString.contractRateHint,
                                                      ),
                                                      style: textTheme.titleMedium?.copyWith(
                                                            fontWeight: FontWeight.w700,
                                                            color: const Color(0xFF111827),
                                                          ) ??
                                                          const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            color: Color(0xFF111827),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              l.contractWorkUnitLabel,
                                              style: textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF1F2937),
                                                  ) ??
                                                  const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                            ),
                                            const SizedBox(height: 10),
                                            TextField(
                                              controller: unitController,
                                              decoration: InputDecoration(
                                                hintText: AppString.contractUnitHint,
                                                filled: true,
                                                fillColor: const Color(0xFFF9FAFB),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    l.contractWorkRatesNote,
                                    style: textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF6B7280),
                                        ) ??
                                        const TextStyle(
                                          color: Color(0xFF6B7280),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
            /*                OutlinedButton.icon(
                              onPressed: () => _showComingSoonSnackBar(rootContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: const Color(0xFF1D4ED8),
                                side: const BorderSide(color: Color(0xFFE0ECFF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(l.addContractWorkButton),
                            ),*/
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(sheetContext).pop(),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                      foregroundColor: const Color(0xFF374151),
                                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Text(l.cancelButton),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                            FocusScope.of(sheetContext).unfocus();
                                            final name = nameController.text.trim();
                                            final rate = double.tryParse(
                                                rateController.text.trim());
                                            final unit = unitController.text.trim();
                                            final resolvedSubtype =
                                                selectedSubtypeValue?.trim() ?? '';

                                            if ((name.isEmpty && isNameEditable) ||
                                                (!isNameEditable &&
                                                    (type?.name.trim().isEmpty ?? true))) {
                                              ScaffoldMessenger.of(rootContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l.contractWorkNameRequiredMessage,
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            if (rate == null || rate <= 0) {
                                              ScaffoldMessenger.of(rootContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l.contractWorkRateRequiredMessage,
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            if (resolvedSubtype.isEmpty) {
                                              ScaffoldMessenger.of(rootContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l.contractWorkSubtypeRequiredMessage,
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            final fallbackUnit =
                                                l.contractWorkUnitFallback;
                                            final normalizedUnit = unit.isEmpty
                                                ? fallbackUnit
                                                : unit;
                                            final resolvedName = type == null ||
                                                    isNameEditable
                                                ? name
                                                : type!.name;

                                            setSheetState(() {
                                              isSaving = true;
                                            });

                                            Future<_ContractType?> future;
                                            if (type == null ||
                                                type.id.startsWith('local-')) {
                                              future = _repository
                                                  .createContractType(
                                                name: resolvedName,
                                                subtype: resolvedSubtype,
                                                ratePerUnit: rate,
                                                unitLabel: normalizedUnit,
                                              )
                                                  .then(
                                                (created) => _ContractType.fromModel(
                                                  type: created,
                                                  isUserDefined: true,
                                                ),
                                              );
                                            } else {
                                              future = _repository
                                                  .updateContractType(
                                                id: type.id,
                                                name: resolvedName,
                                                subtype: resolvedSubtype,
                                                ratePerUnit: rate,
                                                unitLabel: normalizedUnit,
                                              )
                                                  .then(
                                                (updated) => _ContractType.fromModel(
                                                  type: updated,
                                                  isUserDefined: type.isUserDefined,
                                                ),
                                              );
                                            }

                                            try {
                                              final updatedType = await future;
                                              if (!mounted) {
                                                return;
                                              }
                                              Navigator.of(sheetContext).pop(
                                                updatedType,
                                              );
                                            } on ContractTypeRepositoryException catch (error) {
                                              setSheetState(() {
                                                isSaving = false;
                                              });
                                              ScaffoldMessenger.of(rootContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(error.message),
                                                ),
                                              );
                                            } catch (error) {
                                              setSheetState(() {
                                                isSaving = false;
                                              });
                                              ScaffoldMessenger.of(rootContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(error.toString()),
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Text(l.saveButtonLabel),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    _upsertContractType(result);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.contractWorkTypeSavedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;
    final deviceType = responsive.deviceType;
    final totalTypes = _allContractTypes.length;
    final theme = Theme.of(context);
    double maxContentWidth;
    switch (deviceType) {
      case DeviceType.small:
        maxContentWidth = 520;
        break;
      case DeviceType.medium:
        maxContentWidth = 580;
        break;
      case DeviceType.large:
        maxContentWidth = 700;
        break;
      case DeviceType.tablet:
        maxContentWidth = 820;
        break;
    }

    final Widget bodyContent;
    if (_isLoading) {
      bodyContent = const Center(
        key: ValueKey('contract-types-loading'),
        child: CircularProgressIndicator(),
      );
    } else if (_errorMessage != null) {
      final fallbackMessage = l.contractWorkLoadError;
      final details = _errorMessage!.trim();
      bodyContent = Center(
        key: const ValueKey('contract-types-error'),
        child: Padding(
          padding: responsive.scaledSymmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fallbackMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ) ??
                    TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      fontSize: responsive.scaleText(18),
                    ),
              ),
              if (details.isNotEmpty && details != fallbackMessage) ...[
                SizedBox(height: responsive.scale(8)),
                Text(
                  details,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ) ??
                      const TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                ),
              ],
              SizedBox(height: responsive.scale(16)),
              ElevatedButton(
                onPressed: _loadContractTypes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5856D6),
                  foregroundColor: Colors.white,
                  padding:
                      responsive.scaledSymmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(responsive.scale(14)),
                  ),
                ),
                child: Text(l.retryButtonLabel),
              ),
            ],
          ),
        ),
      );
    } else {
      bodyContent = RefreshIndicator(
        key: const ValueKey('contract-types-content'),
        onRefresh: _loadContractTypes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.scale(16),
                  responsive.scale(16),
                  responsive.scale(16),
                  responsive.scale(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  _SummaryHeader(
                    title: l.contractWorkActiveRatesTitle,
                    totalTypes: totalTypes,
                    totalUnits: _totalUnits,
                    totalAmount: _totalContractSalary,
                    activeTypesLabel: l.contractWorkActiveTypesLabel,
                    totalUnitsLabel: l.contractWorkTotalUnitsLabel,
                    totalSalaryLabel: l.contractWorkTotalSalaryLabel,
                  ),
                  SizedBox(height: responsive.scale(20)),
                  _SectionTitle(text: l.contractWorkDefaultTypesTitle),
                  SizedBox(height: responsive.scale(12)),
                  if (_defaultContractTypes.isEmpty)
                    _EmptyState(message: l.contractWorkNoEntriesLabel)
                  else
                    Column(
                      children: _defaultContractTypes
                          .map(
                            (type) => Padding(
                              padding: EdgeInsets.only(
                                bottom: responsive.scale(12),
                              ),
                              child: _ContractTypeTile(
                                type: type,
                                lastUpdatedLabel:
                                    l.contractWorkLastUpdatedLabel,
                                onEdit: () =>
                                    _showContractTypeDialog(type: type),
                                editLabel: l.contractWorkEditRateButton,
                                defaultTag: l.contractWorkDefaultTag,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  SizedBox(height: responsive.scale(12)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: responsive.scaledSymmetric(
                            horizontal: 20, vertical: 14),
                        backgroundColor: const Color(0xFFEEF2FF),
                        foregroundColor: const Color(0xFF4C1D95),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(responsive.scale(16)),
                        ),
                      ),
                      onPressed: () => _showContractTypeDialog(),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l.addContractWorkButton),
                    ),
                  ),
                  SizedBox(height: responsive.scale(28)),
                  _SectionTitle(text: l.contractWorkCustomTypesTitle),
                  SizedBox(height: responsive.scale(12)),
                  if (_userContractTypes.isEmpty)
                    _EmptyState(message: l.contractWorkNoCustomTypesLabel)
                  else
                    Column(
                      children: _userContractTypes
                          .map(
                            (type) => Padding(
                              padding: EdgeInsets.only(
                                bottom: responsive.scale(12),
                              ),
                              child: Dismissible(
                                key: ValueKey('contract-type-${type.id}'),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) =>
                                    _confirmDeleteContractType(type),
                                onDismissed: (_) => _removeContractType(type),
                                background: const SizedBox.shrink(),
                                secondaryBackground: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    responsive.scale(20),
                                  ),
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: responsive.scaledSymmetric(
                                      horizontal: 24,
                                    ),
                                    color: const Color(0xFFFEE2E2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFB91C1C),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l.contractWorkDeleteButton,
                                          style: const TextStyle(
                                            color: Color(0xFFB91C1C),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                child: _ContractTypeTile(
                                  type: type,
                                  lastUpdatedLabel:
                                      l.contractWorkLastUpdatedLabel,
                                  onEdit: () =>
                                      _showContractTypeDialog(type: type),
                                  editLabel: l.contractWorkEditRateButton,
                                  defaultTag: l.contractWorkDefaultTag,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  SizedBox(height: responsive.scale(28)),
                  _SectionTitle(text: l.contractWorkRecentEntriesTitle),
                  SizedBox(height: responsive.scale(12)),
                  if (_recentEntries.isEmpty)
                    _EmptyState(message: l.contractWorkNoEntriesLabel)
                  else
                    Column(
                      children: _recentEntries
                          .map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: responsive.scale(12),
                              ),
                              child: _ContractEntryTile(
                                entry: entry,
                                contractLabel: l.contractWorkLabel,
                                unitsLabel: l.contractWorkUnitsLabel,
                                rateLabel: l.contractWorkRateLabel,
                                onTap: () =>
                                    _showComingSoonSnackBar(context),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                AppAssets.contractWork,
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l.contractWorkLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: responsive.scaleText(20),
                    color: const Color(0xFF111827),
                  ) ??
                  const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF111827),
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: bodyContent,
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.title,
    required this.totalTypes,
    required this.totalUnits,
    required this.totalAmount,
    required this.activeTypesLabel,
    required this.totalUnitsLabel,
    required this.totalSalaryLabel,
  });

  final String title;
  final int totalTypes;
  final double totalUnits;
  final double totalAmount;
  final String activeTypesLabel;
  final String totalUnitsLabel;
  final String totalSalaryLabel;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final stats = [
          _SummaryItem(
            label: activeTypesLabel,
            value: totalTypes.toString(),
          ),
          _SummaryItem(
            label: totalUnitsLabel,
            value: totalUnits.toStringAsFixed(0),
          ),
          _SummaryItem(
            label: totalSalaryLabel,
            value: '€${totalAmount.toStringAsFixed(2)}',
          ),
        ];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsive.scale(24)),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            responsive.scale(24),
            responsive.scale(24),
            responsive.scale(24),
            responsive.scale(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: responsive.scaleText(18),
                    ) ??
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: responsive.scaleText(18),
                    ),
              ),
              SizedBox(height: responsive.scale(18)),
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      stats[i],
                      if (i != stats.length - 1)
                        SizedBox(height: responsive.scale(14)),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: stats[0]),
                    SizedBox(width: responsive.scale(20)),
                    Expanded(child: stats[1]),
                    SizedBox(width: responsive.scale(20)),
                    Expanded(child: stats[2]),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontSize: responsive.scaleText(12),
          ),
        ),
        SizedBox(height: responsive.scale(6)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: responsive.scaleText(18),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
            fontSize: responsive.scaleText(16),
          ) ??
          TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            fontSize: responsive.scaleText(16),
          ),
    );
  }
}

class _ContractTypeTile extends StatelessWidget {
  const _ContractTypeTile({
    required this.type,
    required this.lastUpdatedLabel,
    required this.onEdit,
    required this.editLabel,
    required this.defaultTag,
  });

  final _ContractType type;
  final String lastUpdatedLabel;
  final VoidCallback onEdit;
  final String editLabel;
  final String defaultTag;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        responsive.scale(18),
        responsive.scale(20),
        responsive.scale(18),
        responsive.scale(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.scale(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              SizedBox(width: responsive.scale(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            fontSize: responsive.scaleText(16),
                          ) ??
                          TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            fontSize: responsive.scaleText(16),
                          ),
                    ),
                    SizedBox(height: responsive.scale(4)),
                    Text(
                      '${type.displayRate} · ${type.unitLabel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4B5563),
                            fontSize: responsive.scaleText(13),
                          ) ??
                          TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: responsive.scaleText(13),
                          ),
                    ),
                    if (type.displaySubtype != null) ...[
                      SizedBox(height: responsive.scale(4)),
                      Text(
                        type.displaySubtype!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: responsive.scaleText(13),
                            ) ??
                            TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: responsive.scaleText(13),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (type.isDefault)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.scale(12),
                    vertical: responsive.scale(6),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FDF4),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    defaultTag,
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.scaleText(12),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: responsive.scale(16)),
          LayoutBuilder(
            builder: (context, constraints) {
              final shouldStack = constraints.maxWidth < 340;
              final dateColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastUpdatedLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: responsive.scaleText(12),
                        ) ??
                        TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: responsive.scaleText(12),
                        ),
                  ),
                  SizedBox(height: responsive.scale(4)),
                  Text(
                    type.formattedUpdatedDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          fontSize: responsive.scaleText(14),
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          fontSize: responsive.scaleText(14),
                        ),
                  ),
                ],
              );
              final editButton = TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4C1D95),
                  textStyle: TextStyle(
                    fontSize: responsive.scaleText(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onEdit,
                child: Text(editLabel),
              );

              if (shouldStack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dateColumn,
                    SizedBox(height: responsive.scale(12)),
                    editButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: dateColumn),
                  editButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContractEntryTile extends StatelessWidget {
  const _ContractEntryTile({
    required this.entry,
    required this.contractLabel,
    required this.unitsLabel,
    required this.rateLabel,
    required this.onTap,
  });

  final _ContractEntry entry;
  final String contractLabel;
  final String unitsLabel;
  final String rateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: EdgeInsets.fromLTRB(
          responsive.scale(18),
          responsive.scale(18),
          responsive.scale(18),
          responsive.scale(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final shouldWrap = constraints.maxWidth < 360;
                final leading = Container(
                  padding: EdgeInsets.all(responsive.scale(10)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FDF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF047857),
                  ),
                );
                final titleColumn = Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.scale(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.workName,
                          style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                    fontSize: responsive.scaleText(16),
                                  ) ??
                              TextStyle(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                                fontSize: responsive.scaleText(16),
                              ),
                        ),
                        SizedBox(height: responsive.scale(4)),
                        Text(
                          entry.formattedDate,
                          style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF6B7280),
                                    fontSize: responsive.scaleText(12),
                                  ) ??
                              TextStyle(
                                color: const Color(0xFF6B7280),
                                fontSize: responsive.scaleText(12),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
                final amountText = Text(
                  '€${entry.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        fontSize: responsive.scaleText(16),
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        fontSize: responsive.scaleText(16),
                      ),
                );

                if (shouldWrap) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          leading,
                          titleColumn,
                        ],
                      ),
                      SizedBox(height: responsive.scale(12)),
                      amountText,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    leading,
                    titleColumn,
                    amountText,
                  ],
                );
              },
            ),
            SizedBox(height: responsive.scale(16)),
            Wrap(
              spacing: responsive.scale(8),
              runSpacing: responsive.scale(8),
              children: [
                _InfoChip(label: contractLabel, value: entry.contractName),
                _InfoChip(
                  label: unitsLabel,
                  value: entry.unitsCompleted.toStringAsFixed(0),
                ),
                _InfoChip(
                  label: rateLabel,
                  value: '€${entry.rate.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(12),
        vertical: responsive.scale(8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              fontSize: responsive.scaleText(12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: responsive.scaleText(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_basket_outlined,
            size: 32,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ContractType {
  const _ContractType({
    required this.id,
    required this.name,
    required this.rate,
    this.unitLabel = 'per unit',
    this.subtype,
    this.isDefault = false,
    this.isUserDefined = false,
    this.lastUpdated,
  });

  factory _ContractType.fromModel({
    required models.ContractType type,
    bool? isUserDefined,
  }) {
    final isDefaultType = type.isDefault || type.isGlobal;
    return _ContractType(
      id: type.id,
      name: type.name,
      rate: type.rate,
      unitLabel: type.unitLabel,
      subtype: type.subtype,
      isDefault: isDefaultType,
      isUserDefined: isUserDefined ?? !isDefaultType,
      lastUpdated: type.updatedAt,
    );
  }

  final String id;
  final String name;
  final double rate;
  final String unitLabel;
  final String? subtype;
  final bool isDefault;
  final bool isUserDefined;
  final DateTime? lastUpdated;

  _ContractType copyWith({
    String? id,
    String? name,
    double? rate,
    String? unitLabel,
    String? subtype,
    bool? isDefault,
    bool? isUserDefined,
    DateTime? lastUpdated,
  }) {
    return _ContractType(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      unitLabel: unitLabel ?? this.unitLabel,
      subtype: subtype ?? this.subtype,
      isDefault: isDefault ?? this.isDefault,
      isUserDefined: isUserDefined ?? this.isUserDefined,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get displayRate => '€${rate.toStringAsFixed(2)}';

  String? get displaySubtype {
    final value = subtype?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String get formattedUpdatedDate {
    final date = lastUpdated;
    if (date == null) {
      return AppString.emDash;
    }
    const monthNames = AppString.shortMonthAbbreviations;
    final month = monthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }
}

class _ContractEntry {
  const _ContractEntry({
    required this.date,
    required this.workName,
    required this.contractName,
    required this.unitsCompleted,
    required this.rate,
    required this.totalAmount,
  });

  final DateTime date;
  final String workName;
  final String contractName;
  final double unitsCompleted;
  final double rate;
  final double totalAmount;

  String get formattedDate {
    const monthNames = AppString.shortMonthAbbreviations;
    final month = monthNames[date.month - 1];
    return '$month ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }
}

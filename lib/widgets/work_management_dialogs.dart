import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_strings.dart';
import '../core/localization/app_localizations.dart';
import '../models/contract_type.dart';
import '../models/pending_contract_work.dart';
import '../models/work.dart';
import '../repositories/contract_type_repository.dart';
import '../repositories/work_repository.dart';
import '../screens/contract_work_screen.dart';
import '../utils/contract_work_display.dart';
import '../utils/contract_unit_label.dart';
import '../utils/snackbar.dart';
import 'app_loader.dart';

Future<void> _clearStoredAddWorkContractDrafts() async {
  final prefs = await SharedPreferences.getInstance();
  final keysToRemove = prefs
      .getKeys()
      .where(
        (key) =>
            key.startsWith('add_work_contract_') ||
            key.startsWith('pending_contract_work'),
      )
      .toList(growable: false);

  for (final key in keysToRemove) {
    await prefs.remove(key);
  }
}

Future<void> showAddWorkDialog({required BuildContext context}) async {
  await _clearStoredAddWorkContractDrafts();
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (dialogContext) {
      return _AddWorkDialog(rootContext: context);
    },
  );
}

class _AddWorkDialog extends StatefulWidget {
  const _AddWorkDialog({required this.rootContext});

  final BuildContext rootContext;

  @override
  State<_AddWorkDialog> createState() => _AddWorkDialogState();
}

class _AddWorkDialogState extends State<_AddWorkDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _workNameController;
  late final TextEditingController _hourlySalaryController;
  final List<PendingContractWork> _pendingContractWorks =
      <PendingContractWork>[];
  bool _hasUserCreatedContractWork = false;
  bool _isFormValid = false;

  void _showRootSnack(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    AppSnackBar.show(widget.rootContext, trimmed);
  }

  @override
  void initState() {
    super.initState();
    _workNameController = TextEditingController();
    _hourlySalaryController = TextEditingController();
    _workNameController.addListener(_updateFormValidity);
    _hourlySalaryController.addListener(_updateFormValidity);
    _resetPendingContractWorkState();
    _updateFormValidity();
  }

  @override
  void dispose() {
    _workNameController.removeListener(_updateFormValidity);
    _hourlySalaryController.removeListener(_updateFormValidity);
    _workNameController.dispose();
    _hourlySalaryController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _workNameController.clear();
    _hourlySalaryController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _resetPendingContractWorkState();
      _isFormValid = false;
    });
  }

  void _updateFormValidity() {
    final nextValidity = _computeFormValidity();
    if (!mounted) {
      _isFormValid = nextValidity;
      return;
    }
    if (nextValidity != _isFormValid) {
      setState(() {
        _isFormValid = nextValidity;
      });
    }
  }

  bool _computeFormValidity() {
    final workName = _workNameController.text.trim();
    if (workName.isEmpty) {
      return false;
    }

    final hourlyText = _hourlySalaryController.text.trim();
    if (hourlyText.isEmpty) {
      return true;
    }

    final normalized = hourlyText.replaceAll(',', '');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return false;
    }

    return parsed >= 0;
  }

  bool get _hasPendingContractWorks => _pendingContractWorks.isNotEmpty;

  Future<void> _confirmAndRemovePendingContractWork(int index) async {
    if (index < 0 || index >= _pendingContractWorks.length) {
      return;
    }

    final l = AppLocalizations.of(widget.rootContext);

    final shouldDelete = await showDialog<bool>(
      context: widget.rootContext,
      builder: (context) {
        return AlertDialog(
          title: Text(l.contractWorkDeleteConfirmationTitle),
          content: Text(l.contractWorkDeleteConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
              child: Text(l.contractWorkDeleteButton),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    setState(() {
      _pendingContractWorks.removeAt(index);
      _hasUserCreatedContractWork = _pendingContractWorks.isNotEmpty;
    });
  }

  void _resetPendingContractWorkState() {
    _pendingContractWorks.clear();
    _hasUserCreatedContractWork = false;
  }

  String _resolvePendingContractTitle(
    PendingContractWork work,
    AppLocalizations l,
  ) {
    final name = work.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final role = contractWorkFormatRoleDisplay(work.role).trim();
    if (role.isNotEmpty) {
      return role;
    }

    return l.contractWorkLabel;
  }

  String _buildPendingContractSubtitle(
    PendingContractWork work,
    AppLocalizations l,
  ) {
    final roleDisplay = contractWorkFormatRoleDisplay(work.role).trim();
    final resolvedUnitLabel = resolveContractUnitLabel(
      localizations: l,
      contractName: work.name,
      unitLabel: work.unitLabel,
    );

    final currencySymbol = AppString.euroPrefix.trim().isEmpty
        ? '€'
        : AppString.euroPrefix.trim();
    final rateLabel = buildContractRateSubtitle(
      l,
      rate: work.ratePerUnit,
      role: work.role,
      fallbackUnitLabel: resolvedUnitLabel,
      currencySymbol: currencySymbol,
    );
    final trimmedRateLabel = rateLabel.trim();
    if (trimmedRateLabel.isNotEmpty) {
      return trimmedRateLabel;
    }

    return roleDisplay;
  }

  Widget _buildPendingContractSummary(
    BuildContext context,
    AppLocalizations l,
  ) {
    if (!_hasPendingContractWorks) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.contractWorkSummaryTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _pendingContractWorks.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 20,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
            _PendingContractListRow(
              title: _resolvePendingContractTitle(
                _pendingContractWorks[i],
                l,
              ),
              subtitle: _buildPendingContractSubtitle(
                _pendingContractWorks[i],
                l,
              ),
              onRemove: () => _confirmAndRemovePendingContractWork(i),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _navigateToContractWorkScreen() async {
    FocusScope.of(context).unfocus();

    final l = AppLocalizations.of(widget.rootContext);
    final repository = ContractTypeRepository();

    try {
      final result = await repository.fetchContractTypes();
      if (!mounted) return;

      final availableRoles = contractWorkBuildAvailableRoles<ContractType>(
        globalTypes: result.globalTypes,
        userTypes: result.userTypes,
        roleSelector: (type) => type.role,
      );

      final pending = await showModalBottomSheet<PendingContractWork>(
        context: widget.rootContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return ContractTypeSheet(
            type: null,
            repository: repository,
            rootContext: widget.rootContext,
            isNameEditable: true,
            workNameOptions: kContractWorkDefaultWorkNameOptions,
            defaultRoleOptions: kContractWorkDefaultRoleOptions,
            availableRoles: availableRoles,
            initialRoleValue: null,
            formatRoleDisplay: contractWorkFormatRoleDisplay,
            deferApiCalls: true,
          );
        },
      );

      if (pending != null && mounted) {
        setState(() {
          _pendingContractWorks.add(pending);
          _hasUserCreatedContractWork = true;
        });
        _showRootSnack(l.contractWorkTypeSavedMessage);
      }
    } on ContractTypeRepositoryException catch (error) {
      final message = error.message.trim().isEmpty
          ? l.contractWorkLoadError
          : error.message;
      _showRootSnack(message);
    } catch (_) {
      _showRootSnack(l.contractWorkLoadError);
    }
  }

  Future<void> _handleSaveWork(BuildContext dialogContext) async {
    final formState = _formKey.currentState;
    final isValid = formState?.validate() ?? false;
    if (!isValid) {
      _updateFormValidity();
      return;
    }

    final workName = _workNameController.text.trim();
    final hourlyRateText = _hourlySalaryController.text.trim();
    num hourlyRate = 0;
    if (hourlyRateText.isNotEmpty) {
      hourlyRate =
          double.tryParse(hourlyRateText.replaceAll(',', ''))?.toDouble() ?? 0;
    }

    FocusScope.of(dialogContext).unfocus();
    final shouldIncludeContractWorks =
        _hasUserCreatedContractWork && _pendingContractWorks.isNotEmpty;
    final pending = shouldIncludeContractWorks
        ? List<PendingContractWork>.from(_pendingContractWorks)
        : const <PendingContractWork>[];

    widget.rootContext.read<WorkBloc>().add(
      WorkAdded(
        name: workName,
        hourlyRate: hourlyRate,
        isContract: true,
        pendingContractWorks: pending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(widget.rootContext);

    return BlocConsumer<WorkBloc, WorkState>(
      listenWhen: (previous, current) =>
          previous.addStatus != current.addStatus,
      listener: (blocContext, state) {
        if (state.addStatus == WorkActionStatus.success) {
          _clearForm();
          Navigator.of(context).pop();
          blocContext.read<WorkBloc>().add(const WorkAddStatusCleared());
        } else if (state.addStatus == WorkActionStatus.failure) {
          final message = state.lastErrorMessage?.trim() ?? '';
          _showRootSnack(
            message.isNotEmpty
                ? message
                : 'Unable to save work. Please try again.',
          );
        }
      },
      builder: (blocContext, state) {
        final isSaving = state.addStatus == WorkActionStatus.inProgress;
        final errorMessage = state.addStatus == WorkActionStatus.failure
            ? (state.lastErrorMessage?.trim().isNotEmpty ?? false
                ? state.lastErrorMessage!.trim()
                : 'A work with this name already exists. Please use a different name.')
            : null;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final maxWidth =
              constraints.maxWidth.clamp(0.0, 420.0).toDouble();
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 40,
                          offset: Offset(0, 24),
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 40),
                                Expanded(
                                  child: Text(
                                    l.addNewWorkLabel,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: const Color(0xFF0F172A),
                                    ) ??
                                        const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                          color: Color(0xFF0F172A),
                                        ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _clearForm();
                                    blocContext
                                        .read<WorkBloc>()
                                        .add(const WorkAddStatusCleared());
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                  splashRadius: 20,
                                ),
                              ],
                            ),

                            if (errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4F3),
                                  border: Border.all(color: const Color(0xFFFFB4AC)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFB3261E),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        errorMessage,
                                        style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: const Color(0xFF410E0B),
                                                  fontWeight: FontWeight.w600,
                                                ) ??
                                            const TextStyle(
                                              color: Color(0xFF410E0B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FBFF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                  width: 2,
                                ),
                              ),
                              padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 36,
                                        width: 36,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFE5F1FF),
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            AppAssets.clock,
                                            height: 24,
                                            width: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        l.hourlyWorkLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                          fontWeight:
                                          FontWeight.w700,
                                          fontSize: 18,
                                          color:
                                          const Color(0xFF0F172A),
                                        ) ??
                                            const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              color: Color(0xFF0F172A),
                                            ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  Form(
                                    key: _formKey,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.workNameLabel,
                                          style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 16,
                                                    color: const Color(
                                                        0xFF0F172A),
                                                  ) ??
                                              const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 16,
                                                color:
                                                    Color(0xFF0F172A),
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _workNameController,
                                          textInputAction:
                                              TextInputAction.next,
                                          decoration: InputDecoration(
                                            hintText: l.workNameHint,
                                            hintStyle: const TextStyle(
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF007BFF),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          validator: (value) {
                                            final trimmed =
                                                value?.trim() ?? '';
                                            if (trimmed.isEmpty) {
                                              return l
                                                  .workNameRequiredMessage;
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          l.hourlySalaryLabel,
                                          style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 16,
                                                    color: const Color(
                                                        0xFF0F172A),
                                                  ) ??
                                              const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 16,
                                                color:
                                                    Color(0xFF0F172A),
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller:
                                              _hourlySalaryController,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                            decimal: true,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: l.hourlySalaryHint,
                                            hintStyle: const TextStyle(
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF007BFF),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          validator: (value) {
                                            final trimmed =
                                                value?.trim() ?? '';
                                            if (trimmed.isEmpty) {
                                              return null;
                                            }
                                            final normalized = trimmed
                                                .replaceAll(',', '');
                                            final parsed = double.tryParse(
                                                normalized);
                                            if (parsed == null) {
                                              return l
                                                  .invalidHourlyRateMessage;
                                            }
                                            if (parsed < 0) {
                                              return l
                                                  .hourlyRateNegativeValidation;
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FBFF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '📑',
                                        style: TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          l.contractWorkHeader,
                                          style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 18,
                                                    color:
                                                        const Color(0xFF0F172A),
                                                  ) ??
                                              const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                color: Color(0xFF0F172A),
                                              ),
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  GestureDetector(
                                    onTap: _navigateToContractWorkScreen,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius:
                                            BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.8),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            '📑',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              l.addContractWorkButton,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  if (_hasPendingContractWorks) ...[
                                    _buildPendingContractSummary(context, l),
                                    const SizedBox(height: 4),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _clearForm();
                                      blocContext
                                          .read<WorkBloc>()
                                          .add(const WorkAddStatusCleared());
                                      Navigator.of(context).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFF1F2937),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(32),
                                      ),
                                    ),
                                    child: Text(
                                      l.cancelButton,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSaving || !_isFormValid
                                        ? null
                                        : () => _handleSaveWork(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF0066FF),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(32),
                                      ),
                                      elevation: 0,
                                      disabledBackgroundColor:
                                          const Color(0xFF0066FF)
                                              .withOpacity(0.5),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: AppLoader(
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            l.saveWorkButton,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
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
              );
            },
          ),
        );
      },
    );
  }
}

Future<void> showEditWorkDialog({
  required BuildContext context,
  required Work work,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (dialogContext) {
      return _EditWorkDialog(rootContext: context, work: work);
    },
  );
}

class _EditWorkDialog extends StatefulWidget {
  const _EditWorkDialog({required this.rootContext, required this.work});

  final BuildContext rootContext;
  final Work work;

  @override
  State<_EditWorkDialog> createState() => _EditWorkDialogState();
}

class _EditWorkDialogState extends State<_EditWorkDialog> {
  final ContractTypeRepository _contractTypeRepository =
  ContractTypeRepository();
  final Set<String> _deletingContractTypeIds = <String>{};
  final Set<String> _deletingWorkContractIds = <String>{};
  List<ContractType> _contractTypes = <ContractType>[];
  bool _isLoadingContractTypes = false;
  String? _contractTypesError;
  late Work _currentWork;
  List<_WorkContractDisplay> _workContracts = <_WorkContractDisplay>[];

  @override
  void initState() {
    super.initState();
    _currentWork = widget.work;
    _workContracts = _resolveWorkContracts(_currentWork);
    unawaited(_loadContractTypes());
  }

  Future<void> _loadContractTypes() async {
    final l = AppLocalizations.of(widget.rootContext);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingContractTypes = true;
      _contractTypesError = null;
    });

    try {
      final result = await _contractTypeRepository.fetchContractTypes();
      if (!mounted) {
        return;
      }
      setState(() {
        _contractTypes = result.userTypes;
        _isLoadingContractTypes = false;
      });
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        final message = error.message.trim();
        _contractTypesError =
        message.isEmpty ? l.contractWorkLoadError : message;
        _isLoadingContractTypes = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _contractTypesError = l.contractWorkLoadError;
        _isLoadingContractTypes = false;
      });
    }
  }

  String? _resolveCurrencySymbol([Map<String, dynamic>? source]) {
    // Null-safe access to additionalData to avoid crashes.
    final Map<String, dynamic> data =
        (source ?? _currentWork.additionalData as Map<String, dynamic>?) ??
            const <String, dynamic>{};
    if (data.isEmpty) {
      return null;
    }
    const possibleKeys = [
      'currency_symbol',
      'currencySymbol',
      'currency',
      'currencyCode',
      'currencyPrefix',
    ];
    for (final key in possibleKeys) {
      final value = data[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          final isAlphabetic = trimmed.length == 3 &&
              trimmed.codeUnits.every(
                    (unit) =>
                (unit >= 65 && unit <= 90) ||
                    (unit >= 97 && unit <= 122),
              );
          if (isAlphabetic) {
            return '$trimmed ';
          }
          return trimmed;
        }
      }
    }
    return null;
  }

  String _formatHourlyRate(AppLocalizations l) {
    final rate = _currentWork.hourlyRate;
    if (rate == null) {
      return l.notAvailableLabel;
    }
    final symbol = _resolveCurrencySymbol();
    final formatted = rate.toDouble().toStringAsFixed(2);
    final prefix = symbol ?? '£';
    return '$prefix$formatted/hour';
  }

  (num?, String?) _extractQuantityAndUnitFromText(String? source) {
    if (source == null) {
      return (null, null);
    }
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return (null, null);
    }
    final pattern = RegExp(r'(\d+(?:[\.,]\d+)?)\s*([A-Za-z][A-Za-z\s]*)$',
        caseSensitive: false);
    final match = pattern.firstMatch(trimmed);
    if (match == null) {
      return (null, null);
    }

    final quantityText = match.group(1)?.replaceAll(',', '.');
    final unitText = match.group(2)?.trim();
    if (quantityText == null || unitText == null || unitText.isEmpty) {
      return (null, null);
    }

    final quantity = num.tryParse(quantityText);
    if (quantity == null) {
      return (null, null);
    }

    return (quantity, unitText);
  }

  String _formatQuantity(num quantity) {
    if (quantity % 1 == 0) {
      return quantity.toInt().toString();
    }
    final formatted = quantity.toString();
    return formatted;
  }

  String _normalizeUnitLabel(String unit, num quantity) {
    final trimmed = unit.trim();
    if (trimmed.isEmpty) {
      return quantity == 1 ? 'unit' : 'units';
    }

    final lowerCased = trimmed.toLowerCase();
    if (quantity == 1) {
      if (lowerCased == 'units') {
        return 'unit';
      }
      return lowerCased;
    }

    if (quantity != 1 && !lowerCased.endsWith('s') && lowerCased != 'unit') {
      return lowerCased;
    }

    if (quantity != 1 && lowerCased == 'unit') {
      return 'units';
    }

    return lowerCased;
  }

  String _formatContractRate(AppLocalizations localizations, ContractType type) {
    final Map<String, dynamic> data =
        type.additionalData.isEmpty ? const <String, dynamic>{} : type.additionalData;

    final count = _parseWorkContractCount(data);
    final role = _extractWorkContractRole(data) ?? type.role;
    final fallbackUnitLabel =
        _extractWorkContractUnitLabel(data) ?? (type.unitLabel.isNotEmpty ? type.unitLabel : null);
    final resolvedUnitLabel = resolveContractUnitLabel(
      localizations: localizations,
      contractName: type.name,
      unitLabel: fallbackUnitLabel ?? localizations.contractWorkUnitFallback,
    );

    final rawPriceText = _normalizeWorkContractText(data['price']);

    final currencySymbol =
        _resolveCurrencySymbol(type.additionalData) ?? _resolveCurrencySymbol() ?? '€';

    return buildContractRateSubtitle(
      localizations,
      rate: type.rate,
      rawPrice: rawPriceText,
      count: count,
      role: role,
      fallbackUnitLabel: resolvedUnitLabel,
      currencySymbol: currencySymbol,
    );
  }

  Future<void> _navigateToContractWorkScreen() async {
    FocusScope.of(context).unfocus();
    final l = AppLocalizations.of(widget.rootContext);

    try {
      final result = await _contractTypeRepository.fetchContractTypes();
      if (!mounted) {
        return;
      }

      final availableRoles = contractWorkBuildAvailableRoles<ContractType>(
        globalTypes: result.globalTypes,
        userTypes: result.userTypes,
        roleSelector: (type) => type.role,
      );

      final resultFromSheet = await showModalBottomSheet<dynamic>(
        context: widget.rootContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return ContractTypeSheet(
            type: null,
            repository: _contractTypeRepository,
            rootContext: widget.rootContext,
            isNameEditable: true,
            workNameOptions: kContractWorkDefaultWorkNameOptions,
            defaultRoleOptions: kContractWorkDefaultRoleOptions,
            availableRoles: availableRoles,
            initialRoleValue: null,
            formatRoleDisplay: contractWorkFormatRoleDisplay,
            workId: _currentWork.id,
          );
        },
      );

      if (!mounted) {
        return;
      }
      final didUpdateLocally = _applyContractSheetResult(resultFromSheet);
      if (resultFromSheet != null) {
        unawaited(_refreshWorkDetails(showError: !didUpdateLocally));
      }
      await _loadContractTypes();
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.message.trim().isEmpty
          ? l.contractWorkLoadError
          : error.message;
      AppSnackBar.show(widget.rootContext, message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.show(widget.rootContext, l.contractWorkLoadError);
    }
  }

  Future<void> _confirmAndDeleteContractType(
      BuildContext dialogContext,
      ContractType type,
      ) async {
    final l = AppLocalizations.of(widget.rootContext);

    final shouldDelete = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text(l.contractWorkDeleteConfirmationTitle),
          content: Text(l.contractWorkDeleteConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
              child: Text(l.contractWorkDeleteButton),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _deletingContractTypeIds.add(type.id);
    });

    try {
      await _contractTypeRepository.deleteContractType(id: type.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _contractTypes.removeWhere((item) => item.id == type.id);
        _deletingContractTypeIds.remove(type.id);
      });
      if (!mounted) {
        return;
      }
      AppSnackBar.show(widget.rootContext, l.contractWorkTypeDeletedMessage);
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingContractTypeIds.remove(type.id);
      });
      final exists = await _refreshContractTypesAfterDeleteAttempt(type.id);
      if (!mounted) {
        return;
      }
      if (!exists) {
        AppSnackBar.show(widget.rootContext, l.contractWorkTypeDeletedMessage);
        return;
      }
      final message = error.message.trim().isEmpty
          ? l.contractWorkTypeDeleteFailedMessage
          : error.message;
      AppSnackBar.show(widget.rootContext, message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingContractTypeIds.remove(type.id);
      });
      final exists = await _refreshContractTypesAfterDeleteAttempt(type.id);
      if (!mounted) {
        return;
      }
      if (!exists) {
        AppSnackBar.show(widget.rootContext, l.contractWorkTypeDeletedMessage);
        return;
      }
      AppSnackBar.show(widget.rootContext, l.contractWorkTypeDeleteFailedMessage);
    }
  }

  Future<void> _confirmAndDeleteWorkContract(
      _WorkContractDisplay contract,
      ) async {
    final contractId = contract.id;
    if (contractId == null || contractId.isEmpty ||
        _deletingWorkContractIds.contains(contractId)) {
      return;
    }

    final l = AppLocalizations.of(widget.rootContext);

    final shouldDelete = await showDialog<bool>(
      context: widget.rootContext,
      builder: (context) {
        return AlertDialog(
          title: Text(l.contractWorkDeleteConfirmationTitle),
          content: Text(l.contractWorkDeleteConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
              child: Text(l.contractWorkDeleteButton),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _deletingWorkContractIds.add(contractId);
    });

    try {
      await _contractTypeRepository.deleteContractType(id: contractId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingWorkContractIds.remove(contractId);
        _workContracts = _workContracts
            .where((item) => item.id != contractId)
            .toList(growable: false);
        _contractTypes.removeWhere((item) => item.id == contractId);
      });
      if (!mounted) {
        return;
      }
      AppSnackBar.show(widget.rootContext, l.contractWorkTypeDeletedMessage);
      unawaited(_refreshWorkDetails(showError: false));
      unawaited(_loadContractTypes());
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingWorkContractIds.remove(contractId);
      });
      final message = error.message.trim().isEmpty
          ? l.contractWorkTypeDeleteFailedMessage
          : error.message;
      AppSnackBar.show(widget.rootContext, message);
      unawaited(_refreshWorkDetails());
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingWorkContractIds.remove(contractId);
      });
      AppSnackBar.show(widget.rootContext, l.contractWorkTypeDeleteFailedMessage);
      unawaited(_refreshWorkDetails());
    }
  }

  Future<bool> _refreshContractTypesAfterDeleteAttempt(
      String contractTypeId,
      ) async {
    try {
      final result = await _contractTypeRepository.fetchContractTypes();
      if (!mounted) {
        return false;
      }
      final updatedTypes = result.userTypes;
      setState(() {
        _contractTypes = updatedTypes;
        _contractTypesError = null;
      });
      return updatedTypes.any((type) => type.id == contractTypeId);
    } on ContractTypeRepositoryException {
      return true;
    } catch (_) {
      return true;
    }
  }

  Widget _buildWorkInfoSection(BuildContext context) {
    final hourlyText =
        'Hourly Rate: ${_formatHourlyRate(AppLocalizations.of(widget.rootContext))}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF93C5FD),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentWork.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            hourlyText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E3A8A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<_WorkContractDisplay> _resolveWorkContracts(Work work) {
    final l = AppLocalizations.of(widget.rootContext);
    final items = <_WorkContractDisplay>[];

    void addItem(String? rawTitle, String? rawSubtitle, {String? id}) {
      final title = rawTitle?.trim() ?? '';
      final subtitle = rawSubtitle?.trim() ?? '';
      if (title.isEmpty && subtitle.isEmpty) {
        return;
      }
      final resolvedTitle = title.isEmpty ? l.contractWorkLabel : title;
      final resolvedSubtitle =
          subtitle.isEmpty ? l.notAvailableLabel : subtitle;
      items.add(
        _WorkContractDisplay(
          id: id,
          title: resolvedTitle,
          subtitle: resolvedSubtitle,
        ),
      );
    }

    final rawContracts = work.additionalData['contracts'];
    if (rawContracts is List) {
      for (final raw in rawContracts) {
        if (raw is Map) {
          final map = <String, dynamic>{};
          raw.forEach((key, value) {
            map[key.toString()] = value;
          });

          final name = _normalizeWorkContractText(map['name']) ??
              _normalizeWorkContractText(map['title']);
          final rawType = _normalizeWorkContractText(map['type']);
          final rawRole = _extractWorkContractRole(map);
          final type = rawType ?? rawRole;
          final combinedTitle = _combineWorkContractTitle(name, type);
          final rate = _parseWorkContractRate(map);
          final rawPrice = _normalizeWorkContractText(map['price']);
          final unitLabel = _extractWorkContractUnitLabel(map);
          final resolvedUnitLabel = resolveContractUnitLabel(
            localizations: l,
            contractName: name ?? type ?? '',
            unitLabel: unitLabel ?? l.contractWorkUnitFallback,
          );
          final count = _parseWorkContractCount(map);
          final contractId = _extractWorkContractId(map);

          final subtitle = buildContractRateSubtitle(
            l,
            rate: rate,
            rawPrice: rawPrice,
            count: count,
            role: rawRole ?? rawType,
            fallbackUnitLabel: resolvedUnitLabel,
            currencySymbol: _resolveCurrencySymbol(map),
          );

          final resolvedTitle = combinedTitle.isNotEmpty
              ? combinedTitle
              : (name ?? type ?? '');
          addItem(resolvedTitle, subtitle, id: contractId);
        }
      }
    }

    if (items.isNotEmpty) {
      return items;
    }

    final legacyItems = work.additionalData['contractItems'];
    if (legacyItems is List) {
      for (final raw in legacyItems) {
        if (raw is Map) {
          final map = <String, dynamic>{};
          raw.forEach((key, value) {
            map[key.toString()] = value;
          });
          final title = _normalizeWorkContractText(map['title']);
          final subtitle = _normalizeWorkContractText(map['price']);
          final contractId = _extractWorkContractId(map);
          addItem(title, subtitle, id: contractId);
        }
      }
    }

    return items;
  }

  String? _extractWorkContractId(Map<String, dynamic> data) {
    const keys = <String>[
      'id',
      'contract_id',
      'contractId',
      'contract_type_id',
      'contractTypeId',
      'work_contract_id',
      'workContractId',
      'type_id',
      'typeId',
    ];
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  bool _applyContractSheetResult(Object? sheetResult) {
    if (sheetResult == null || !mounted) {
      return false;
    }

    try {
      final dynamic result = sheetResult;

      String? readString(dynamic value) {
        if (value == null) {
          return null;
        }
        final text = value.toString().trim();
        return text.isEmpty ? null : text;
      }

      String? id;
      String? name;
      String? role;
      String? type;
      String? unitLabel;
      num? count;
      num? rate;

      try {
        id = readString(result.id);
      } catch (_) {}
      try {
        name = readString(result.name);
      } catch (_) {}
      try {
        role = readString(result.role);
      } catch (_) {}
      if (role == null) {
        try {
          role = readString(result.roleName);
        } catch (_) {}
      }
      if (role == null) {
        try {
          role = readString(result.unitName);
        } catch (_) {}
      }
      try {
        type = readString(result.type);
      } catch (_) {}
      try {
        unitLabel = readString(result.unitLabel);
      } catch (_) {}
      void readCount(dynamic source) {
        try {
          count = _parseNumericValue(source);
        } catch (_) {}
      }
      try {
        readCount(result.count);
      } catch (_) {}
      if (count == null) {
        try {
          readCount(result.unitCount);
        } catch (_) {}
      }
      if (count == null) {
        try {
          readCount(result.quantity);
        } catch (_) {}
      }
      if (count == null) {
        try {
          readCount(result.qty);
        } catch (_) {}
      }
      if (count == null) {
        try {
          readCount(result.perCount);
        } catch (_) {}
      }
      try {
        final dynamic rateValue = result.rate;
        if (rateValue is num) {
          rate = rateValue;
        } else if (rateValue is String) {
          rate = num.tryParse(rateValue);
        }
      } catch (_) {}

      final l = AppLocalizations.of(widget.rootContext);

      final resolvedUnitLabel = resolveContractUnitLabel(
        localizations: l,
        contractName: name ?? role ?? type ?? '',
        unitLabel: (unitLabel != null && unitLabel.isNotEmpty)
            ? unitLabel
            : l.contractWorkUnitFallback,
      );

      var subtitle = buildContractRateSubtitle(
        l,
        rate: rate,
        count: count,
        role: role ?? type,
        fallbackUnitLabel: resolvedUnitLabel,
        currencySymbol: _resolveCurrencySymbol(),
      );
      if (subtitle.isEmpty) {
        subtitle = l.notAvailableLabel;
      }

      final roleOrType = (role != null && role.isNotEmpty) ? role : type;
      final combinedTitle = _combineWorkContractTitle(name, roleOrType);
      final resolvedTitle = combinedTitle.isNotEmpty
          ? combinedTitle
          : (name ?? role ?? type ?? l.contractWorkLabel);

      final display = _WorkContractDisplay(
        id: id,
        title: resolvedTitle,
        subtitle: subtitle,
      );

      setState(() {
        final updated = List<_WorkContractDisplay>.from(_workContracts);
        if (display.id != null && display.id!.isNotEmpty) {
          final index =
              updated.indexWhere((item) => item.id == display.id);
          if (index != -1) {
            updated[index] = display;
          } else {
            updated.add(display);
          }
        } else {
          final index = updated.indexWhere(
            (item) => item.title.toLowerCase() == display.title.toLowerCase(),
          );
          if (index != -1) {
            updated[index] = display;
          } else {
            updated.add(display);
          }
        }
        _workContracts = updated;
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshWorkDetails({bool showError = true}) async {
    final l = AppLocalizations.of(widget.rootContext);

    try {
      final repository = WorkRepository();
      final works = await repository.fetchWorks();

      Work? updatedWork;
      for (final work in works) {
        if (work.id == _currentWork.id) {
          updatedWork = work;
          break;
        }
      }

      if (!mounted) {
        return;
      }

      if (updatedWork != null) {
        setState(() {
          _currentWork = updatedWork!;
          _workContracts = _resolveWorkContracts(_currentWork);
          _deletingWorkContractIds.clear();
        });
      } else {
        setState(() {
          _workContracts = _resolveWorkContracts(_currentWork);
          _deletingWorkContractIds.clear();
        });
      }
    } on WorkRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingWorkContractIds.clear();
      });
      if (!showError) {
        return;
      }
      final message = error.message.trim().isEmpty
          ? l.contractWorkLoadError
          : error.message;
      AppSnackBar.show(widget.rootContext, message);
    } on Exception {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingWorkContractIds.clear();
      });
      if (!showError) {
        return;
      }
      AppSnackBar.show(widget.rootContext, l.contractWorkLoadError);
    }
  }

  String? _normalizeWorkContractText(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num) {
      return value.toString();
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  num? _parseWorkContractRate(Map<String, dynamic> data) {
    const keys = <String>['rate_per_unit', 'ratePerUnit', 'rate', 'price', 'amount'];
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      if (value is num) {
        return value;
      }
      if (value is String) {
        final sanitized = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
        if (sanitized.isEmpty) {
          continue;
        }
        final normalized = sanitized.replaceAll(',', '');
        final parsed = num.tryParse(normalized);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  num? _parseWorkContractCount(Map<String, dynamic> data) {
    const keys = <String>[
      'count',
      'quantity',
      'qty',
      'unit_count',
      'unitCount',
      'unit_quantity',
      'unitQuantity',
      'per_count',
      'perCount',
      'units',
      'unit_size',
      'unitSize',
      'bundle_size',
      'bundleSize',
    ];
    for (final key in keys) {
      final value = data[key];
      final parsed = _parseNumericValue(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  String? _extractWorkContractRole(Map<String, dynamic> data) {
    const keys = <String>[
      'role',
      'contract_role',
      'contractRole',
      'role_name',
      'roleName',
      'unit_name',
      'unitName',
      'unit',
      'unit_display',
      'unitDisplay',
      'type',
      'contract_type',
      'contractType',
      'subtype',
      'contract_subtype',
      'contractSubtype',
    ];

    for (final key in keys) {
      final value = _normalizeWorkContractText(data[key]);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  num? _parseNumericValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    if (value is String) {
      final sanitized = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
      if (sanitized.isEmpty) {
        return null;
      }
      final normalized = sanitized.replaceAll(',', '');
      return num.tryParse(normalized);
    }
    return null;
  }

  String? _extractWorkContractUnitLabel(Map<String, dynamic> data) {
    const keys = <String>[
      'unit_label',
      'unitLabel',
      'unit',
      'unit_name',
      'unitName',
      'unit_display',
      'unitDisplay',
    ];
    for (final key in keys) {
      final value = _normalizeWorkContractText(data[key]);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _combineWorkContractTitle(String? name, String? type) {
    final nameText = name?.trim() ?? '';
    final typeText = _formatWorkContractTypeLabel(type);
    if (nameText.isEmpty && typeText.isEmpty) {
      return '';
    }
    if (nameText.isEmpty) {
      return typeText;
    }
    if (typeText.isEmpty) {
      return nameText;
    }
    return '$nameText • $typeText';
  }

  String _formatWorkContractTypeLabel(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return '';
    }
    if (text.length == 1) {
      return text.toUpperCase();
    }
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  Widget _buildContractTypeTile(
      BuildContext context,
      AppLocalizations l,
      ContractType type,
      ) {
    final isDeleting = _deletingContractTypeIds.contains(type.id);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFACC15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C2D12),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatContractRate(l, type),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isDeleting)
            const SizedBox(
              height: 20,
              width: 20,
              child: AppLoader(
                size: 20,
                color: Color(0xFFB91C1C),
              ),
            )
          else
            InkWell(
              onTap: () => _confirmAndDeleteContractType(context, type),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContractSection(BuildContext context) {
    final workContracts = _workContracts;
    final isContractWork = _currentWork.isContract;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildWorkInfoSection(context),
        const SizedBox(height: 16),
        if (workContracts.isNotEmpty) ...[
          _WorkContractList(
            items: workContracts,
            onDelete: _confirmAndDeleteWorkContract,
            deletingIds: _deletingWorkContractIds,
          ),
          const SizedBox(height: 16),
        ],
        if (isContractWork) ...[
          GestureDetector(
            onTap: _navigateToContractWorkScreen,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📑', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Add Contract Work',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ) ??
                          const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _handleDeleteWork(BuildContext dialogContext) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l = AppLocalizations.of(widget.rootContext);
    final bloc = widget.rootContext.read<WorkBloc>();

    if (bloc.state.deletingWorkId != null &&
        bloc.state.deletingWorkId != _currentWork.id) {
      return;
    }

    final shouldDelete = await _showDeleteConfirmationDialog(dialogContext, l);
    if (!shouldDelete || !mounted) {
      return;
    }

    final completer = Completer<bool>();
    bloc.add(WorkDeleted(work: _currentWork, completer: completer));
    final result = await completer.future;

    if (!mounted) {
      return;
    }

    if (result) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showDeleteConfirmationDialog(
      BuildContext dialogContext,
      AppLocalizations l,
      ) async {
    final theme = Theme.of(dialogContext);
    final result = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1FDC2626),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Color(0xFFB91C1C),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.workDeleteConfirmationTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                                  const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.workDeleteConfirmationMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                                height: 1.5,
                              ) ??
                                  const TextStyle(
                                    color: Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFF97316),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l.workDeleteIrreversibleMessage,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9A3412),
                              height: 1.4,
                            ) ??
                                const TextStyle(
                                  color: Color(0xFF9A3412),
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            l.workDeleteCancelButton,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB91C1C),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            l.workDeleteConfirmButton,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ) ??
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(widget.rootContext);

    return BlocBuilder<WorkBloc, WorkState>(
      builder: (blocContext, state) {
        final isDeleting = state.deletingWorkId == _currentWork.id;
        final theme = Theme.of(context);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (layoutContext, constraints) {
              final maxWidth =
              constraints.maxWidth.clamp(0.0, 420.0).toDouble();
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF8FBFF), Color(0xFFFFFFFF)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F1D4ED8),
                          offset: Offset(0, 18),
                          blurRadius: 40,
                          spreadRadius: -12,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l.editWorkDetailsTitle,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight:
                                          FontWeight.w700,
                                          fontSize: 20,
                                        ) ??
                                            const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            _buildContractSection(context),

                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: isDeleting
                                    ? null
                                    : () => _handleDeleteWork(context),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                  const Color(0xFFB91C1C),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(24),
                                  ),
                                ),
                                child: isDeleting
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: AppLoader(
                                    size: 20,
                                    color: Color(0xFFB91C1C),
                                  ),
                                )
                                    : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.delete_outline),
                                    const SizedBox(width: 8),
                                    Text(
                                      l.deleteWorkButton,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                        fontWeight:
                                        FontWeight.w600,
                                      ) ??
                                          const TextStyle(
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isDeleting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  l.close,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
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
            },
          ),
        );
      },
    );
  }
}

class _WorkContractList extends StatelessWidget {
  const _WorkContractList({
    required this.items,
    this.onDelete,
    this.deletingIds = const <String>{},
  });

  final List<_WorkContractDisplay> items;
  final void Function(_WorkContractDisplay contract)? onDelete;
  final Set<String> deletingIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.contractWorkSummaryTitle,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 20,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
            _ContractListRow(
              item: items[i],
              onDelete: onDelete,
              isDeleting:
                  items[i].id != null && deletingIds.contains(items[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingContractListRow extends StatelessWidget {
  const _PendingContractListRow({
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                ),
                color: const Color(0xFFB91C1C),
                tooltip: l.contractWorkRemoveEntryButton,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                splashRadius: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContractListRow extends StatelessWidget {
  const _ContractListRow({
    required this.item,
    this.onDelete,
    this.isDeleting = false,
  });

  final _WorkContractDisplay item;
  final void Function(_WorkContractDisplay contract)? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final contractId = item.id;
    final canDelete =
        onDelete != null && contractId != null && contractId.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  item.subtitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: 12),
                if (isDeleting)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: AppLoader(
                      size: 20,
                      color: Color(0xFFB91C1C),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => onDelete?.call(item),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                    ),
                    color: const Color(0xFFB91C1C),
                    tooltip: l.contractWorkRemoveEntryButton,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minHeight: 32, minWidth: 32),
                    splashRadius: 18,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkContractDisplay {
  const _WorkContractDisplay({this.id, required this.title, required this.subtitle});

  final String? id;
  final String title;
  final String subtitle;
}

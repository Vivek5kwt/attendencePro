import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/contract_type.dart';
import '../models/pending_contract_work.dart';
import '../models/work.dart';
import '../repositories/contract_type_repository.dart';
import '../screens/contract_work_screen.dart';

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
  late final TextEditingController _workNameController;
  late final TextEditingController _hourlySalaryController;
  final List<PendingContractWork> _pendingContractWorks =
      <PendingContractWork>[];
  bool _hasUserCreatedContractWork = false;

  @override
  void initState() {
    super.initState();
    _workNameController = TextEditingController();
    _hourlySalaryController = TextEditingController();
    _resetPendingContractWorkState();
  }

  @override
  void dispose() {
    _workNameController.dispose();
    _hourlySalaryController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _workNameController.clear();
    _hourlySalaryController.clear();
    setState(() {
      _resetPendingContractWorkState();
    });
  }

  bool get _hasPendingContractWorks => _pendingContractWorks.isNotEmpty;

  void _removePendingContractWork(int index) {
    if (index < 0 || index >= _pendingContractWorks.length) {
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

  Widget _buildPendingContractWorkTile({
    required int index,
    required PendingContractWork work,
    required AppLocalizations l,
  }) {
    final roleDisplay = contractWorkFormatRoleDisplay(work.role);
    final rateText = work.ratePerUnit.toStringAsFixed(2);
    final subtitle = '$roleDisplay • $rateText / ${work.unitLabel}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _removePendingContractWork(index),
            icon: const Icon(
              Icons.close,
              size: 18,
              color: Color(0xFF1F2937),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
            tooltip: l.contractWorkRemoveEntryButton,
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToContractWorkScreen() async {
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(widget.rootContext);
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
        messenger.showSnackBar(
          SnackBar(content: Text(l.contractWorkTypeSavedMessage)),
        );
      }
    } on ContractTypeRepositoryException catch (error) {
      final message = error.message.trim().isEmpty
          ? l.contractWorkLoadError
          : error.message;
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.contractWorkLoadError)),
      );
    }
  }

  Future<void> _handleSaveWork(BuildContext dialogContext) async {
    final messenger = ScaffoldMessenger.of(widget.rootContext);
    final l = AppLocalizations.of(widget.rootContext);
    final workName = _workNameController.text.trim();
    final hourlyRateText = _hourlySalaryController.text.trim();

    if (workName.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.workNameRequiredMessage)),
      );
      return;
    }

    num hourlyRate = 0;
    if (hourlyRateText.isNotEmpty) {
      final parsedRate = double.tryParse(hourlyRateText.replaceAll(',', ''));
      if (parsedRate == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.invalidHourlyRateMessage)),
        );
        return;
      }
      if (parsedRate < 0) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.hourlyRateNegativeValidation)),
        );
        return;
      }
      hourlyRate = parsedRate;
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
        }
      },
      builder: (blocContext, state) {
        final isSaving = state.addStatus == WorkActionStatus.inProgress;

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

                                  Text(
                                    l.workNameLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color:
                                      const Color(0xFF0F172A),
                                    ) ??
                                        const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xFF0F172A),
                                        ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextField(
                                    controller: _workNameController,
                                    textInputAction: TextInputAction.next,
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
                                  ),

                                  const SizedBox(height: 16),

                                  Text(
                                    l.hourlySalaryLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color:
                                      const Color(0xFF0F172A),
                                    ) ??
                                        const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xFF0F172A),
                                        ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextField(
                                    controller: _hourlySalaryController,
                                    keyboardType:
                                    const TextInputType.numberWithOptions(
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
                                        '💼',
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
                                            color: Color(0xFF0F172A),
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
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xFF1E40AF),
                                            Color(0xFF0EA5E9),
                                          ],
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(30),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
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
                                            '+',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
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
                                    Text(
                                      '${l.contractWorkLabel} (${_pendingContractWorks.length})',
                                      style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1F2937),
                                              ) ??
                                          const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1F2937),
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Column(
                                      children: List.generate(
                                        _pendingContractWorks.length,
                                        (index) => Padding(
                                          padding:
                                              EdgeInsets.only(bottom: index == _pendingContractWorks.length - 1 ? 0 : 12),
                                          child: _buildPendingContractWorkTile(
                                            index: index,
                                            work: _pendingContractWorks[index],
                                            l: l,
                                          ),
                                        ),
                                      ),
                                    ),
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
                                    onPressed: isSaving
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
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
  List<ContractType> _contractTypes = <ContractType>[];
  bool _isLoadingContractTypes = false;
  String? _contractTypesError;

  @override
  void initState() {
    super.initState();
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
        (source ?? widget.work.additionalData as Map<String, dynamic>?) ??
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
    final rate = widget.work.hourlyRate;
    if (rate == null) {
      return l.notAvailableLabel;
    }
    final symbol = _resolveCurrencySymbol();
    final formatted = rate.toDouble().toStringAsFixed(2);
    final prefix = symbol ?? '£';
    return '$prefix$formatted/hour';
  }

  String _deriveUnitWatermark(ContractType type) {
    final Map<String, dynamic> data =
        type.additionalData ?? const <String, dynamic>{};

    final watermarkKeys = <String>[
      'watermark',
      'unitWatermark',
      'unit_watermark',
      'unit_display',
      'unitDisplay',
      'unit_label_display',
    ];
    for (final k in watermarkKeys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) {
        return v.trim();
      }
    }

    num? qty;
    final qtyKeys = <String>[
      'unit_quantity',
      'unitQuantity',
      'quantity',
      'qty',
      'per_count',
      'perCount',
      'count',
      'units',
      'unit_size',
      'unitSize',
      'bundle_size',
      'bundleSize',
    ];
    for (final k in qtyKeys) {
      final v = data[k];
      if (v is num) {
        qty = v;
        break;
      } else if (v is String) {
        final parsed = num.tryParse(v);
        if (parsed != null) {
          qty = parsed;
          break;
        }
      }
    }

    String? unitName;
    final unitKeys = <String>[
      'unit_name',
      'unitName',
      'unit',
      'unit_type',
      'unitType',
      'unit_display',
      'unitDisplay',
      'role',
      'type',
      'role_name',
      'roleName',
    ];
    for (final k in unitKeys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) {
        unitName = v.trim();
        break;
      }
    }

    if (qty != null && unitName != null && unitName.isNotEmpty) {
      final formattedQty = _formatQuantity(qty);
      final normalizedUnit = _normalizeUnitLabel(unitName, qty);
      return 'per $formattedQty $normalizedUnit';
    }

    final parsedUnitLabel = _extractQuantityAndUnitFromText(type.unitLabel);
    qty ??= parsedUnitLabel.$1;
    unitName ??= parsedUnitLabel.$2;

    final parsedName = _extractQuantityAndUnitFromText(type.name);
    qty ??= parsedName.$1;
    unitName ??= parsedName.$2;

    if ((unitName == null || unitName.isEmpty) &&
        (type.role?.trim().isNotEmpty ?? false)) {
      unitName = type.role!.trim();
    }

    if (qty == null && unitName != null && unitName.isNotEmpty) {
      qty = 1;
    }

    if (qty != null && (unitName != null && unitName.isNotEmpty)) {
      final formattedQty = _formatQuantity(qty);
      final normalizedUnit = _normalizeUnitLabel(unitName, qty);
      return 'per $formattedQty $normalizedUnit';
    }

    if (qty != null && (unitName == null || unitName.isEmpty)) {
      final formattedQty = _formatQuantity(qty);
      final normalizedUnit = _normalizeUnitLabel('unit', qty);
      return 'per $formattedQty $normalizedUnit';
    }

    final label = (type.unitLabel ?? '').trim();
    if (label.isNotEmpty && label.toLowerCase() != 'per unit') {
      return label;
    }

    return 'per 1 ${_normalizeUnitLabel('unit', 1)}';
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

  String _formatContractRate(ContractType type) {
    final symbol =
        _resolveCurrencySymbol(type.additionalData) ?? _resolveCurrencySymbol() ?? '£';
    final formattedRate = type.rate.toStringAsFixed(2);
    final watermark = _deriveUnitWatermark(type);
    return '$symbol$formattedRate / $watermark';
  }

  Future<void> _navigateToContractWorkScreen() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(widget.rootContext);
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

      await showModalBottomSheet<void>(
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
            workId: widget.work.id,
          );
        },
      );

      if (!mounted) {
        return;
      }
      await _loadContractTypes();
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.message.trim().isEmpty
          ? l.contractWorkLoadError
          : error.message;
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l.contractWorkLoadError)),
      );
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
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(content: Text(l.contractWorkTypeDeletedMessage)),
      );
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
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          SnackBar(content: Text(l.contractWorkTypeDeletedMessage)),
        );
        return;
      }
      final message = error.message.trim().isEmpty
          ? l.contractWorkTypeDeleteFailedMessage
          : error.message;
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          SnackBar(content: Text(l.contractWorkTypeDeletedMessage)),
        );
        return;
      }
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(content: Text(l.contractWorkTypeDeleteFailedMessage)),
      );
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
            widget.work.name,
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

  List<_WorkContractDisplay> _resolveWorkContracts() {
    final l = AppLocalizations.of(widget.rootContext);
    final currencyPrefix = _resolveCurrencySymbol() ?? '£';
    final items = <_WorkContractDisplay>[];

    void addItem(String? rawTitle, String? rawSubtitle) {
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
          title: resolvedTitle,
          subtitle: resolvedSubtitle,
        ),
      );
    }

    final rawContracts = widget.work.additionalData['contracts'];
    if (rawContracts is List) {
      for (final raw in rawContracts) {
        if (raw is Map) {
          final map = <String, dynamic>{};
          raw.forEach((key, value) {
            map[key.toString()] = value;
          });

          final name = _normalizeWorkContractText(map['name']) ??
              _normalizeWorkContractText(map['title']);
          final type = _normalizeWorkContractText(map['type']) ??
              _normalizeWorkContractText(map['role']);
          final combinedTitle = _combineWorkContractTitle(name, type);
          final rate = _parseWorkContractRate(map);
          final rawPrice = _normalizeWorkContractText(map['price']);
          final unitLabel = _extractWorkContractUnitLabel(map);

          var subtitle = '';
          if (rate != null) {
            subtitle =
                _formatCurrencyDisplay(rate.toStringAsFixed(2), currencyPrefix);
          } else if (rawPrice != null && rawPrice.isNotEmpty) {
            subtitle = rawPrice;
          }

          if (unitLabel != null && unitLabel.isNotEmpty) {
            subtitle = subtitle.isEmpty
                ? unitLabel
                : '$subtitle ${unitLabel.trim()}';
          }

          final resolvedTitle = combinedTitle.isNotEmpty
              ? combinedTitle
              : (name ?? type ?? '');
          addItem(resolvedTitle, subtitle);
        }
      }
    }

    if (items.isNotEmpty) {
      return items;
    }

    final legacyItems = widget.work.additionalData['contractItems'];
    if (legacyItems is List) {
      for (final raw in legacyItems) {
        if (raw is Map) {
          final map = <String, dynamic>{};
          raw.forEach((key, value) {
            map[key.toString()] = value;
          });
          final title = _normalizeWorkContractText(map['title']);
          final subtitle = _normalizeWorkContractText(map['price']);
          addItem(title, subtitle);
        }
      }
    }

    return items;
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

  String _formatCurrencyDisplay(String value, String prefix) {
    final trimmedValue = value.trim();
    final trimmedPrefix = prefix.trim();
    if (trimmedValue.isEmpty) {
      return trimmedPrefix.isEmpty ? value : trimmedPrefix;
    }
    if (trimmedPrefix.isEmpty) {
      return trimmedValue;
    }
    final addSpace =
        prefix.trimRight() != prefix || trimmedPrefix.length > 1;
    return addSpace ? '$trimmedPrefix $trimmedValue' : '$trimmedPrefix$trimmedValue';
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
                  _formatContractRate(type),
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
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFFB91C1C),
                ),
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
    final workContracts = _resolveWorkContracts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildWorkInfoSection(context),
        const SizedBox(height: 16),
        if (workContracts.isNotEmpty) ...[
          _WorkContractList(items: workContracts),
          const SizedBox(height: 16),
        ],
        GestureDetector(
          onTap: _navigateToContractWorkScreen,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  Theme.of(context).colorScheme.primary.withOpacity(0.25),
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
    );
  }

  Future<void> _handleDeleteWork(BuildContext dialogContext) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l = AppLocalizations.of(widget.rootContext);
    final bloc = widget.rootContext.read<WorkBloc>();

    if (bloc.state.deletingWorkId != null &&
        bloc.state.deletingWorkId != widget.work.id) {
      return;
    }

    final shouldDelete = await _showDeleteConfirmationDialog(dialogContext, l);
    if (!shouldDelete || !mounted) {
      return;
    }

    final completer = Completer<bool>();
    bloc.add(WorkDeleted(work: widget.work, completer: completer));
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
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
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
        final isDeleting = state.deletingWorkId == widget.work.id;
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      Color(0xFFB91C1C),
                                    ),
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
  const _WorkContractList({required this.items});

  final List<_WorkContractDisplay> items;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    items[i].title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    items[i].subtitle,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkContractDisplay {
  const _WorkContractDisplay({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

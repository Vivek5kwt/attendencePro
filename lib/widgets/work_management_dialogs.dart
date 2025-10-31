import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/contract_type.dart';
import '../models/work.dart';
import '../repositories/contract_type_repository.dart';
import '../screens/contract_work_screen.dart';

Future<void> showAddWorkDialog({required BuildContext context}) async {
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
  const _AddWorkDialog({
    required this.rootContext,
  });

  final BuildContext rootContext;

  @override
  State<_AddWorkDialog> createState() => _AddWorkDialogState();
}

class _AddWorkDialogState extends State<_AddWorkDialog> {
  late final TextEditingController _workNameController;
  late final TextEditingController _hourlySalaryController;

  @override
  void initState() {
    super.initState();
    _workNameController = TextEditingController();
    _hourlySalaryController = TextEditingController();
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
    widget.rootContext.read<WorkBloc>().add(
      WorkAdded(
        name: workName,
        hourlyRate: hourlyRate,
        isContract: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(widget.rootContext);

    return BlocConsumer<WorkBloc, WorkState>(
      listenWhen: (previous, current) => previous.addStatus != current.addStatus,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: SingleChildScrollView(
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
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
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F9FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 35,
                              width: 35,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE5F1FF),
                              ),
                              child: Image.asset(AppAssets.clock),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l.hourlyWorkLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
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
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _workNameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: l.workNameHint,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: Color(0xFF007BFF)),
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
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: Color(0xFF007BFF)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () async {
                            await Navigator.of(
                              context,
                              rootNavigator: true,
                            ).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                const ContractWorkScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF1D4ED8),
                            side: const BorderSide(
                                color: Color(0xFF2563EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.work_outline_rounded,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l.addContractWorkButton,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                          onPressed: () {
                            _clearForm();
                            blocContext
                                .read<WorkBloc>()
                                .add(const WorkAddStatusCleared());
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            l.cancelButton,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
                            backgroundColor: const Color(0xFF007BFF),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
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
  }
}

Future<void> showEditWorkDialog({
  required BuildContext context,
  required Work work,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (dialogContext) {
      return _EditWorkDialog(rootContext: context, work: work);
    },
  );
}

class _EditWorkDialog extends StatefulWidget {
  const _EditWorkDialog({
    required this.rootContext,
    required this.work,
  });

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
      final result =
      await _contractTypeRepository.fetchContractTypes();
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
        _contractTypesError = message.isEmpty
            ? l.contractWorkLoadError
            : message;
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
    final data = source ?? widget.work.additionalData;
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
    final prefix = symbol ?? '€';
    return '$prefix$formatted/hour';
  }

  String _formatContractRate(ContractType type) {
    final symbol = _resolveCurrencySymbol(type.additionalData) ??
        _resolveCurrencySymbol() ??
        '€';
    final formatted = type.rate.toStringAsFixed(2);
    final unit = type.unitLabel.trim();
    if (unit.isEmpty) {
      return '$symbol$formatted';
    }
    return '$symbol$formatted/${unit.toLowerCase()}';
  }

  Future<void> _navigateToContractWorkScreen() async {
    FocusScope.of(context).unfocus();
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(
      MaterialPageRoute<void>(
        builder: (contractContext) {
          return ContractWorkScreen(
            work: widget.work,
            allowEditing: false,
          );
        },
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadContractTypes();
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
        _contractTypes
            .removeWhere((item) => item.id == type.id);
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
      final exists =
      await _refreshContractTypesAfterDeleteAttempt(type.id);
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
      final exists =
      await _refreshContractTypesAfterDeleteAttempt(type.id);
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
        SnackBar(
            content: Text(
                l.contractWorkTypeDeleteFailedMessage)),
      );
    }
  }

  Future<bool> _refreshContractTypesAfterDeleteAttempt(
      String contractTypeId) async {
    try {
      final result =
      await _contractTypeRepository.fetchContractTypes();
      if (!mounted) {
        return false;
      }
      final updatedTypes = result.userTypes;
      setState(() {
        _contractTypes = updatedTypes;
        _contractTypesError = null;
      });
      return updatedTypes
          .any((type) => type.id == contractTypeId);
    } on ContractTypeRepositoryException {
      return true;
    } catch (_) {
      return true;
    }
  }

  // ——————————————————
  // WORK HEADER CARD  (Blue box like "Farm Fresh Ltd.")
  // ——————————————————
  Widget _buildWorkInfoSection(BuildContext context) {
    final hourlyText =
        'Hourly Rate: ${_formatHourlyRate(AppLocalizations.of(widget.rootContext))}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // very light blue fill
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF93C5FD), // light blue border
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Work name bold blue
          Text(
            widget.work.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8), // strong blue title
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Hourly rate grey/blue small
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

  // ——————————————————
  // CONTRACT TILE  (Cream box like "Orange  €5/crate   X")
  // ——————————————————
  Widget _buildContractTypeTile(
      BuildContext context,
      AppLocalizations l,
      ContractType type,
      ) {
    final isDeleting = _deletingContractTypeIds.contains(type.id);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // soft cream / light orange
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFACC15), // warm orange/yellow border
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texts (name + rate)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contract item name (e.g. "Orange")
                Text(
                  type.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C2D12), // dark orange/brown-ish title
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Rate per unit (e.g. "€5/crate")
                Text(
                  _formatContractRate(type),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280), // gray text
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Trailing delete "X"
          if (isDeleting)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFFB91C1C)),
              ),
            )
          else
            InkWell(
              onTap: () =>
                  _confirmAndDeleteContractType(context, type),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFFB91C1C), // red X
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ——————————————————
  // SECTION combining:
  //   "My Workplace" title row,
  //   blue workplace card,
  //   orange "Contract Work" pill button,
  //   contract tiles list
  // ——————————————————
  Widget _buildContractSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row "My Workplace" with small emoji-like icon
        Row(
          children: [
            const Icon(
              Icons.apartment_rounded,
              color: Color(0xFF1E293B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'My Workplace',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ) ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Blue workplace info card
        _buildWorkInfoSection(context),

        const SizedBox(height: 16),

        // Orange button "Contract Work"
        GestureDetector(
          onTap: _navigateToContractWorkScreen,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316), // orange fill
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFEA580C),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '📑',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Contract Work',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ) ??
                        const TextStyle(
                          fontSize: 15,
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

        const SizedBox(height: 16),

        // Contract items list
        if (_isLoadingContractTypes)
          const Center(
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          )
        else if (_contractTypesError != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _contractTypesError!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB91C1C),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadContractTypes,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          )
        else if (_contractTypes.isEmpty)
            const Text(
              'No contract work added.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            )
          else
            Column(
              children: _contractTypes
                  .map(
                    (type) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildContractTypeTile(
                    context,
                    AppLocalizations.of(widget.rootContext),
                    type,
                  ),
                ),
              )
                  .toList(),
            ),
      ],
    );
  }

  // ——————————————————
  // MAIN BUILD DIALOG
  // ——————————————————
  Future<void> _handleDeleteWork(BuildContext dialogContext) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l = AppLocalizations.of(widget.rootContext);
    final bloc = widget.rootContext.read<WorkBloc>();

    if (bloc.state.deletingWorkId != null &&
        bloc.state.deletingWorkId != widget.work.id) {
      return;
    }

    final shouldDelete =
    await _showDeleteConfirmationDialog(dialogContext, l);
    if (!shouldDelete || !mounted) {
      return;
    }

    final completer = Completer<bool>();
    bloc.add(WorkDeleted(
        work: widget.work, completer: completer));
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
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius:
                          BorderRadius.circular(20),
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
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.workDeleteConfirmationTitle,
                              style: theme
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight:
                                FontWeight.w700,
                              ) ??
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.w700,
                                    fontSize: 20,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.workDeleteConfirmationMessage,
                              style: theme
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: const Color(
                                    0xFF6B7280),
                                height: 1.5,
                              ) ??
                                  const TextStyle(
                                    color:
                                    Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context)
                                .pop(false),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding:
                    const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFFFF7ED),
                      borderRadius:
                      BorderRadius.circular(22),
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFF97316),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l.workDeleteIrreversibleMessage,
                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color:
                              const Color(
                                  0xFF9A3412),
                              height: 1.4,
                            ) ??
                                const TextStyle(
                                  color: Color(
                                      0xFF9A3412),
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
                          onPressed: () =>
                              Navigator.of(context)
                                  .pop(false),
                          style: OutlinedButton
                              .styleFrom(
                            padding: const EdgeInsets
                                .symmetric(
                              vertical: 16,
                            ),
                            side: BorderSide(
                              color: theme
                                  .colorScheme
                                  .primary,
                            ),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(24),
                            ),
                          ),
                          child: Text(
                            l.workDeleteCancelButton,
                            style: TextStyle(
                              color: theme
                                  .colorScheme
                                  .primary,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context)
                                  .pop(true),
                          style: ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                                0xFFB91C1C),
                            padding: const EdgeInsets
                                .symmetric(
                              vertical: 16,
                            ),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(24),
                            ),
                          ),
                          child: Text(
                            l.workDeleteConfirmButton,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                              color: Colors
                                  .white,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ) ??
                                const TextStyle(
                                  color: Colors
                                      .white,
                                  fontWeight:
                                  FontWeight
                                      .w700,
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
        final isDeleting =
            state.deletingWorkId == widget.work.id;
        final theme = Theme.of(context);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 24),
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (layoutContext, constraints) {
              final maxWidth = constraints.maxWidth
                  .clamp(0.0, 420.0)
                  .toDouble();
              return Center(
                child: ConstrainedBox(
                  constraints:
                  BoxConstraints(maxWidth: maxWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF8FBFF),
                          Color(0xFFFFFFFF)
                        ],
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
                      borderRadius:
                      BorderRadius.circular(28),
                      child: SingleChildScrollView(
                        padding:
                        const EdgeInsets.fromLTRB(
                            24, 24, 24, 28),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Container(
                                  padding:
                                  const EdgeInsets
                                      .all(14),
                                  decoration:
                                  BoxDecoration(
                                    color: const Color(
                                        0xFFE0EDFF),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                        20),
                                  ),
                                  child: const Icon(
                                    Icons.edit_square,
                                    color: Color(
                                        0xFF1D4ED8),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(
                                    width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        l.editWorkDetailsTitle,
                                        style: theme
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                          fontWeight:
                                          FontWeight
                                              .w700,
                                        ) ??
                                            const TextStyle(
                                              fontWeight:
                                              FontWeight
                                                  .w700,
                                              fontSize:
                                              20,
                                            ),
                                      ),
                                      const SizedBox(
                                          height: 6),
                                      Text(
                                        l.editWorkDetailsSubtitle,
                                        style: theme
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          color:
                                          const Color(
                                              0xFF6B7280),
                                          height:
                                          1.5,
                                        ) ??
                                            const TextStyle(
                                              color: Color(
                                                  0xFF6B7280),
                                              height:
                                              1.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.of(
                                          context)
                                          .pop(),
                                  icon: const Icon(
                                      Icons.close),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: 24),

                            // workplace card + contract list layout
                            _buildContractSection(
                                context),

                            const SizedBox(
                                height: 24),

                            // delete work button
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: isDeleting
                                    ? null
                                    : () =>
                                    _handleDeleteWork(
                                        context),
                                style: TextButton
                                    .styleFrom(
                                  foregroundColor:
                                  const Color(
                                      0xFFB91C1C),
                                  padding: const EdgeInsets
                                      .symmetric(
                                    vertical: 14,
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                        24),
                                  ),
                                ),
                                child: isDeleting
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth:
                                    2.5,
                                    valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                      Color(
                                          0xFFB91C1C),
                                    ),
                                  ),
                                )
                                    : Row(
                                  mainAxisSize:
                                  MainAxisSize
                                      .min,
                                  children: [
                                    const Icon(Icons
                                        .delete_outline),
                                    const SizedBox(
                                        width:
                                        8),
                                    Text(
                                      l.deleteWorkButton,
                                      style: theme
                                          .textTheme
                                          .labelLarge
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

                            const SizedBox(
                                height: 12),

                            // close button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isDeleting
                                    ? null
                                    : () => Navigator.of(
                                    context)
                                    .pop(),
                                style: ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                  const Color(
                                      0xFF2563EB),
                                  padding: const EdgeInsets
                                      .symmetric(
                                    vertical: 16,
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                        24),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  l.close,
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .w700,
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

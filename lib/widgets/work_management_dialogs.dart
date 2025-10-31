import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/work.dart';
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
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Color(0xFF007BFF)),
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
                          keyboardType: const TextInputType.numberWithOptions(
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
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Color(0xFF007BFF)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.of(
                              context,
                              rootNavigator: true,
                            ).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ContractWorkScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF1D4ED8),
                            side: const BorderSide(color: Color(0xFF2563EB)),
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
                          icon: const Icon(Icons.work_outline_rounded, size: 18),
                          label: Text(l.addContractWorkButton),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                          onPressed:
                              isSaving ? null : () => _handleSaveWork(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
  late final TextEditingController _nameController;
  late final TextEditingController _hourlyController;
  late final ValueNotifier<bool> _isContractNotifier;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.work.name);
    _hourlyController =
        TextEditingController(text: widget.work.hourlyRate?.toString() ?? '');
    _isContractNotifier = ValueNotifier<bool>(widget.work.isContract);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hourlyController.dispose();
    _isContractNotifier.dispose();
    super.dispose();
  }

  InputDecoration _buildTextFieldDecoration({
    required BuildContext context,
    required String hintText,
    Widget? prefixIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outlineColor = isDark
        ? theme.colorScheme.outline.withOpacity(0.4)
        : const Color(0xFFE5E7EB);
    final fillColor = isDark
        ? theme.colorScheme.surfaceVariant.withOpacity(0.35)
        : Colors.white;

    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      prefixIconColor: theme.colorScheme.primary,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: outlineColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: outlineColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
        ),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(
          color: Color(0xFFDC2626),
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildElevatedInputSurface({
    required BuildContext context,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outlineColor = isDark
        ? theme.colorScheme.outline.withOpacity(0.4)
        : const Color(0xFFE5E7EB);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              color: Color(0x14374151),
              blurRadius: 32,
              offset: Offset(0, 12),
              spreadRadius: -8,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Future<void> _handleUpdateWork(BuildContext dialogContext) async {
    final messenger = ScaffoldMessenger.of(widget.rootContext);
    final l = AppLocalizations.of(widget.rootContext);
    final workName = _nameController.text.trim();

    if (workName.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.workNameRequiredMessage)),
      );
      return;
    }

    FocusScope.of(dialogContext).unfocus();
    widget.rootContext.read<WorkBloc>().add(
          WorkUpdated(
            work: widget.work,
            name: workName,
            hourlyRate: widget.work.hourlyRate ?? 0,
            isContract: widget.work.isContract,
          ),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.colorScheme.primary),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            l.workDeleteConfirmButton,
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
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

    return BlocConsumer<WorkBloc, WorkState>(
      listenWhen: (previous, current) =>
          previous.updateStatus != current.updateStatus,
      listener: (blocContext, state) {
        if (state.updateStatus == WorkActionStatus.success) {
          Navigator.of(context).pop();
          blocContext
              .read<WorkBloc>()
              .add(const WorkUpdateStatusCleared());
        }
      },
      builder: (blocContext, state) {
        final isSaving = state.updateStatus == WorkActionStatus.inProgress;
        final isDeleting = state.deletingWorkId == widget.work.id;
        final isProcessing = isSaving || isDeleting;
        final theme = Theme.of(context);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                      color: const Color(0xFFE0EDFF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.edit_square,
                                      color: Color(0xFF1D4ED8),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.editWorkDetailsTitle,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ) ??
                                              const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 20,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l.editWorkDetailsSubtitle,
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
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      blocContext
                                          .read<WorkBloc>()
                                          .add(const WorkUpdateStatusCleared());
                                    },
                                    icon: const Icon(Icons.close),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildElevatedInputSurface(
                                context: context,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.workNameLabel,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ) ??
                                          const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _nameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: _buildTextFieldDecoration(
                                        context: context,
                                        hintText: l.workNameHint,
                                        prefixIcon:
                                            const Icon(Icons.badge_outlined),
                                      ),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return l.workNameRequiredMessage;
                                        }
                                        if (trimmed.length < 3) {
                                          return l.workNameTooShortValidation;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      l.hourlySalaryLabel,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ) ??
                                          const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _hourlyController,
                                      enabled: false,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: _buildTextFieldDecoration(
                                        context: context,
                                        hintText: l.hourlySalaryHint,
                                        prefixIcon: const Icon(
                                          Icons.payments_outlined,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: _isContractNotifier,
                                      builder: (valueContext, isContract, _) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    l.contractWorkLabel,
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
                                                ),
                                                Switch.adaptive(
                                                  value: isContract,
                                                  onChanged: null,
                                                  activeColor:
                                                      theme.colorScheme.primary,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              l.contractWorkDescription,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                    color: const Color(0xFF6B7280),
                                                    height: 1.5,
                                                  ) ??
                                                  const TextStyle(
                                                    color: Color(0xFF6B7280),
                                                    height: 1.5,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              width: double.infinity,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: <Color>[
                                                      theme.colorScheme.primary,
                                                      Color.lerp(
                                                            theme
                                                                .colorScheme
                                                                .primary,
                                                            theme
                                                                .colorScheme
                                                                .onPrimary,
                                                            0.25,
                                                          ) ??
                                                          theme.colorScheme
                                                              .primary,
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  boxShadow: const <BoxShadow>[
                                                    BoxShadow(
                                                      color: Color(0x33000000),
                                                      blurRadius: 16,
                                                      offset: Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  child: FilledButton.icon(
                                                  onPressed: () {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    Navigator.of(
                                                      context,
                                                      rootNavigator: true,
                                                    ).push(
                                                      MaterialPageRoute(
                                                        builder:
                                                            (contractContext) {
                                                          return ContractWorkScreen(
                                                            work: widget.work,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  style: FilledButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 18,
                                                      horizontal: 20,
                                                    ),
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    foregroundColor: theme
                                                        .colorScheme.onPrimary,
                                                    shadowColor:
                                                        Colors.transparent,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    textStyle: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              24),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.add_task_rounded,
                                                    size: 22,
                                                  ),
                                                  label: Text(
                                                    l.addContractWorkButton,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: isProcessing
                                      ? null
                                      : () => _handleDeleteWork(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFB91C1C),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () {
                                              Navigator.of(context).pop();
                                              blocContext
                                                  .read<WorkBloc>()
                                                  .add(const WorkUpdateStatusCleared());
                                            },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
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
                                      onPressed: isProcessing
                                          ? null
                                          : () async {
                                              if (_formKey.currentState
                                                      ?.validate() ??
                                                  false) {
                                                await _handleUpdateWork(
                                                  context,
                                                );
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
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
                                                        Colors.white),
                                              ),
                                            )
                                          : Text(
                                              l.saveChangesButton,
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


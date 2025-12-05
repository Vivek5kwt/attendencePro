import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_strings.dart';
import '../core/localization/app_localizations.dart';
import '../models/contract_type.dart' as models;
import '../models/pending_contract_work.dart';
import '../models/report_summary.dart';
import '../models/work.dart';
import '../repositories/contract_type_repository.dart';
import '../repositories/reports_repository.dart';
import '../utils/contract_work_display.dart';
import '../utils/contract_unit_label.dart';
import '../utils/responsive.dart';
import '../utils/snackbar.dart';
import '../utils/work_contract_filter.dart';
import '../widgets/app_loader.dart';

const List<String> kContractWorkDefaultRoleOptions = <String>[
  'Bin',
  'Crate',
  'Bunches',
];

const List<String> kContractWorkDefaultWorkNameOptions = <String>[
  'Watermelon',
  'Orange',
  'Radish',
  'Carrot',
  'Ravanello 10 Unit',
  'Ravanello 15 Unit',
  'Ravanello 18 Unit',
  'Ravanello 20 Unit',
  'Custom Work',
];

String contractWorkFormatRoleDisplay(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;

  switch (trimmed.toLowerCase()) {
    case 'bin':
      return 'Bin';
    case 'crate':
      return 'Crate';
    case 'bunches':
      return 'Bunches';
    default:
      return trimmed;
  }
}

List<String> contractWorkBuildAvailableRoles<T>({
  required Iterable<T> globalTypes,
  required Iterable<T> userTypes,
  required String? Function(T type) roleSelector,
  Iterable<String> baseRoleOptions = kContractWorkDefaultRoleOptions,
}) {
  final unique = <String, String>{};

  for (final option in baseRoleOptions) {
    final formatted = contractWorkFormatRoleDisplay(option);
    final key = formatted.toLowerCase();
    unique.putIfAbsent(key, () => formatted);
  }
  void addRole(String? value) {
    final roleValue = value?.trim();
    if (roleValue == null || roleValue.isEmpty) return;

    final formatted = contractWorkFormatRoleDisplay(roleValue);
    final key = formatted.toLowerCase();
    unique.putIfAbsent(key, () => formatted);
  }

  for (final type in globalTypes) {
    addRole(roleSelector(type));
  }

  for (final type in userTypes) {
    addRole(roleSelector(type));
  }

  final sorted = unique.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return sorted;
}

class ContractWorkScreen extends StatefulWidget {
  const ContractWorkScreen({super.key, this.work, this.allowEditing = false});

  final Work? work;
  final bool allowEditing;

  @override
  State<ContractWorkScreen> createState() => _ContractWorkScreenState();
}

class _ContractWorkScreenState extends State<ContractWorkScreen> {
  final ContractTypeRepository _repository = ContractTypeRepository();

  final List<_ContractType> _defaultContractTypes = <_ContractType>[];
  final List<_ContractType> _userContractTypes = <_ContractType>[];
  final List<String> _availableRoles = <String>[];

  final ReportsRepository _reportsRepository = ReportsRepository();

  List<_ContractSummaryRow> _summaryRows = const <_ContractSummaryRow>[];
  bool _isLoadingSummary = false;
  String? _summaryError;
  double _summaryTotalUnits = 0;
  double _summarySalaryAmount = 0;

  final Set<String> _pendingDeletionIds = <String>{};

  bool _isLoading = true;
  String? _errorMessage;

  void _showSnack(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    AppSnackBar.show(context, trimmed, backgroundColor: backgroundColor);
  }

  @override
  void initState() {
    super.initState();
    _loadContractTypes();
    _loadContractSummary();
  }

  @override
  void didUpdateWidget(covariant ContractWorkScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.work?.id != widget.work?.id) {
      _loadContractSummary();
    }
  }

  Future<void> _loadContractTypes({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      final result = await _repository.fetchContractTypes();
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      final filteredUserTypes = _filterContractTypesForCurrentWork(
        result.userTypes,
      );

      setState(() {
        _defaultContractTypes
          ..clear()
          ..addAll(
            result.globalTypes.map(
                  (type) => _ContractType.fromModel(type: type),
            ),
          );

        _userContractTypes
          ..clear()
          ..addAll(
            filteredUserTypes.map(
              (type) => _withWorkAssociation(
                _ContractType.fromModel(
                  type: type,
                  isUserDefined: true,
                ),
              ),
            ),
          );

        _syncAvailableRoles();

        _summaryRows =
            _buildSummaryRowsFromTypes(_userContractTypes, localizations);
        _summaryError = null;

        _pendingDeletionIds.clear();
        if (showLoader) {
          _isLoading = false;
        }
      });
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) return;
      if (showLoader) {
        setState(() {
          _errorMessage = error.message;
          _isLoading = false;
        });
      } else {
        final l = AppLocalizations.of(context);
        final message = error.message.trim().isEmpty
            ? l.contractWorkLoadError
            : error.message;
        _showSnack(message);
      }
    } catch (error) {
      if (!mounted) return;
      if (showLoader) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      } else {
        final l = AppLocalizations.of(context);
        _showSnack(l.contractWorkLoadError);
      }
    }
  }

  Future<void> _loadContractSummary({bool showLoader = true}) async {
    final work = widget.work;
    if (work == null) {
      setState(() {
        _summaryTotalUnits = 0;
        _summarySalaryAmount = 0;
        _isLoadingSummary = false;
        _summaryError = null;
      });
      return;
    }

    setState(() {
      if (showLoader) {
        _isLoadingSummary = true;
      }
      _summaryError = null;
    });

    try {
      final now = DateTime.now();
      final summary = await _reportsRepository.fetchSummary(
        workId: work.id,
        month: now.month,
        year: now.year,
      );

      if (!mounted) return;

      final localizations = AppLocalizations.of(context);
      final computedRows = _buildSummaryRows(summary, localizations);
      final resolvedTotalUnits = computedRows.totalUnits > 0
          ? computedRows.totalUnits
          : summary.contractSummary.totalUnits.toDouble();
      final resolvedSalary = computedRows.totalSalary > 0
          ? computedRows.totalSalary
          : summary.contractSummary.salaryAmount;

      setState(() {
        _summaryRows = computedRows.rows;
        _summaryTotalUnits = resolvedTotalUnits;
        _summarySalaryAmount = resolvedSalary;
        _isLoadingSummary = false;
      });
    } on ReportsRepositoryException catch (error) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final message =
      error.message.trim().isEmpty ? l.contractWorkLoadError : error.message;
      setState(() {
        _summaryTotalUnits = 0;
        _summarySalaryAmount = 0;
        _isLoadingSummary = false;
        _summaryError = message;
      });
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      setState(() {
        _summaryTotalUnits = 0;
        _summarySalaryAmount = 0;
        _isLoadingSummary = false;
        _summaryError = l.contractWorkLoadError;
      });
    }
  }

  List<_ContractSummaryRow> _buildSummaryRowsFromTypes(
    List<_ContractType> types,
    AppLocalizations l,
  ) {
    if (types.isEmpty) return const <_ContractSummaryRow>[];
    return List<_ContractSummaryRow>.generate(types.length, (i) {
      final t = types[i];
      final metadata = t.additionalData;
      final fallbackUnitLabel = _summaryExtractContractUnitLabel(metadata) ??
          (t.unitLabel.isNotEmpty ? t.unitLabel : null);
      final count = _normalizeContractUnits(
        _summaryExtractContractCount(metadata),
        title: t.name,
        unitLabel: fallbackUnitLabel,
        role: t.role,
      );
      final resolvedUnitLabel =
          fallbackUnitLabel?.trim().isNotEmpty == true
              ? fallbackUnitLabel!
              : l.contractWorkUnitFallback;
      final currencySymbol =
          _summaryExtractCurrencySymbol(metadata) ?? '€';
      String? unitsLabel;
      if (count != null) {
        final displayCount =
            count % 1 == 0 ? count.toInt().toString() : count.toString();
        final unitDisplay =
            resolvedUnitLabel.trim().isEmpty ? l.contractWorkUnitsLabel : resolvedUnitLabel;
        unitsLabel = '$displayCount $unitDisplay';
      }
      final paymentAmount = count != null ? t.rate * count : null;
      final paymentLabel = paymentAmount != null
          ? _formatCurrencyValue(paymentAmount, currencySymbol)
          : l.notAvailableLabel;
      return _ContractSummaryRow(
        index: i + 1,
        workName: _formatWorkNameWithRole(t.name, t.role),
        units: unitsLabel ?? l.notAvailableLabel,
        payment: paymentLabel,
      );
    });
  }

  String? _normalizeSummaryRole(String? role) {
    final trimmed = role?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return contractWorkFormatRoleDisplay(trimmed);
  }

  String _formatWorkNameWithRole(String workName, String? role) {
    final normalizedRole = _normalizeSummaryRole(role);
    if (normalizedRole == null) {
      return workName;
    }
    return '$workName · $normalizedRole';
  }

  _ContractSummaryComputation _buildSummaryRows(
    ReportSummary summary,
    AppLocalizations l,
  ) {
    final items = summary.contractSummary.items;
    if (items.isEmpty) {
      return const _ContractSummaryComputation(
        rows: <_ContractSummaryRow>[],
        totalUnits: 0,
        totalSalary: 0,
      );
    }

    final normalizedSymbol = summary.currencySymbol.trim().isEmpty
        ? '€'
        : summary.currencySymbol;
    final aggregations = <String, _ContractSummaryAggregation>{};

    num? _extractUnits(ContractWorkItemData data) {
      return _normalizeContractUnits(
            data.unitCount,
            title: data.title,
            unitLabel: data.unitLabel,
            role: data.unitRole,
          ) ??
          _normalizeContractUnits(
            data.unitsCompleted,
            title: data.title,
            unitLabel: data.unitLabel,
            role: data.unitRole,
          ) ??
          _normalizeContractUnits(
            data.unitsTotal,
            title: data.title,
            unitLabel: data.unitLabel,
            role: data.unitRole,
          ) ??
          _normalizeContractUnits(
            data.unitsPending,
            title: data.title,
            unitLabel: data.unitLabel,
            role: data.unitRole,
          );
    }

    for (final item in items) {
      final workName = item.title.trim().isEmpty
          ? l.notAvailableLabel
          : item.title.trim();
      final role = _normalizeSummaryRole(item.unitRole);
      final key = '${workName.toLowerCase()}|${role?.toLowerCase() ?? ''}';
      final aggregation = aggregations.putIfAbsent(
        key,
        () => _ContractSummaryAggregation(
          workName: workName,
          role: role,
        ),
      );

      aggregation.role ??= role;
      final units = _extractUnits(item);
      if (units != null) {
        aggregation.totalUnits += units;
      }

      if (item.ratePerUnit != null && item.ratePerUnit! > 0) {
        aggregation.ratePerUnit ??= item.ratePerUnit;
      }

      final fallbackUnitLabel = (item.unitLabel?.trim().isNotEmpty ?? false)
          ? item.unitLabel!.trim()
          : l.contractWorkUnitFallback;
      aggregation.unitLabel ??= fallbackUnitLabel;

      if (item.amount > 0) {
        aggregation.amount += item.amount;
      }
    }

    final rows = <_ContractSummaryRow>[];
    var totalUnits = 0.0;
    var totalSalary = 0.0;
    var rowIndex = 1;

    for (final aggregation in aggregations.values) {
      late final String unitsLabel;
      if (aggregation.totalUnits > 0) {
        final displayUnits = aggregation.totalUnits % 1 == 0
            ? aggregation.totalUnits.toInt().toString()
            : aggregation.totalUnits.toString();
        final unitLabel = (aggregation.unitLabel ?? l.contractWorkUnitsLabel).trim();
        final resolvedUnitLabel =
            unitLabel.isEmpty ? l.contractWorkUnitsLabel : unitLabel;
        unitsLabel = '$displayUnits $resolvedUnitLabel';
      } else {
        unitsLabel = l.notAvailableLabel;
      }

      double? paymentAmount;
      if (aggregation.ratePerUnit != null && aggregation.totalUnits > 0) {
        paymentAmount = aggregation.ratePerUnit! * aggregation.totalUnits;
      } else if (aggregation.amount > 0) {
        paymentAmount = aggregation.amount;
      }

      final paymentLabel = paymentAmount != null
          ? _formatCurrencyValue(paymentAmount, normalizedSymbol)
          : l.notAvailableLabel;

      if (aggregation.totalUnits > 0) {
        totalUnits += aggregation.totalUnits;
      }
      if (paymentAmount != null) {
        totalSalary += paymentAmount;
      }

      rows.add(
        _ContractSummaryRow(
          index: rowIndex++,
          workName: _formatWorkNameWithRole(
            aggregation.workName,
            aggregation.role,
          ),
          units: unitsLabel,
          payment: paymentLabel,
        ),
      );
    }

    return _ContractSummaryComputation(
      rows: rows,
      totalUnits: totalUnits,
      totalSalary: totalSalary,
    );
  }

  num? _summaryExtractContractCount(Map<String, dynamic> data) {
    if (data.isEmpty) return null;
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
      final parsed = _summaryParseNumericValue(data[key]);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  bool _isHundredBunchContract({
    required String? title,
    required String? unitLabel,
    required String? role,
  }) {
    final normalizedTitle = title?.toLowerCase() ?? '';
    final normalizedUnitLabel = unitLabel?.toLowerCase() ?? '';
    final normalizedRole = role?.toLowerCase() ?? '';

    if (normalizedRole == 'bunches') {
      return true;
    }

    final mentionsBunch = normalizedTitle.contains('bunch') ||
        normalizedUnitLabel.contains('bunch') ||
        normalizedUnitLabel.contains('mazz') ||
        normalizedTitle.contains('mazz') ||
        normalizedTitle.contains('ravanello') ||
        normalizedUnitLabel.contains('ravanello');
    if (!mentionsBunch) {
      return false;
    }

    final mentionsHundred = normalizedUnitLabel.contains('100') ||
        normalizedUnitLabel.contains('hundred') ||
        normalizedTitle.contains('100') ||
        normalizedTitle.contains('cento');

    return mentionsHundred || normalizedRole == 'bunches';
  }

  num? _normalizeContractUnits(
    num? value, {
    required String? title,
    required String? unitLabel,
    required String? role,
  }) {
    if (value == null) {
      return null;
    }
    final doubleValue = value.toDouble();
    if (doubleValue.isNaN || doubleValue.isInfinite) {
      return null;
    }
    if (doubleValue < 0) {
      return null;
    }

    if (_isHundredBunchContract(
      title: title,
      unitLabel: unitLabel,
      role: role,
    )) {
      final normalized = doubleValue / 100;
      if (normalized % 1 == 0) {
        return normalized.toInt();
      }
      return double.parse(normalized.toStringAsFixed(2));
    }

    return doubleValue.round();
  }

  String? _summaryExtractContractUnitLabel(Map<String, dynamic> data) {
    if (data.isEmpty) return null;
    const keys = <String>[
      'unit_label',
      'unitLabel',
      'unit',
      'unit_name',
      'unitName',
      'unit_display',
      'unitDisplay',
      'label',
    ];
    for (final key in keys) {
      final value = _summaryNormalizeText(data[key]);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _summaryExtractCurrencySymbol(Map<String, dynamic> data) {
    if (data.isEmpty) return null;
    const keys = <String>[
      'currency_symbol',
      'currencySymbol',
      'currency',
      'currencyCode',
      'currencyPrefix',
    ];
    for (final key in keys) {
      final value = data[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) {
          continue;
        }
        final isAlphabetic = trimmed.length == 3 &&
            trimmed.codeUnits.every(
              (unit) =>
                  (unit >= 65 && unit <= 90) || (unit >= 97 && unit <= 122),
            );
        if (isAlphabetic) {
          return '$trimmed ';
        }
        return trimmed;
      }
    }
    return null;
  }

  String _formatCurrencyValue(num value, String currencySymbol) {
    final normalizedSymbol = currencySymbol.trim().isEmpty ? '€' : currencySymbol;
    final doubleValue = value.toDouble();
    final isWholeNumber = doubleValue.floorToDouble() == doubleValue;
    final formatted = doubleValue.abs().toStringAsFixed(isWholeNumber ? 0 : 2);
    final prefix = doubleValue < 0 ? '-' : '';
    return '$prefix$normalizedSymbol$formatted';
  }

  num? _summaryParseNumericValue(Object? value) {
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

  String? _summaryNormalizeText(Object? value) {
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

  Future<void> _handleRefresh() async {
    await _refreshContractData(showLoader: true, notifyDashboard: true);
  }

  Future<void> _refreshContractData({
    bool showLoader = false,
    bool notifyDashboard = false,
  }) async {
    await Future.wait<void>([
      _loadContractTypes(showLoader: showLoader),
      _loadContractSummary(showLoader: showLoader),
    ]);

    if (notifyDashboard) {
      _notifyDashboardOfChanges();
    }
  }

  void _notifyDashboardOfChanges() {
    try {
      final workBloc = context.read<WorkBloc>();
      workBloc.add(const WorkRefreshed());
    } on ProviderNotFoundException {
      // No WorkBloc available in the current context.
    }
  }

  List<_ContractType> get _allContractTypes => <_ContractType>[
    ..._defaultContractTypes,
    ..._userContractTypes,
  ];

  List<models.ContractType> _filterContractTypesForCurrentWork(
    List<models.ContractType> types,
  ) {
    final workId = widget.work?.id.trim();
    if (workId == null || workId.isEmpty) {
      return types;
    }
    return types
        .where((type) =>
            type.additionalData.isNotEmpty &&
            workDataMatchesId(type.additionalData, workId))
        .toList(growable: false);
  }

  _ContractType _withWorkAssociation(_ContractType type) {
    final workId = widget.work?.id.trim();
    if (workId == null || workId.isEmpty) {
      return type;
    }
    if (type.additionalData.isNotEmpty &&
        workDataMatchesId(type.additionalData, workId)) {
      return type;
    }
    final updated = Map<String, dynamic>.from(type.additionalData)
      ..['work_id'] = workId;
    return type.copyWith(additionalData: updated);
  }

  bool _shouldIncludeContractType(_ContractType type) {
    final workId = widget.work?.id.trim();
    if (workId == null || workId.isEmpty) {
      return true;
    }
    return type.additionalData.isNotEmpty &&
        workDataMatchesId(type.additionalData, workId);
  }

  void _upsertContractType(_ContractType type) {
    final normalizedType = _withWorkAssociation(type);
    if (!_shouldIncludeContractType(normalizedType)) {
      return;
    }
    final targetList = normalizedType.isUserDefined
        ? _userContractTypes
        : _defaultContractTypes;
    final index = targetList.indexWhere((item) => item.id == normalizedType.id);
    final localizations = AppLocalizations.of(context);
    setState(() {
      if (index == -1) {
        targetList.add(normalizedType);
      } else {
        targetList[index] = normalizedType;
      }
      _syncAvailableRoles();
      _summaryRows =
          _buildSummaryRowsFromTypes(_userContractTypes, localizations);
    });
  }

  void _syncAvailableRoles() {
    final roles = contractWorkBuildAvailableRoles<_ContractType>(
      globalTypes: _defaultContractTypes,
      userTypes: _userContractTypes,
      roleSelector: (type) => type.role,
    );
    _availableRoles
      ..clear()
      ..addAll(roles);
  }

  // REMOVED role selection dialog. We open the Add Contract Work sheet directly.

  void _showComingSoonSnackBar(BuildContext context) {
    final l = AppLocalizations.of(context);
    AppSnackBar.show(context, l.helpSupportComingSoon);
  }

  double get _totalUnits => _summaryTotalUnits.toDouble();

  double get _totalContractSalary => _summarySalaryAmount;

  Future<void> _showContractTypeDialog({_ContractType? type}) async {
    // Open the Add Contract Work sheet directly, without any pre-dialog.
    final rootContext = context;

    final result = await showModalBottomSheet<_ContractType>(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ContractTypeSheet(
          type: type,
          repository: _repository,
          rootContext: rootContext,
          isNameEditable: !(type?.isDefault ?? false),
          workNameOptions: kContractWorkDefaultWorkNameOptions,
          defaultRoleOptions: kContractWorkDefaultRoleOptions,
          availableRoles: _availableRoles,
          initialRoleValue: null, // no pre-prompt; user selects inside sheet
          formatRoleDisplay: contractWorkFormatRoleDisplay,
          workId: widget.work?.id,
        );
      },
    );

    if (!mounted || result == null) return;
    final l = AppLocalizations.of(context);

    _upsertContractType(result);

    await _refreshContractData(notifyDashboard: true);
    if (!mounted) return;

    _showSnack(l.contractWorkTypeSavedMessage);
  }

  Future<void> _handleDeleteContractType(_ContractType type) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
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
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.contractWorkDeleteButton),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _pendingDeletionIds.add(type.id);
    });

    try {
      await _repository.deleteContractType(id: type.id);
      if (!mounted) return;
      setState(() {
        _pendingDeletionIds.remove(type.id);
        _defaultContractTypes.removeWhere((item) => item.id == type.id);
        _userContractTypes.removeWhere((item) => item.id == type.id);
        _syncAvailableRoles();
        _summaryRows =
            _buildSummaryRowsFromTypes(_userContractTypes, l);
      });

      await _refreshContractData(notifyDashboard: true);
      if (!mounted) return;

      _showSnack(l.contractWorkTypeDeletedMessage);
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _pendingDeletionIds.remove(type.id);
      });
      final message = error.message.trim().isNotEmpty
          ? error.message
          : l.contractWorkTypeDeleteFailedMessage;
      _showSnack(message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingDeletionIds.remove(type.id);
      });
      _showSnack(l.contractWorkTypeDeleteFailedMessage);
    }
  }

  Future<void> _showManageTypesDialog() async {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final responsive = context.responsive;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            return LayoutBuilder(
              builder: (ctx3, constraints) {
                final isCompact = constraints.maxWidth < 420;
                return AlertDialog(
                  titlePadding: EdgeInsets.fromLTRB(
                    responsive.scale(20),
                    responsive.scale(18),
                    responsive.scale(20),
                    0,
                  ),
                  contentPadding: EdgeInsets.fromLTRB(
                    responsive.scale(20),
                    responsive.scale(12),
                    responsive.scale(20),
                    responsive.scale(8),
                  ),
                  actionsPadding: EdgeInsets.fromLTRB(
                    responsive.scale(16),
                    0,
                    responsive.scale(16),
                    responsive.scale(12),
                  ),
                  title: Text(
                    l.contractWorkCustomTypesTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ??
                        TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: responsive.scaleText(16),
                        ),
                  ),
                  content: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 520 : 640,
                      maxHeight: responsive.scale(460),
                    ),
                    child: _userContractTypes.isEmpty
                        ? Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.scale(8),
                      ),
                      child: Text(
                        l.contractWorkNoCustomTypesLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                        : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _userContractTypes.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = _userContractTypes[i];
                          final isBusy =
                          _pendingDeletionIds.contains(t.id);
                          final unitLabel =
                              t.unitLabel.trim().isNotEmpty ? t.unitLabel : l.contractWorkUnitFallback;
                          final roleSuffix =
                              t.displayRole == null ? '' : ' · ${t.displayRole}';
                          return _ManageTypeRow(
                            name: t.name,
                            subtitle:
                            '${t.displayRate} · $unitLabel$roleSuffix',
                            isBusy: isBusy,
                            onEdit: isBusy
                                ? null
                                : () async {
                              Navigator.of(ctx).pop();
                              await _showContractTypeDialog(
                                type: t,
                              );
                            },
                            onDelete: isBusy
                                ? null
                                : () async {
                              await _handleDeleteContractType(t);
                              if (mounted) {
                                setStateDialog(() {});
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l.close),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _showContractTypeDialog();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l.addContractWorkButton),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;
    final deviceType = responsive.deviceType;
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

    Widget bodyContent;

    if (_isLoading) {
      bodyContent = const Center(
        key: ValueKey('contract-types-loading'),
        child: AppLoader(),
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
                      const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
              SizedBox(height: responsive.scale(16)),
              ElevatedButton(
                onPressed: _handleRefresh,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF4C6EF5),
                  foregroundColor: Colors.white,
                  padding: responsive.scaledSymmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(responsive.scale(14)),
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
        color: const Color(0xFF4C6EF5),
        backgroundColor: Colors.white,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      responsive.scale(16),
                      responsive.scale(8),
                      responsive.scale(16),
                      responsive.scale(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showContractTypeDialog(),
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(l.addContractWorkButton),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    responsive.scale(14),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.scale(16),
                                  vertical: responsive.scale(10),
                                ),
                                textStyle: TextStyle(
                                  fontSize: responsive.scaleText(14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: responsive.scale(10)),
                            OutlinedButton.icon(
                              onPressed: _showManageTypesDialog,
                              icon: const Icon(Icons.tune_rounded),
                              label: Text(l.editWorkTitle),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                foregroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    responsive.scale(14),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.scale(14),
                                  vertical: responsive.scale(10),
                                ),
                                textStyle: TextStyle(
                                  fontSize: responsive.scaleText(14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: responsive.scale(16)),

                        _ContractSummaryTable(
                          title: l.contractWorkSummaryTitle,
                          rows: _summaryRows,
                          isLoading: _isLoadingSummary && _summaryRows.isEmpty,
                          error: _summaryError,
                          emptyMessage: _userContractTypes.isEmpty
                              ? l.contractWorkNoCustomTypesLabel
                              : l.contractWorkNoEntriesLabel,
                          onRetry: _handleRefresh,
                          onEmptyAction: _showContractTypeDialog,
                          emptyActionLabel: l.addContractWorkButton,
                        ),

                        SizedBox(height: responsive.scale(28)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF2F5FF), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: context.responsive.scale(72),
          titleSpacing: 0,
          title: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.scale(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(context.responsive.scale(12)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      context.responsive.scale(18),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A3C4BC8),
                        blurRadius: 16,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppAssets.contractWork,
                    width: context.responsive.scale(26),
                    height: context.responsive.scale(26),
                  ),
                ),
                SizedBox(width: context.responsive.scale(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).contractWorkLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: context.responsive.scaleText(20),
                          color: const Color(0xFF0F172A),
                        ) ??
                            TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: context.responsive.scaleText(20),
                              color: const Color(0xFF0F172A),
                            ),
                      ),
                      if (widget.work != null) ...[
                        SizedBox(height: context.responsive.scale(2)),
                        Text(
                          widget.work!.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            fontSize: context.responsive.scaleText(13),
                          ) ??
                              TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                                fontSize: context.responsive.scaleText(13),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: context.responsive.scale(4)),
                      Text(
                        AppLocalizations.of(context).contractWorkSetupSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF475467),
                          fontSize: context.responsive.scaleText(12),
                        ) ??
                            TextStyle(
                              color: const Color(0xFF475467),
                              fontSize: context.responsive.scaleText(12),
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.responsive.scale(12)),
                SizedBox(
                  height: context.responsive.scale(44),
                  width: context.responsive.scale(44),
                  child: Material(
                    color: Colors.white,
                    elevation: 0,
                    borderRadius: BorderRadius.circular(
                      context.responsive.scale(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: const Color(0xFF1F2937),
                          size: context.responsive.scale(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: bodyContent,
          ),
        ),
      ),
    );
  }
}

class ContractTypeSheet extends StatefulWidget {
  const ContractTypeSheet({
    required this.type,
    required this.repository,
    required this.rootContext,
    required this.isNameEditable,
    required this.workNameOptions,
    required this.defaultRoleOptions,
    required this.availableRoles,
    this.initialRoleValue,
    required this.formatRoleDisplay,
    this.workId,
    this.deferApiCalls = false,
    super.key,
  });

  final _ContractType? type;
  final ContractTypeRepository repository;
  final BuildContext rootContext;
  final bool isNameEditable;
  final List<String> workNameOptions;
  final List<String> defaultRoleOptions;
  final List<String> availableRoles;
  final String? initialRoleValue;
  final String Function(String value) formatRoleDisplay;
  final String? workId;
  final bool deferApiCalls;

  @override
  State<ContractTypeSheet> createState() => _ContractTypeSheetState();
}

class _ContractTypeSheetState extends State<ContractTypeSheet> {
  static const String _customWorkOptionKey = 'custom work';

  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  late final List<String> _workNameOptions;
  late final List<String> _roleOptions;
  late final bool _isRoleLocked;
  late final bool _isRateEditable;

  String? _selectedRoleValue;
  String? _selectedWorkName;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final type = widget.type;
    _nameController = TextEditingController(text: type?.name ?? '');
    _rateController = TextEditingController(
      text: type != null ? type.rate.toStringAsFixed(2) : '',
    );
    _isRoleLocked = _shouldLockRole(type);
    _isRateEditable = _shouldAllowRateEditing(type);

    _workNameOptions = List<String>.from(widget.workNameOptions);

    final existingName = type?.name.trim();
    if (existingName != null && existingName.isNotEmpty) {
      final matchIndex = _workNameOptions.indexWhere(
            (option) => option.toLowerCase() == existingName.toLowerCase(),
      );
      if (matchIndex != -1) {
        _selectedWorkName = _workNameOptions[matchIndex];
        _nameController.text = _selectedWorkName!;
      } else {
        _selectedWorkName = _resolveCustomWorkLabel();
      }
    }

    final seenRoleOptions = <String>{};
    final options = <String>[];

    void addRoleOption(String option, {bool prepend = false}) {
      final formatted = widget.formatRoleDisplay(option);
      if (formatted.isEmpty) return;
      final key = formatted.toLowerCase();
      if (seenRoleOptions.contains(key)) {
        if (prepend) {
          final existingIndex =
          options.indexWhere((item) => item.toLowerCase() == key);
          if (existingIndex > 0) {
            final existingValue = options.removeAt(existingIndex);
            options.insert(0, existingValue);
          }
        }
        return;
      }

      seenRoleOptions.add(key);
      if (prepend) {
        options.insert(0, formatted);
      } else {
        options.add(formatted);
      }
    }

    final existingRole = type?.role?.trim();
    final existingRoleDisplay =
    (existingRole != null && existingRole.isNotEmpty)
        ? widget.formatRoleDisplay(existingRole)
        : null;
    final initialRoleRaw = widget.initialRoleValue?.trim();
    final initialRoleDisplay = (initialRoleRaw != null && initialRoleRaw.isNotEmpty)
        ? widget.formatRoleDisplay(initialRoleRaw)
        : null;

    String? initialSelection;
    if (existingRoleDisplay != null) {
      addRoleOption(existingRoleDisplay, prepend: true);
      initialSelection = existingRoleDisplay;
    }
    if (initialRoleDisplay != null && initialRoleDisplay != existingRoleDisplay) {
      addRoleOption(initialRoleDisplay, prepend: true);
      initialSelection ??= initialRoleDisplay;
    }

    final allowedRoleKeys =
    widget.defaultRoleOptions.map((option) => widget.formatRoleDisplay(option).toLowerCase()).toSet();

    for (final option in widget.defaultRoleOptions) {
      addRoleOption(option);
    }
    for (final option in widget.availableRoles) {
      final formatted = widget.formatRoleDisplay(option);
      if (!allowedRoleKeys.contains(formatted.toLowerCase())) {
        continue;
      }
      addRoleOption(option);
    }

    _roleOptions = options;
    _selectedRoleValue = initialSelection;
    _selectedRoleValue ??= _roleOptions.isNotEmpty ? _roleOptions.first : null;
  }

  bool _shouldAllowRateEditing(_ContractType? type) {
    final identifier = type?.id.trim();
    if (identifier == null || identifier.isEmpty) {
      return true;
    }
    return identifier.startsWith('local-');
  }

  bool _shouldLockRole(_ContractType? type) {
    final role = type?.role?.trim().toLowerCase();
    if (role == null || role.isEmpty) {
      return false;
    }
    return role == 'bin';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  String _resolveCustomWorkLabel() {
    final index = _workNameOptions.indexWhere(
          (option) => option.toLowerCase() == _customWorkOptionKey,
    );
    if (index != -1) return _workNameOptions[index];
    const fallback = 'Custom Work';
    _workNameOptions.add(fallback);
    return fallback;
  }

  bool _isCustomWorkOptionValue(String? value) {
    if (value == null) return false;
    return value.trim().toLowerCase() == _customWorkOptionKey;
  }

  bool get _isCustomWorkSelected => _isCustomWorkOptionValue(_selectedWorkName);

  void _handleWorkNameChanged(String? value) {
    if (value == null) return;

    FocusScope.of(context).unfocus();
    final previousSelection = _selectedWorkName;

    setState(() {
      _selectedWorkName = value;
      if (_isCustomWorkOptionValue(value)) {
        if (widget.isNameEditable && !_isCustomWorkOptionValue(previousSelection)) {
          _nameController.clear();
        }
      } else {
        _nameController.text = value;
      }
    });
  }

  String _resolveRateHint(AppLocalizations l) {
    final selection = _selectedRoleValue?.toLowerCase();
    switch (selection) {
      case 'bin':
        return l.contractWorkPricePerBinHint;
      case 'crate':
        return l.contractWorkPricePerCrateHint;
      case 'bunches':
        return l.contractWorkPricePerBunchesHint;
      default:
        return l.contractWorkRateHint;
    }
  }

  Future<void> _handleSave() async {
    final l = AppLocalizations.of(context);

    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final rate = double.tryParse(_rateController.text.trim());
    final resolvedRole = _selectedRoleValue?.trim() ?? '';
    final resolvedUnitLabel = resolveContractUnitLabel(
      localizations: l,
      contractName: name,
      unitLabel: widget.type?.unitLabel ?? l.contractWorkUnitFallback,
    );

    const resolvedContractKind = 'fixed';

    final type = widget.type;

    // Validation for required fields
    if ((name.isEmpty && widget.isNameEditable) ||
        (!widget.isNameEditable && (type?.name.trim().isEmpty ?? true))) {
      AppSnackBar.show(context, l.contractWorkNameRequiredMessage);
      return;
    }
    if (resolvedRole.isEmpty) {
      AppSnackBar.show(context, l.contractWorkRoleRequiredMessage);
      return;
    }
    if (rate == null || rate <= 0) {
      AppSnackBar.show(context, l.contractWorkRateRequiredMessage);
      return;
    }

    final resolvedName = type == null || widget.isNameEditable ? name : type!.name;

    if (!mounted) return;

    if (widget.deferApiCalls) {
      final pending = PendingContractWork(
        name: resolvedName,
        role: resolvedRole,
        ratePerUnit: rate,
        unitLabel: resolvedUnitLabel,
        contractKind: resolvedContractKind,
      );
      Navigator.of(context).pop(pending);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    Future<_ContractType?> future;
    if (type == null || type.id.startsWith('local-')) {
      // Creating a new contract type
      future = widget.repository
          .createContractType(
        name: resolvedName,
        type: resolvedContractKind,
        role: resolvedRole,
        ratePerUnit: rate,
        unitLabel: resolvedUnitLabel,
        workId: widget.workId,
      )
          .then((created) => _ContractType.fromModel(type: created));
    } else {
      // Updating an existing contract type
      future = widget.repository
          .updateContractType(
        id: type.id,
        name: resolvedName,
        type: resolvedContractKind,
        role: resolvedRole,
        ratePerUnit: rate,
        unitLabel: resolvedUnitLabel,
      )
          .then((updated) => _ContractType.fromModel(
        type: updated,
        isUserDefined: type.isUserDefined,
      ));
    }

    try {
      final updatedType = await future;
      if (!mounted) return;

      // Close the bottom sheet after successful operation
      print("Closing bottom sheet...");
      Navigator.of(context).pop(updatedType);

      // Success message
      AppSnackBar.show(context, l.contractWorkTypeSavedMessage);
    } on ContractTypeRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      print("Error: ${error.message}");

      final lowerCasedMessage = error.message.toLowerCase();
      if (lowerCasedMessage.contains('contract type already exists')) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            final dialogLocalizations = AppLocalizations.of(dialogContext);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(dialogLocalizations.contractWorkDuplicateErrorTitle),
              content: Text(
                error.message.isNotEmpty
                    ? error.message
                    : dialogLocalizations.contractWorkDuplicateErrorMessage,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(dialogLocalizations.okButtonLabel),
                ),
              ],
            );
          },
        );
      } else {
        // Other repository errors
        AppSnackBar.show(context, error.message);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      // Generic error
      print("An unknown error occurred: $error");
      Navigator.of(context, rootNavigator: true).pop();  // Close the bottom sheet
      AppSnackBar.show(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    final headerTitle = l.addContractWorkButton;

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
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
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
                        Semantics(
                          button: true,
                          label: l.contractWorkCloseSheetLabel,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFF6B7280),
                            tooltip: l.contractWorkCloseSheetLabel,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Container
                      (
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
                          Text(
                            l.workNameLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ) ??
                                const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                          ),
                          const SizedBox(height: 8),
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
                              vertical: 4,
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
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedWorkName,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                      ),
                                      hint: Text(
                                        l.contractWorkSelectWorkHint,
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF9CA3AF),
                                        ) ??
                                            const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                      ),
                                      disabledHint: Text(
                                        _nameController.text.isNotEmpty
                                            ? _nameController.text
                                            : l.contractWorkSelectWorkHint,
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF9CA3AF),
                                        ) ??
                                            const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                      ),
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                      ) ??
                                          const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                      selectedItemBuilder:
                                          (BuildContext context) {
                                        return _workNameOptions.map((option) {
                                          final isCustom =
                                          _isCustomWorkOptionValue(option);
                                          final displayText = isCustom
                                              ? (_nameController.text
                                              .trim()
                                              .isNotEmpty
                                              ? _nameController.text.trim()
                                              : l.contractWorkCustomOption)
                                              : option;
                                          return Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              displayText,
                                              style: textTheme.bodyLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color:
                                                const Color(0xFF111827),
                                              ) ??
                                                  const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF111827),
                                                  ),
                                            ),
                                          );
                                        }).toList();
                                      },
                                      items: _workNameOptions
                                          .map(
                                            (option) =>
                                            DropdownMenuItem<String>(
                                              value: option,
                                              child: Text(
                                                _isCustomWorkOptionValue(option)
                                                    ? l.contractWorkCustomOption
                                                    : option,
                                                style: textTheme.bodyLarge
                                                    ?.copyWith(
                                                  fontWeight:
                                                  FontWeight.w700,
                                                  color: const Color(
                                                    0xFF111827,
                                                  ),
                                                ) ??
                                                    const TextStyle(
                                                      fontWeight:
                                                      FontWeight.w700,
                                                      color:
                                                      Color(0xFF111827),
                                                    ),
                                              ),
                                            ),
                                      )
                                          .toList(),
                                      onChanged: widget.isNameEditable
                                          ? _handleWorkNameChanged
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_isCustomWorkSelected) ...[
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
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8EB),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '✍️',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _nameController,
                                      enabled: widget.isNameEditable,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText:
                                        AppString.contractNameHint,
                                        hintStyle: textTheme.bodyMedium
                                            ?.copyWith(
                                          color: const Color(0xFF9CA3AF),
                                        ) ??
                                            const TextStyle(
                                              color: Color(0xFF9CA3AF),
                                            ),
                                      ),
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                      ) ??
                                          const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                            fontSize: 16,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            l.contractWorkTypeLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ) ??
                                const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                          ),
                          const SizedBox(height: 8),
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
                              vertical: 4,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoleValue,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ) ??
                                    const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                hint: Text(
                                  l.contractWorkRoleHint,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF9CA3AF),
                                  ) ??
                                      const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                ),
                                items: _roleOptions
                                    .map(
                                      (option) => DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(
                                      option,
                                      style: textTheme.bodyLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                        const Color(0xFF111827),
                                      ) ??
                                          const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827),
                                          ),
                                    ),
                                  ),
                                )
                                    .toList(),
                                onChanged:
                                _roleOptions.isEmpty || _isRoleLocked
                                    ? null
                                    : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedRoleValue = value;
                                  });
                                },
                              ),
                            ),
                          ),

                          if (_isRoleLocked) ...[
                            const SizedBox(height: 6),
                            Text(
                              l.contractWorkTypeLockedMessage,
                              style: textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6B7280),
                              ) ??
                                  const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                            ),
                          ],

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
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '💶',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _rateController,
                                    enabled: _isRateEditable,
                                    readOnly: !_isRateEditable,
                                    keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: _resolveRateHint(l),
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

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: const Color(0xFF374151),
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
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
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: AppLoader(
                                size: 20,
                                color: Colors.white,
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
  }
}

class _ContractSummaryTable extends StatelessWidget {
  const _ContractSummaryTable({
    required this.title,
    required this.rows,
    required this.emptyMessage,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onEmptyAction,
    this.emptyActionLabel,
  });

  final String title;
  final List<_ContractSummaryRow> rows;
  final bool isLoading;
  final String? error;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onEmptyAction;
  final String? emptyActionLabel;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final hasRows = rows.isNotEmpty;
    final l = AppLocalizations.of(context);
    final resolvedError = error?.trim() ?? '';
    final hasError = resolvedError.isNotEmpty;

    Widget buildStatusMessage(String message, {Widget? action}) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.scale(16),
          vertical: responsive.scale(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
                fontSize: responsive.scaleText(13),
              ) ??
                  TextStyle(
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.scaleText(13),
                  ),
            ),
            if (action != null) ...[
              SizedBox(height: responsive.scale(12)),
              action,
            ],
          ],
        ),
      );
    }

    Widget tableContent;

    if (isLoading) {
      tableContent = Padding(
        padding: EdgeInsets.symmetric(vertical: responsive.scale(24)),
        child: const SizedBox(
          height: 32,
          width: 32,
          child: AppLoader(size: 32),
        ),
      );
    } else if (hasError) {
      tableContent = buildStatusMessage(
        resolvedError,
        action: onRetry == null
            ? null
            : TextButton.icon(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  textStyle: TextStyle(
                    fontSize: responsive.scaleText(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.retryButtonLabel),
              ),
      );
    } else if (hasRows) {
      final headerStyle = TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: responsive.scaleText(13),
        color: const Color(0xFF111827),
      );
      final valueStyle = TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: responsive.scaleText(13),
        color: const Color(0xFF1F2937),
      );
      final secondaryValueStyle = valueStyle.copyWith(color: const Color(0xFF4B5563));

      TableRow buildRow({
        required List<Widget> cells,
        bool isHeader = false,
      }) {
        final backgroundColor = isHeader ? const Color(0xFFF3F4F6) : Colors.white;
        return TableRow(
          decoration: BoxDecoration(color: backgroundColor),
          children: cells
              .map(
                (cell) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.scale(12),
                    vertical: responsive.scale(isHeader ? 12 : 10),
                  ),
                  child: cell,
                ),
              )
              .toList(),
        );
      }

      tableContent = ClipRRect(
        borderRadius: BorderRadius.circular(responsive.scale(12)),
        child: Table(
          columnWidths: {
            0: FixedColumnWidth(responsive.scale(40)),
            1: const FlexColumnWidth(3),
            2: const FlexColumnWidth(2),
            3: const FlexColumnWidth(2),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            verticalInside: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            left: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          children: [
            buildRow(
              isHeader: true,
              cells: [
                Text('#', style: headerStyle),
                Text('Contract Name', style: headerStyle),
                Text('Total Units', style: headerStyle),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Total Payment', style: headerStyle),
                ),
              ],
            ),
            ...rows.map(
              (row) => buildRow(
                cells: [
                  Text('${row.index}.', style: secondaryValueStyle),
                  Text(
                    row.workName,
                    style: valueStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  Text(
                    row.units,
                    style: secondaryValueStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      row.payment,
                      style: secondaryValueStyle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      tableContent = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.scale(16),
          vertical: responsive.scale(24),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0EAFF), Color(0xFFF5F8FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(responsive.scale(18)),
          ),
          child: Padding(
            padding: EdgeInsets.all(responsive.scale(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: responsive.scale(64),
                  width: responsive.scale(64),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2563EB),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(responsive.scale(14)),
                    child: Image.asset(
                      AppAssets.contractWork,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: responsive.scale(16)),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                        fontSize: responsive.scaleText(15),
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                        fontSize: responsive.scaleText(15),
                      ),
                ),
                SizedBox(height: responsive.scale(12)),
                Text(
                  l.contractWorkEmptyHelperText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1F2937),
                        fontSize: responsive.scaleText(13),
                      ) ??
                      TextStyle(
                        color: const Color(0xFF1F2937),
                        fontSize: responsive.scaleText(13),
                      ),
                ),
                if (onEmptyAction != null) ...[
                  SizedBox(height: responsive.scale(18)),
                  FilledButton.icon(
                    onPressed: onEmptyAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.scale(20),
                        vertical: responsive.scale(12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          responsive.scale(14),
                        ),
                      ),
                      textStyle: TextStyle(
                        fontSize: responsive.scaleText(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: Text(
                      emptyActionLabel ?? l.addContractWorkButton,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.scale(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.scale(18)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143B82F6),
            blurRadius: 18,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              fontSize: responsive.scaleText(16),
            ) ??
                TextStyle(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  fontSize: responsive.scaleText(16),
                ),
          ),
          SizedBox(height: responsive.scale(16)),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(responsive.scale(14)),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: tableContent,
          ),
        ],
      ),
    );
  }
}

class _SummaryCountChip extends StatelessWidget {
  const _SummaryCountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16),
        vertical: responsive.scale(10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(responsive.scale(40)),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: RichText(
        text: TextSpan(
          text: '$count ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: responsive.scaleText(13),
          ),
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
                fontSize: responsive.scaleText(12),
              ),
            ),
          ],
        ),
      ),
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

class _ContractType {
  const _ContractType({
    required this.id,
    required this.name,
    required this.rate,
    this.unitLabel = 'per unit',
    required this.type,
    this.role,
    this.isDefault = false,
    this.isUserDefined = false,
    this.lastUpdated,
    this.additionalData = const <String, dynamic>{},
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
      type: type.type,
      role: type.role,
      isDefault: isDefaultType,
      isUserDefined: isUserDefined ?? !isDefaultType,
      lastUpdated: type.updatedAt,
      additionalData: type.additionalData,
    );
  }

  final String id;
  final String name;
  final double rate;
  final String unitLabel;
  final String type;
  final String? role;
  final bool isDefault;
  final bool isUserDefined;
  final DateTime? lastUpdated;
  final Map<String, dynamic> additionalData;

  _ContractType copyWith({
    String? id,
    String? name,
    double? rate,
    String? unitLabel,
    String? type,
    String? role,
    bool? isDefault,
    bool? isUserDefined,
    DateTime? lastUpdated,
    Map<String, dynamic>? additionalData,
  }) {
    return _ContractType(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      unitLabel: unitLabel ?? this.unitLabel,
      type: type ?? this.type,
      role: role ?? this.role,
      isDefault: isDefault ?? this.isDefault,
      isUserDefined: isUserDefined ?? this.isUserDefined,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  String get displayRate => '€${rate.toStringAsFixed(2)}';

  String? get displayRole {
    final value = role?.trim();
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

class _ContractSummaryRow {
  const _ContractSummaryRow({
    required this.index,
    required this.workName,
    required this.units,
    required this.payment,
  });

  final int index;
  final String workName;
  final String units;
  final String payment;
}

class _ContractSummaryAggregation {
  _ContractSummaryAggregation({
    required this.workName,
    this.role,
  });

  final String workName;
  String? role;
  double totalUnits = 0;
  double amount = 0;
  double? ratePerUnit;
  String? unitLabel;
}

class _ContractSummaryComputation {
  const _ContractSummaryComputation({
    required this.rows,
    required this.totalUnits,
    required this.totalSalary,
  });

  final List<_ContractSummaryRow> rows;
  final double totalUnits;
  final double totalSalary;
}

class _ManageTypeRow extends StatelessWidget {
  const _ManageTypeRow({
    required this.name,
    required this.subtitle,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final String subtitle;
  final bool isBusy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.scale(10)),
      child: LayoutBuilder(
        builder: (ctx, cons) {
          final isNarrow = cons.maxWidth < 420;

          final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: r.scaleText(14),
            color: const Color(0xFF111827),
          ) ??
              TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: r.scaleText(14),
                color: const Color(0xFF111827),
              );

          final subtitleStyle =
              Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: r.scaleText(12),
                color: const Color(0xFF6B7280),
              ) ??
                  TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: r.scaleText(12),
                    color: const Color(0xFF6B7280),
                  );

          final infoContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: titleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: r.scale(4)),
              Text(
                subtitle,
                style: subtitleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final actions = Wrap(
            alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
            spacing: r.scale(8),
            runSpacing: r.scale(8),
            children: [
              OutlinedButton(
                onPressed: isBusy ? null : onEdit,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.scale(12),
                    vertical: r.scale(8),
                  ),
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: r.scaleText(12),
                  ),
                  minimumSize: Size(r.scale(64), r.scale(36)),
                ),
                child: Text(
                  AppLocalizations.of(context).contractWorkEditRateButton,
                ),
              ),
              TextButton(
                onPressed: isBusy ? null : onDelete,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.scale(12),
                    vertical: r.scale(8),
                  ),
                  foregroundColor: const Color(0xFFB91C1C),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: r.scaleText(12),
                  ),
                  minimumSize: Size(r.scale(64), r.scale(36)),
                ),
                child: Text(
                  AppLocalizations.of(context).contractWorkDeleteButton,
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoContent,
                SizedBox(height: r.scale(8)),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: infoContent),
              SizedBox(width: r.scale(12)),
              actions,
            ],
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/work_bloc.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/attendance_history.dart';
import '../models/report_summary.dart';
import '../models/work.dart';
import '../repositories/attendance_history_repository.dart';
import '../repositories/reports_repository.dart';
import '../utils/local_notification_service.dart';
import '../utils/pdf_report_service.dart';
import '../utils/contract_unit_label.dart';
import '../utils/snackbar.dart';
import '../widgets/app_loader.dart';
import '../widgets/work_selection_dialog.dart';

class ReportsSummaryScreen extends StatefulWidget {
  const ReportsSummaryScreen({super.key, this.initialWorkId});

  final String? initialWorkId;

  @override
  State<ReportsSummaryScreen> createState() => _ReportsSummaryScreenState();
}

class _ReportsSummaryScreenState extends State<ReportsSummaryScreen> {
  final AttendanceHistoryRepository _historyRepository = AttendanceHistoryRepository();

  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<Color> _contractColorPalette = <Color>[
    Color(0xFF2EBD5F),
    Color(0xFF1C87FF),
    Color(0xFFFFB74D),
    Color(0xFFFF3B30),
    Color(0xFF6366F1),
    Color(0xFF059669),
  ];

  List<String> _availableMonths = const <String>[];
  String _selectedMonth = '';
  bool _initialized = false;

  ReportSummary? _summary;
  bool _isLoadingSummary = false;
  String? _summaryError;
  int _summaryRequestId = 0;

  bool _missingWork = false;
  String? _selectedWorkId;
  String? _selectedWorkName;

  bool _monthListRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _selectedWorkId = widget.initialWorkId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    // Always prefer current month on first load (ignore stale appstrings).
    final now = DateTime.now();
    _availableMonths = _computeAvailableMonths(now);
    _selectedMonth = _formatMonth(DateTime(now.year, now.month, 1));

    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSummary();
    });
  }

  // ===== Month helpers (dynamic list) =====

  List<String> _computeAvailableMonths(DateTime base) {
    final anchor = DateTime(base.year, base.month, 1);
    return List.generate(
      12,
          (index) => _formatMonth(DateTime(anchor.year, anchor.month - index, 1)),
    );
  }

  void _refreshMonthsIfNeeded() {
    if (_monthListRefreshScheduled) return;
    final fresh = _computeAvailableMonths(DateTime.now());
    if (!_areStringListsEqual(_availableMonths, fresh)) {
      _monthListRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final newMonths = _computeAvailableMonths(DateTime.now());
        var newSelected = _selectedMonth;
        if (!newMonths.contains(newSelected)) {
          newSelected = newMonths.first; // current month
        }
        setState(() {
          _availableMonths = newMonths;
          _selectedMonth = newSelected;
          _monthListRefreshScheduled = false;
        });
        _loadSummary();
      });
    } else {
      if (!_availableMonths.contains(_selectedMonth)) {
        _monthListRefreshScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedMonth = _availableMonths.first;
            _monthListRefreshScheduled = false;
          });
          _loadSummary();
        });
      }
    }
  }

  bool _areStringListsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  DateTime? _parseMonth(String value) {
    final parts = value.split(' ');
    if (parts.length != 2) return null;
    final monthIndex = _monthNames.indexWhere((m) => m.toLowerCase() == parts[0].toLowerCase());
    final year = int.tryParse(parts[1]);
    if (monthIndex == -1 || year == null) return null;
    return DateTime(year, monthIndex + 1, 1);
  }

  String _formatMonth(DateTime date) {
    final name = _monthNames[date.month - 1];
    return '$name ${date.year}';
  }

  void _onMonthSelected(String month) {
    if (month == _selectedMonth) return;
    setState(() => _selectedMonth = month);
    _loadSummary();
  }

  // ===== Data load =====

  Future<void> _loadSummary() async {
    final targetDate = _parseMonth(_selectedMonth) ?? DateTime.now();
    final workState = context.read<WorkBloc>().state;
    final selectedWork = _resolveSelectedWork(workState);
    final l = AppLocalizations.of(context);

    if (selectedWork == null) {
      setState(() {
        _summary = null;
        _summaryError = null;
        _missingWork = true;
        _isLoadingSummary = false;
        _selectedWorkId = null;
        _selectedWorkName = null;
      });
      return;
    }

    final requestId = ++_summaryRequestId;
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
      _missingWork = false;
      _selectedWorkId = selectedWork.id;
      _selectedWorkName = selectedWork.name;
    });

    try {
      final repository = context.read<ReportsRepository>();
      final summary = await repository.fetchSummary(
        workId: selectedWork.id,
        month: targetDate.month,
        year: targetDate.year,
      );
      if (!mounted || requestId != _summaryRequestId) return;
      setState(() {
        _summary = summary;
        _summaryError = null;
        _missingWork = false;
        _isLoadingSummary = false;
      });
    } on ReportsRepositoryException catch (e) {
      if (!mounted || requestId != _summaryRequestId) return;
      final message = (e.message).trim().isEmpty ? l.reportsLoadFailedMessage : e.message;
      setState(() {
        _summary = null;
        _summaryError = message;
        _missingWork = false;
        _isLoadingSummary = false;
      });
    } catch (_) {
      if (!mounted || requestId != _summaryRequestId) return;
      setState(() {
        _summary = null;
        _summaryError = l.reportsLoadFailedMessage;
        _missingWork = false;
        _isLoadingSummary = false;
      });
    }
  }

  // ===== Safe converters + “contract-like” checks =====

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        // Try common dd-MM-yyyy
        final parts = v.split(RegExp(r'[-/ ]'));
        if (parts.length >= 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            return DateTime(y, m, d);
          }
        }
      }
    }
    return null;
  }

  String _asString(dynamic v) => (v?.toString() ?? '').trim();

  bool _isContractLikeEntry(dynamic e) {
    // 1) If enum/type exists and equals contract, accept.
    try {
      if (e.type == AttendanceHistoryEntryType.contract) return true;
    } catch (_) {}

    // 2) Heuristics: any of these indicate contract piecework.
    final hasUnits = (_asInt(e?.unitsCompleted) ?? 0) > 0;
    final hasRate = (_asDouble(e?.ratePerUnit) ?? 0) > 0.0;
    final hasSalary = (_asDouble(e?.salary) ?? 0.0) > 0.0;
    final hasContractName = _asString(e?.contractType).isNotEmpty;

    return hasUnits || hasRate || hasSalary || hasContractName;
  }

  ContractReportRow? _toContractRow(dynamic e) {
    final date = _asDate(e?.date);
    final type = _asString(e?.contractType);
    final units = _asInt(e?.unitsCompleted) ?? 0;
    final rate = _asDouble(e?.ratePerUnit) ?? 0.0;
    final salary = _asDouble(e?.salary) ?? 0.0;

    if (date == null) return null; // need a date for the PDF
    // If nothing at all is present, skip.
    if (units == 0 && rate == 0.0 && salary == 0.0 && type.isEmpty) return null;

    return ContractReportRow(
      date: date,
      contractType: type,
      unitsCompleted: units,
      ratePerUnit: rate,
      salary: salary,
    );
  }

  // ===== UI helpers =====

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    final m = message.trim();
    if (m.isEmpty) return;
    AppSnackBar.show(context, m, backgroundColor: color);
  }

  Future<void> _downloadMonthlyContractReport() async {
    if (_selectedWorkId == null) return;

    final l = AppLocalizations.of(context);
    final workId = _selectedWorkId;
    final targetDate = _parseMonth(_selectedMonth);
    final workState = context.read<WorkBloc>().state;
    final storedWorkName = _selectedWorkName?.trim() ?? '';
    final resolvedWorkName =
    storedWorkName.isNotEmpty ? storedWorkName : (_resolveSelectedWork(workState)?.name ?? '').trim();

    if (workId == null || targetDate == null) {
      _showSnack(l.reportDownloadFailedMessage, color: const Color(0xFFB91C1C));
      return;
    }

    try {
      final history = await _historyRepository.fetchHistory(
        workId: workId,
        workName: resolvedWorkName,
        month: targetDate.month,
        year: targetDate.year,
      );

      // 🔁 Use tolerant filter (no hard enum dependency)
      final entries = history.entries;
      final contractLike = entries.where(_isContractLikeEntry).toList(growable: false);

      // Convert to rows safely
      final rows = <ContractReportRow>[];
      for (final e in contractLike) {
        final row = _toContractRow(e);
        if (row != null) rows.add(row);
      }

      if (rows.isEmpty) {
        _showSnack(l.reportDownloadNoEntriesMessage);
        return;
      }

      final workLabel = resolvedWorkName.isEmpty ? l.attendanceHistoryAllWorks : resolvedWorkName;

      final pdfSummary = _resolvePdfSummaryForPdf();
      final reportFile = await PdfReportService.generateMonthlyContractReport(
        workName: workLabel,
        monthLabel: _selectedMonth,
        currencySymbol: history.currencySymbol,
        rows: rows,
        summary: pdfSummary,
      );

      _showSnack(
        l.reportDownloadSuccessMessage(reportFile.path),
        color: const Color(0xFF15803D),
      );

      final fileName =
      reportFile.uri.pathSegments.isNotEmpty ? reportFile.uri.pathSegments.last : reportFile.path;

      await LocalNotificationService.showDownloadNotification(
        fileName: fileName,
        filePath: reportFile.path,
      );
    } on AttendanceHistoryAuthException {
      _showSnack(l.reportDownloadFailedMessage, color: const Color(0xFFB91C1C));
    } on AttendanceHistoryRepositoryException catch (e) {
      final msg = e.message.trim().isEmpty ? l.reportDownloadFailedMessage : e.message;
      _showSnack(msg, color: const Color(0xFFB91C1C));
    } catch (_) {
      _showSnack(l.reportDownloadFailedMessage, color: const Color(0xFFB91C1C));
    }
  }

  HistoryReportSummary? _resolvePdfSummaryForPdf() {
    final summary = _summary;
    if (summary == null) {
      return null;
    }

    final totalHours = summary.hourlySummary.totalHours;
    final totalHourlySalary = summary.hourlySummary.hourlySalary;
    final totalContractSalary = summary.contractSummary.salaryAmount;
    final combined = summary.combinedSalary.amount;
    final grandTotal =
        combined > 0 ? combined : totalHourlySalary + totalContractSalary;

    return HistoryReportSummary(
      totalHoursWorked: totalHours,
      totalHourlySalary: totalHourlySalary,
      totalContractSalary: totalContractSalary,
      grandTotalEarnings: grandTotal,
    );
  }

  Work? _findActiveWorkFromState(WorkState state) {
    if (state.works.isEmpty) return null;
    for (final work in state.works) {
      if (_isWorkActive(work)) return work;
    }
    return state.works.first;
  }

  Work? _resolveSelectedWork(WorkState state) {
    if (state.works.isEmpty) return null;

    final selectedId = _selectedWorkId;
    if (selectedId != null) {
      for (final work in state.works) {
        if (work.id == selectedId) return work;
      }
    }
    return _findActiveWorkFromState(state);
  }

  bool _isWorkActive(Work work) {
    if (work.isActive) return true;

    final data = work.additionalData;
    const keys = {
      'is_active',
      'isActive',
      'active',
      'is_current',
      'isCurrent',
      'currently_active',
    };

    bool? resolve(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final n = value.toLowerCase().trim();
        if (n.isEmpty) return null;
        if (['true', '1', 'yes', 'active', 'current'].contains(n)) return true;
        if (['false', '0', 'no', 'inactive'].contains(n)) return false;
      }
      return null;
    }

    for (final k in keys) {
      final v = data[k];
      final r = resolve(v);
      if (r != null) return r;
    }
    return false;
  }

  List<_ContractWorkItem> _mapContractItems(
    ReportSummary summary,
    AppLocalizations l,
  ) {
    final items = summary.contractSummary.items;
    if (items.isEmpty) return const <_ContractWorkItem>[];

    final normalizedSymbol = summary.currencySymbol.trim().isEmpty ? '€' : summary.currencySymbol;
    final aggregations = <String, _ContractWorkAggregation>{};

    for (final data in items) {
      final workName = data.title.trim().isEmpty ? l.notAvailableLabel : data.title.trim();
      final role = _normalizeContractRoleDisplay(data.unitRole);
      final aggregationKey = '${workName.toLowerCase()}|${role?.toLowerCase() ?? ''}';
      final aggregation = aggregations.putIfAbsent(
        aggregationKey,
        () => _ContractWorkAggregation(workName: workName, role: role),
      );

      final units = _extractContractUnits(data);
      if (units != null) {
        aggregation.totalUnits += units;
      }

      if (data.ratePerUnit != null && data.ratePerUnit! > 0) {
        aggregation.ratePerUnit ??= data.ratePerUnit;
      }

      final resolvedUnitLabel = _resolveUnitLabelText(data, l);
      aggregation.unitLabel ??= resolvedUnitLabel;

      if (data.amount > 0) {
        aggregation.amount += data.amount;
      }

      if (data.indicatorColorValue != null && aggregation.indicatorColorValue == null) {
        aggregation.indicatorColorValue = data.indicatorColorValue;
      }
    }

    final aggregationList = aggregations.values.toList(growable: false);
    final result = <_ContractWorkItem>[];

    for (var i = 0; i < aggregationList.length; i++) {
      final aggregation = aggregationList[i];
      final resolvedUnitLabel = aggregation.unitLabel ?? l.contractWorkUnitFallback;
      final unitsLabel = aggregation.totalUnits > 0
          ? contractUnitCountLabel(
              localizations: l,
              contractName: aggregation.workName,
              unitLabel: resolvedUnitLabel,
              quantity: aggregation.totalUnits,
            )
          : l.notAvailableLabel;

      double? paymentAmount;
      if (aggregation.ratePerUnit != null && aggregation.totalUnits > 0) {
        paymentAmount = aggregation.ratePerUnit! * aggregation.totalUnits;
      } else if (aggregation.amount > 0) {
        paymentAmount = aggregation.amount;
      }

      final amountLabel = paymentAmount != null
          ? _formatCurrencyValue(paymentAmount, normalizedSymbol)
          : l.notAvailableLabel;

      final calculationLabel =
          aggregation.ratePerUnit != null && aggregation.totalUnits > 0
              ? '$unitsLabel × ${_formatCurrencyValue(aggregation.ratePerUnit!, normalizedSymbol)}'
              : null;

      final indicatorColor = aggregation.indicatorColorValue != null
          ? Color(aggregation.indicatorColorValue!)
          : _contractColorPalette[i % _contractColorPalette.length];

      result.add(
        _ContractWorkItem(
          title: _formatContractWorkTitle(aggregation.workName, aggregation.role),
          unitsLabel: unitsLabel,
          amount: amountLabel,
          indicatorColor: indicatorColor,
          calculationLabel: calculationLabel,
        ),
      );
    }

    return result;
  }

  String _resolveUnitLabelText(ContractWorkItemData data, AppLocalizations l) {
    final explicitLabel = data.unitLabel?.trim();
    if (explicitLabel != null && explicitLabel.isNotEmpty) {
      return resolveContractUnitLabel(
        localizations: l,
        contractName: data.title,
        unitLabel: explicitLabel,
      );
    }

    final roleLabel = data.unitRole?.trim();
    if (roleLabel != null && roleLabel.isNotEmpty) {
      final normalizedRole = roleLabel.toLowerCase();
      return resolveContractUnitLabel(
        localizations: l,
        contractName: data.title,
        unitLabel: 'per $normalizedRole',
      );
    }

    return resolveContractUnitLabel(
      localizations: l,
      contractName: data.title,
      unitLabel: l.contractWorkUnitFallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep month list dynamic across boundaries.
    _refreshMonthsIfNeeded();

    final l = AppLocalizations.of(context);
    final selectedMonth = _selectedMonth.isEmpty ? _formatMonth(DateTime.now()) : _selectedMonth;
    final months = _availableMonths.isEmpty ? <String>[selectedMonth] : _availableMonths;

    final workState = context.watch<WorkBloc>().state;
    final selectedWork = _resolveSelectedWork(workState);
    final storedWorkName = _selectedWorkName?.trim() ?? '';
    final resolvedWorkNameCandidate =
    storedWorkName.isNotEmpty ? storedWorkName : (selectedWork?.name ?? '').trim();
    final hasSelectedWork = selectedWork != null || resolvedWorkNameCandidate.isNotEmpty;
    final activeWorkName = resolvedWorkNameCandidate.isNotEmpty ? resolvedWorkNameCandidate : l.notAvailableLabel;

    final summary = _summary;
    final error = _summaryError;
    final isLoading = _isLoadingSummary;
    final currencySymbol = summary?.currencySymbol ?? '€';

    Widget summaryBody;
    if (isLoading) {
      summaryBody = _SummaryLoadingView(
        key: const ValueKey('loading'),
        message: l.reportsLoadingMessage,
      );
    } else if (_missingWork) {
      summaryBody = _SummaryEmptyView(
        key: const ValueKey('missing'),
        message: l.noWorkAddedYet,
      );
    } else if (error != null && error.isNotEmpty) {
      summaryBody = _SummaryErrorView(
        key: const ValueKey('error'),
        message: error,
        onRetry: _loadSummary,
      );
    } else if (summary != null) {
      final hasContractSummary = _hasContractSummaryData(summary);
      final contractItems =
          hasContractSummary ? _mapContractItems(summary, l) : const <_ContractWorkItem>[];
        summaryBody = _SummaryLoadedContent(
          key: const ValueKey('content'),
          summary: summary,
          localization: l,
          selectedMonth: selectedMonth,
          contractItems: contractItems,
          showContractSummary: hasContractSummary,
          canDownloadContractReport: true,
          onDownloadContractReport: _downloadMonthlyContractReport,
        );
    } else {
      summaryBody = _SummaryEmptyView(
        key: const ValueKey('empty'),
        message: l.notAvailableLabel,
      );
    }

    return BlocListener<WorkBloc, WorkState>(
      listenWhen: (previous, current) {
        if (previous.works.length != current.works.length) return true;
        final pIds = previous.works.map((w) => w.id).toSet();
        final cIds = current.works.map((w) => w.id).toSet();
        if (pIds.length != cIds.length) return true;
        if (!pIds.containsAll(cIds) || !cIds.containsAll(pIds)) return true;
        final pActive = _findActiveWorkFromState(previous)?.id;
        final cActive = _findActiveWorkFromState(current)?.id;
        if (pActive != cActive) return true;
        if (_selectedWorkId != null) {
          final pHas = pIds.contains(_selectedWorkId);
          final cHas = cIds.contains(_selectedWorkId);
          if (pHas != cHas) return true;
        }
        return false;
      },
      listener: (context, state) {
        final work = _resolveSelectedWork(state);
        if (work == null) {
          setState(() {
            _summary = null;
            _summaryError = null;
            _missingWork = true;
            _isLoadingSummary = false;
            _selectedWorkId = null;
            _selectedWorkName = null;
          });
          return;
        }
        _loadSummary();
      },
      child: Scaffold(
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
                  color: const Color(0xFFE6F0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(AppAssets.reports, width: 24, height: 24),
              ),
              const SizedBox(width: 12),
              Text(
                l.reportsSummaryLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MonthSelector(
                label: l.reportsSummaryMonth,
                selectedMonth: selectedMonth,
                months: months,
                onMonthSelected: _onMonthSelected,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActiveWorkBadge(
                    workName: hasSelectedWork ? activeWorkName : l.notAvailableLabel,
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => _handleChangeWork(workState.works),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      l.changeWorkButton,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ) ??
                          const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: summaryBody,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleChangeWork(List<Work> works) async {
    if (!mounted || works.isEmpty) return;
    final l = AppLocalizations.of(context);
    final selected = await showWorkSelectionDialog(
      context: context,
      works: works,
      localization: l,
      initialSelectedWorkId: _selectedWorkId ?? _resolveSelectedWork(context.read<WorkBloc>().state)?.id,
    );
    if (!mounted || selected == null) return;
    if (selected.id == _selectedWorkId) return;
    setState(() {
      _selectedWorkId = selected.id;
      _selectedWorkName = selected.name;
    });
    _loadSummary();
  }

  bool _hasContractSummaryData(ReportSummary summary) {
    final c = summary.contractSummary;
    if (c.items.isNotEmpty) return true;
    if (c.totalUnits > 0) return true;
    if (c.salaryAmount > 0) return true;
    return false;
  }
}

class _SummaryLoadedContent extends StatelessWidget {
  const _SummaryLoadedContent({
    super.key,
    required this.summary,
    required this.localization,
    required this.selectedMonth,
    required this.contractItems,
    required this.showContractSummary,
    required this.canDownloadContractReport,
    required this.onDownloadContractReport,
  });

  final ReportSummary summary;
  final AppLocalizations localization;
  final String selectedMonth;
  final List<_ContractWorkItem> contractItems;
  final bool showContractSummary;
  final bool canDownloadContractReport;
  final VoidCallback onDownloadContractReport;

  @override
  Widget build(BuildContext context) {
    final currency = summary.currencySymbol;
    final resolvedContractUnits = _resolveContractSummaryTotalUnits(summary.contractSummary);
    final resolvedContractSalary = _resolveContractSummarySalaryAmount(summary.contractSummary);
    final contractDetails = summary.contractDetails;
    final hasContractDetails = contractDetails.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CombinedSalaryCard(
          title: localization.reportsCombinedSalaryTitle,
          amount: summary.combinedSalary.amount,
          currencySymbol: currency,
        ),
        const SizedBox(height: 24),
        _SectionTitle(text: localization.reportsHourlyWorkSummaryTitle),
        const SizedBox(height: 12),
        _HourlyWorkSummaryCard(
          totalHoursLabel: localization.totalHoursLabel,
          totalHours: summary.hourlySummary.totalHours,
          hourlySalaryLabel: localization.hourlySalaryLabel,
          hourlySalary: summary.hourlySummary.hourlySalary,
          workingDaysLabel: localization.reportsWorkingDaysLabel,
          workingDays: summary.hourlySummary.workingDays,
          currencySymbol: currency,
        ),
        if (hasContractDetails) ...[
          const SizedBox(height: 24),
          _SectionTitle(text: localization.reportsContractDetailsTitle),
          const SizedBox(height: 12),
          _ContractDetailsCard(
            details: contractDetails,
            currencySymbol: currency,
            subtitle: localization.reportsContractDetailsSubtitle,
            rateLabel: localization.reportsContractDetailsRateLabel,
            typeLabel: localization.reportsContractDetailsTypeLabel,
          ),
        ],
        if (showContractSummary) ...[
          const SizedBox(height: 24),
          _SectionTitle(text: localization.contractWorkSummaryTitle),
          const SizedBox(height: 12),
          _ContractWorkSummaryCard(
            totalUnitsLabel: localization.reportsTotalUnitsLabel,
            totalUnits: resolvedContractUnits,
            salaryLabel: localization.reportsContractSalaryLabel,
            salaryAmount: resolvedContractSalary,
            currencySymbol: currency,
            items: contractItems,
            emptyMessage: localization.notAvailableLabel,
            workNameLabel: localization.workNameLabel,
            unitsColumnLabel: localization.reportsTotalUnitsLabel,
            paymentColumnLabel: localization.reportsTotalPaymentLabel,
          ),
        ],
        if (canDownloadContractReport) ...[
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onDownloadContractReport,
              icon: const Icon(Icons.download),
              label: Text(localization.reportsSummaryDownloadLabel),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryLoadingView extends StatelessWidget {
  const _SummaryLoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF6B7280),
    ) ??
        const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6B7280));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: AppLoader(size: 48),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: style),
          ],
        ),
      ),
    );
  }
}

class _SummaryErrorView extends StatelessWidget {
  const _SummaryErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF6B7280),
    ) ??
        const TextStyle(color: Color(0xFF6B7280));
    final l = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11111827),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 28),
          const SizedBox(height: 12),
          Text(message, style: body),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: Text(l.retryButtonLabel),
          ),
        ],
      ),
    );
  }
}

class _SummaryEmptyView extends StatelessWidget {
  const _SummaryEmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF6B7280),
    ) ??
        const TextStyle(color: Color(0xFF6B7280));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insights_outlined,
            color: Color(0xFF9CA3AF),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: style),
        ],
      ),
    );
  }
}

class _ActiveWorkBadge extends StatelessWidget {
  const _ActiveWorkBadge({required this.workName});

  final String workName;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1F2937),
      fontSize: 13,
    ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          fontSize: 13,
        );
    final workStyle = label.copyWith(fontSize: 11, fontWeight: FontWeight.w600);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.work_outline, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Active Work', style: label),
                const SizedBox(height: 2),
                Text(workName, style: workStyle, softWrap: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
      ) ??
          const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.selectedMonth,
    required this.months,
    required this.onMonthSelected,
  });

  final String label;
  final String selectedMonth;
  final List<String> months;
  final ValueChanged<String> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showMonthPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F2937).withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  AppAssets.icCalender,
                  height: 20,
                  width: 20,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedMonth,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    if (months.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        const baseHeaderExtent = 136.0;
        final estimatedHeight = baseHeaderExtent + (months.length * 56.0);
        final heightFactor = (estimatedHeight / screenHeight).clamp(0.35, 0.85).toDouble();
        final sheetHeight = screenHeight * heightFactor;
        final showScrollbar = months.length > 6;

        return SizedBox(
          height: sheetHeight,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ) ??
                        const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: showScrollbar,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: months.length,
                        itemBuilder: (context, index) {
                          final month = months[index];
                          final isSelected = month == selectedMonth;
                          return ListTile(
                            title: Text(
                              month,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: const Color(0xFF111827),
                              ) ??
                                  TextStyle(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 16,
                                    color: const Color(0xFF111827),
                                  ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                              Icons.check,
                              color: Color(0xFF2563EB),
                            )
                                : null,
                            onTap: () => Navigator.of(context).pop(month),
                          );
                        },
                        separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null && selected != selectedMonth) {
      onMonthSelected(selected);
    }
  }
}

class _CombinedSalaryCard extends StatelessWidget {
  const _CombinedSalaryCard({
    required this.title,
    required this.amount,
    required this.currencySymbol,
  });

  final String title;
  final double amount;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331F2937),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatCurrencyValue(amount, currencySymbol),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 36,
            ) ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                ),
          ),
        ],
      ),
    );
  }
}

class _HourlyWorkSummaryCard extends StatelessWidget {
  const _HourlyWorkSummaryCard({
    required this.totalHoursLabel,
    required this.totalHours,
    required this.hourlySalaryLabel,
    required this.hourlySalary,
    required this.workingDaysLabel,
    required this.workingDays,
    required this.currencySymbol,
  });

  final String totalHoursLabel;
  final double totalHours;
  final String hourlySalaryLabel;
  final double hourlySalary;
  final String workingDaysLabel;
  final int workingDays;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111827),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryValueTile(
                  label: totalHoursLabel,
                  value: '${_formatHoursValue(totalHours)} h',
                  icon: Icons.schedule,
                  iconColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryValueTile(
                  label: hourlySalaryLabel,
                  value: _formatCurrencyValue(hourlySalary, currencySymbol),
                  icon: Icons.payments,
                  iconColor: const Color(0xFF059669),
                  emphasizeValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SummaryDetailTile(
            label: workingDaysLabel,
            value: workingDays.toString(),
            icon: Icons.calendar_month,
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

class _ContractDetailsCard extends StatelessWidget {
  const _ContractDetailsCard({
    required this.details,
    required this.currencySymbol,
    required this.subtitle,
    required this.rateLabel,
    required this.typeLabel,
  });

  final List<ContractDetail> details;
  final String currencySymbol;
  final String subtitle;
  final String rateLabel;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1D4ED8),
        ) ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D4ED8),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0EAFF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A312E81),
            blurRadius: 22,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: subtitleStyle),
          const SizedBox(height: 16),
          ...List.generate(details.length, (index) {
            final detail = details[index];
            final isLast = index == details.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: _ContractDetailTile(
                detail: detail,
                currencySymbol: currencySymbol,
                rateLabel: rateLabel,
                typeLabel: typeLabel,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ContractDetailTile extends StatelessWidget {
  const _ContractDetailTile({
    required this.detail,
    required this.currencySymbol,
    required this.rateLabel,
    required this.typeLabel,
  });

  final ContractDetail detail;
  final String currencySymbol;
  final String rateLabel;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        );
    final hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        );
    final rateStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        );
    final chipStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF1E3A8A),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E3A8A),
        );

    final rate = detail.ratePerUnit;
    final rateText = rate != null
        ? _formatCurrencyValue(rate, currencySymbol)
        : '--';
    final unitLabel = detail.unitLabel.trim();
    final type = detail.type;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.name, style: nameStyle),
                if (type != null && type.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${typeLabel.toUpperCase()}: ${type.trim()}',
                      style: chipStyle,
                    ),
                  ),
                ],
                if (unitLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(unitLabel, style: hintStyle),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rateText, style: rateStyle),
              const SizedBox(height: 4),
              Text(rateLabel, style: hintStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValueTile extends StatelessWidget {
  const _SummaryValueTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF4F7FB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ) ??
                const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: emphasizeValue ? FontWeight.w700 : FontWeight.w600,
              color: emphasizeValue ? const Color(0xFF059669) : const Color(0xFF111827),
            ) ??
                TextStyle(
                  fontSize: 20,
                  fontWeight: emphasizeValue ? FontWeight.w700 : FontWeight.w600,
                  color: emphasizeValue ? const Color(0xFF059669) : const Color(0xFF111827),
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDetailTile extends StatelessWidget {
  const _SummaryDetailTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ) ??
                      const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractWorkSummaryCard extends StatelessWidget {
  const _ContractWorkSummaryCard({
    required this.totalUnitsLabel,
    required this.totalUnits,
    required this.salaryLabel,
    required this.salaryAmount,
    required this.currencySymbol,
    required this.items,
    required this.emptyMessage,
    required this.workNameLabel,
    required this.unitsColumnLabel,
    required this.paymentColumnLabel,
  });

  final String totalUnitsLabel;
  final int totalUnits;
  final String salaryLabel;
  final double salaryAmount;
  final String currencySymbol;
  final List<_ContractWorkItem> items;
  final String emptyMessage;
  final String workNameLabel;
  final String unitsColumnLabel;
  final String paymentColumnLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111827),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryValueTile(
                  label: totalUnitsLabel,
                  value: totalUnits.toString(),
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryValueTile(
                  label: salaryLabel,
                  value: _formatCurrencyValue(salaryAmount, currencySymbol),
                  icon: Icons.savings_outlined,
                  iconColor: const Color(0xFF059669),
                  emphasizeValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ) ??
                    const TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          else
            Column(
              children: [
                _ContractSummaryHeaderRow(
                  workNameLabel: workNameLabel,
                  unitsLabel: unitsColumnLabel,
                  paymentLabel: paymentColumnLabel,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == items.length - 1 ? 0 : 12,
                    ),
                    child: _ContractWorkTile(item: items[i]),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContractWorkItem {
  const _ContractWorkItem({
    required this.title,
    required this.unitsLabel,
    required this.amount,
    required this.indicatorColor,
    this.calculationLabel,
  });

  final String title;
  final String unitsLabel;
  final String amount;
  final Color indicatorColor;
  final String? calculationLabel;
}

class _ContractWorkAggregation {
  _ContractWorkAggregation({
    required this.workName,
    this.role,
  });

  final String workName;
  final String? role;
  num totalUnits = 0;
  double amount = 0;
  double? ratePerUnit;
  String? unitLabel;
  int? indicatorColorValue;
}

String _formatContractWorkTitle(String workName, String? role) {
  final normalizedName = workName.trim().isEmpty ? 'Contract Work' : workName.trim();
  final normalizedRole = _normalizeContractRoleDisplay(role);
  if (normalizedRole == null || normalizedRole.isEmpty) {
    return normalizedName;
  }
  return '$normalizedName · $normalizedRole';
}

String? _normalizeContractRoleDisplay(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
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

class _ContractWorkTile extends StatelessWidget {
  const _ContractWorkTile({required this.item});

  final _ContractWorkItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final workStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF111827),
    ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Color(0xFF111827),
        );
    final detailStyle = textTheme.bodySmall?.copyWith(
      color: const Color(0xFF6B7280),
      fontWeight: FontWeight.w500,
    ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        );
    final calculationStyle = detailStyle.copyWith(
      color: const Color(0xFF2563EB),
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.indicatorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: workStyle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.unitsLabel, style: detailStyle),
                  if (item.calculationLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(item.calculationLabel!, style: calculationStyle),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: item.indicatorColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  item.amount,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: item.indicatorColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractSummaryHeaderRow extends StatelessWidget {
  const _ContractSummaryHeaderRow({
    required this.workNameLabel,
    required this.unitsLabel,
    required this.paymentLabel,
  });

  final String workNameLabel;
  final String unitsLabel;
  final String paymentLabel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: const Color(0xFF6B7280),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.6,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(workNameLabel.toUpperCase(), style: style),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(unitsLabel.toUpperCase(), style: style),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(paymentLabel.toUpperCase(), style: style),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrencyValue(num value, String symbol) {
  final doubleValue = value.toDouble();
  final isWhole = doubleValue.floorToDouble() == doubleValue;
  final formatted = doubleValue.abs().toStringAsFixed(isWhole ? 0 : 2);
  final prefix = doubleValue < 0 ? '-' : '';
  return '$prefix$symbol$formatted';
}

String _formatHoursValue(double value) {
  final isWhole = value.floorToDouble() == value;
  return value.toStringAsFixed(isWhole ? 0 : 1);
}

num? _extractContractUnits(ContractWorkItemData data) {
  num? normalize(num? value) {
    if (value == null) {
      return null;
    }
    if (value < 0) {
      return null;
    }
    return value;
  }

  final unitCount = normalize(data.unitCount);
  if (unitCount != null) {
    return _normalizeHundredBunchUnits(unitCount, data);
  }

  final completed = normalize(data.unitsCompleted);
  if (completed != null) {
    return _normalizeHundredBunchUnits(completed, data);
  }

  final totalUnits = normalize(data.unitsTotal);
  if (totalUnits != null) {
    return _normalizeHundredBunchUnits(totalUnits, data);
  }

  final pending = normalize(data.unitsPending);
  if (pending != null) {
    return _normalizeHundredBunchUnits(pending, data);
  }

  return null;
}

bool _isHundredBunchContractItem(ContractWorkItemData data) {
  final title = data.title.toLowerCase();
  final unitLabel = data.unitLabel?.toLowerCase() ?? '';
  final role = data.unitRole?.toLowerCase() ?? '';

  if (role == 'bunches') {
    return true;
  }

  final mentionsBunch = title.contains('bunch') ||
      unitLabel.contains('bunch') ||
      unitLabel.contains('mazz') ||
      title.contains('mazz');
  if (!mentionsBunch) {
    return false;
  }

  final mentionsHundred = unitLabel.contains('100') ||
      unitLabel.contains('hundred') ||
      title.contains('100') ||
      title.contains('cento');

  return mentionsHundred || role == 'bunches';
}

num _normalizeHundredBunchUnits(num rawUnits, ContractWorkItemData data) {
  if (rawUnits <= 0) {
    return rawUnits;
  }
  if (!_isHundredBunchContractItem(data)) {
    return rawUnits;
  }

  final normalized = rawUnits / 100;
  if (normalized % 1 == 0) {
    return normalized.toInt();
  }

  return double.parse(normalized.toStringAsFixed(2));
}

double? _calculateContractItemAmount(ContractWorkItemData data) {
  final rate = data.ratePerUnit;
  final units = _extractContractUnits(data);
  if (rate != null && rate > 0 && units != null) {
    return rate * units;
  }
  return null;
}

num _resolveContractSummaryTotalUnits(ContractSummaryData summary) {
  if (summary.totalUnits > 0) {
    return summary.totalUnits;
  }
  num total = 0;
  for (final item in summary.items) {
    final units = _extractContractUnits(item);
    if (units != null) {
      total += units;
    }
  }
  return total;
}

double _resolveContractSummarySalaryAmount(ContractSummaryData summary) {
  if (summary.salaryAmount > 0) {
    return summary.salaryAmount;
  }
  var total = 0.0;
  for (final item in summary.items) {
    if (item.amount > 0) {
      total += item.amount;
      continue;
    }
    final computed = _calculateContractItemAmount(item);
    if (computed != null) {
      total += computed;
    }
  }
  return total;
}

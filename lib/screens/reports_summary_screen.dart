import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/work_bloc.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/attendance_history.dart';
import '../models/contract_type.dart';
import '../models/report_summary.dart';
import '../models/work.dart';
import '../repositories/attendance_history_repository.dart';
import '../repositories/reports_repository.dart';
import '../utils/local_notification_service.dart';
import '../utils/pdf_report_service.dart';
import '../utils/contract_unit_label.dart';
import '../utils/history_entry_hours.dart';
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

  bool _isGeneratingReport = false;

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

  // ===== Report helpers =====

  Map<DateTime, List<AttendanceHistoryEntryData>> _groupHistoryEntriesByDay(
      List<AttendanceHistoryEntryData> entries,
      ) {
    final grouped = <DateTime, List<AttendanceHistoryEntryData>>{};
    for (final entry in entries) {
      final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
      grouped.putIfAbsent(key, () => <AttendanceHistoryEntryData>[]).add(entry);
    }
    return grouped;
  }

  String _buildHistoryDetail(
      AttendanceHistoryEntryData entry,
      AppLocalizations localization,
      ) {
    switch (entry.type) {
      case AttendanceHistoryEntryType.hourly:
        final start = _normalizeTimeLabel(entry.startTime).isNotEmpty
            ? _normalizeTimeLabel(entry.startTime)
            : '--';
        final end = _normalizeTimeLabel(entry.endTime).isNotEmpty
            ? _normalizeTimeLabel(entry.endTime)
            : '--';
        final hours = _formatHours(entry.hoursWorked);
        final overtime = entry.overtimeHours > 0
            ? ' (+${_formatHours(entry.overtimeHours)} overtime)'
            : '';
        final breakLabel = entry.breakDuration?.trim().isNotEmpty == true
            ? ', Break: ${entry.breakDuration!.trim()}'
            : '';
        return '$start - $end ($hours$overtime$breakLabel)';
      case AttendanceHistoryEntryType.contract:
        final units = entry.unitsCompleted ?? 0;
        final rate = entry.ratePerUnit ?? 0;
        final typeLabel = entry.contractType?.trim().isNotEmpty == true
            ? entry.contractType!.trim()
            : localization.reportsContractDetailsTypeLabel;
        final rateLabel = _formatCurrencyValue(
          rate,
          entry.detectedCurrencySymbol ?? '',
        );
        return '$units $typeLabel @ $rateLabel';
      case AttendanceHistoryEntryType.leave:
        final reason = entry.leaveReason?.trim();
        if (reason == null || reason.isEmpty) {
          return localization.attendanceHistoryLeaveEntry;
        }
        return reason;
    }
  }

  String _resolveEntryTypeLabel(
      AttendanceHistoryEntryType type,
      AppLocalizations localization,
      ) {
    switch (type) {
      case AttendanceHistoryEntryType.hourly:
        return localization.attendanceHistoryHourlyEntry;
      case AttendanceHistoryEntryType.contract:
        return localization.attendanceHistoryContractEntry;
      case AttendanceHistoryEntryType.leave:
        return localization.attendanceHistoryLeaveEntry;
    }
  }

  String _resolveContractTypeLabel(
    AttendanceHistoryEntryData entry,
    AppLocalizations localization, {
    Map<String, ContractType>? contractTypeLookup,
  }) {
    final lookup = contractTypeLookup;
    if (lookup != null && lookup.isNotEmpty && entry.contractBundles.isNotEmpty) {
      final seen = <String>{};
      final labels = <String>[];

      for (final bundle in entry.contractBundles) {
        final name = _contractTypeNameFromLookup(
          bundle.contractTypeId.toString(),
          lookup,
        );
        if (name != null && name.isNotEmpty && seen.add(name)) {
          labels.add(name);
        }
      }

      if (labels.isNotEmpty) {
        return labels.join(', ');
      }
    }

    // When we have contract metadata but no bundle linkage, fall back to the
    // sole available contract name instead of the generic unit placeholder so
    // the PDF shows the actual contract selected by the user.
    if (lookup != null && lookup.length == 1) {
      final single = lookup.values.first.name.trim();
      if (single.isNotEmpty) {
        return single;
      }
    }

    final explicit = entry.contractType?.trim();
    final mappedExplicit = _contractTypeNameFromLookup(explicit, lookup);
    if (mappedExplicit != null && mappedExplicit.isNotEmpty) {
      return mappedExplicit;
    }

    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    return localization.contractWorkUnitFallback;
  }

  String _resolveContractUnitLabel(
    AttendanceHistoryEntryData entry,
    AppLocalizations localization, {
    Map<String, ContractType>? contractTypeLookup,
  }) {
    final lookup = contractTypeLookup;

    if (lookup != null && lookup.isNotEmpty) {
      for (final bundle in entry.contractBundles) {
        final type = lookup[bundle.contractTypeId.toString()];
        if (type != null && type.unitLabel.trim().isNotEmpty) {
          return resolveContractUnitLabel(
            localizations: localization,
            contractName: type.name,
            unitLabel: type.unitLabel,
          );
        }
      }

      if (lookup.length == 1) {
        final single = lookup.values.first;
        final name = single.name.trim();
        if (name.isNotEmpty) {
          return resolveContractUnitLabel(
            localizations: localization,
            contractName: name,
            unitLabel: single.unitLabel,
          );
        }
      }

      final explicit = entry.contractType?.trim();
      if (explicit != null && explicit.isNotEmpty) {
        for (final type in lookup.values) {
          if (type.name == explicit && type.unitLabel.trim().isNotEmpty) {
            return resolveContractUnitLabel(
              localizations: localization,
              contractName: type.name,
              unitLabel: type.unitLabel,
            );
          }
        }
      }
    }

    final fallbackName = entry.contractType?.trim();
    return resolveContractUnitLabel(
      localizations: localization,
      contractName:
          fallbackName != null && fallbackName.isNotEmpty ? fallbackName : localization.contractWorkUnitFallback,
      unitLabel: localization.contractWorkUnitFallback,
    );
  }

  String? _contractTypeNameFromLookup(
    String? idOrName,
    Map<String, ContractType>? lookup,
  ) {
    if (lookup == null || lookup.isEmpty) {
      return null;
    }

    final raw = idOrName?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final directMatch = lookup[raw];
    if (directMatch != null && directMatch.name.trim().isNotEmpty) {
      return directMatch.name.trim();
    }

    final numericId = int.tryParse(raw)?.toString();
    if (numericId != null) {
      final numericMatch = lookup[numericId];
      if (numericMatch != null && numericMatch.name.trim().isNotEmpty) {
        return numericMatch.name.trim();
      }
    }

    for (final type in lookup.values) {
      if (type.id == raw || type.id == numericId || type.name.trim() == raw) {
        final resolved = type.name.trim();
        if (resolved.isNotEmpty) {
          return resolved;
        }
      }
    }

    return null;
  }

  // ===== UI helpers =====

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    final m = message.trim();
    if (m.isEmpty) return;
    AppSnackBar.show(context, m, backgroundColor: color);
  }

  Future<void> _downloadAttendanceHistoryReport() async {
    if (_isGeneratingReport) return;

    final l = AppLocalizations.of(context);
    final workState = context.read<WorkBloc>().state;
    Work? resolvedWork;
    if (_selectedWorkId != null) {
      for (final work in workState.works) {
        if (work.id == _selectedWorkId) {
          resolvedWork = work;
          break;
        }
      }
    }

    resolvedWork ??= _resolveSelectedWork(workState);
    resolvedWork ??= _findActiveWorkFromState(workState);
    resolvedWork ??= workState.works.isNotEmpty ? workState.works.first : null;
    final workId = resolvedWork?.id;
    final targetDate = _parseMonth(_selectedMonth);
    final storedWorkName = _selectedWorkName?.trim() ?? '';
    final resolvedWorkName = storedWorkName.isNotEmpty
        ? storedWorkName
        : (resolvedWork?.name ?? '').trim();

    if (workId == null || targetDate == null) {
      _showSnack(l.reportDownloadFailedMessage, color: const Color(0xFFB91C1C));
      return;
    }

    setState(() => _isGeneratingReport = true);

    try {
      final history = await _historyRepository.fetchHistory(
        workId: workId,
        workName: resolvedWorkName,
        month: targetDate.month,
        year: targetDate.year,
      );

      final entries = history.entries;
      final contractTypeLookup = <String, ContractType>{
        for (final type in history.contractTypes) type.id: type,
      };
      final hoursEntries = entries
          .where(
            (entry) =>
                (entry.type == AttendanceHistoryEntryType.hourly ||
                    entry.type == AttendanceHistoryEntryType.leave) &&
                entry.isContractEntry != true,
          )
          .toList(growable: false);
      final contractEntries = entries
          .where(
            (entry) =>
                entry.type == AttendanceHistoryEntryType.contract ||
                entry.isContractEntry == true,
          )
          .toList(growable: false);

      if (entries.isEmpty) {
        _showSnack(l.reportDownloadNoEntriesMessage);
        return;
      }

      final summary = HistoryReportSummary(
        totalHoursWorked: hoursEntries.fold<double>(
          0,
              (previous, entry) => previous + resolveEntryTotalHours(entry),
        ),
        totalHourlySalary: hoursEntries.fold<double>(
          0,
              (previous, entry) => previous + entry.salary,
        ),
        totalContractSalary: contractEntries.fold<double>(
          0,
              (previous, entry) => previous + entry.salary,
        ),
        grandTotalEarnings: hoursEntries.fold<double>(
          0,
              (previous, entry) => previous + entry.salary,
        ) +
            contractEntries.fold<double>(
              0,
                  (previous, entry) => previous + entry.salary,
            ),
      );

      final workLabel = resolvedWorkName.isEmpty
          ? l.attendanceHistoryAllWorks
          : resolvedWorkName;

      if (hoursEntries.isEmpty && contractEntries.isNotEmpty) {
        final rows = contractEntries
            .map(
              (entry) => ContractReportRow(
                date: entry.date,
                contractType: _resolveContractTypeLabel(
                  entry,
                  l,
                  contractTypeLookup: contractTypeLookup,
                ),
                unitLabel: _resolveContractUnitLabel(
                  entry,
                  l,
                  contractTypeLookup: contractTypeLookup,
                ),
                unitsCompleted: entry.unitsCompleted ?? 0,
                ratePerUnit: entry.ratePerUnit ?? 0,
                salary: entry.salary,
              ),
            )
            .toList(growable: false);

        final reportFile = await PdfReportService.generateMonthlyContractReport(
          workName: workLabel,
          monthLabel: _selectedMonth,
          currencySymbol: history.currencySymbol,
          rows: rows,
          summary: summary,
        );

        _showSnack(
          l.reportDownloadSuccessMessage(reportFile.path),
          color: const Color(0xFF15803D),
        );

        final fileName = reportFile.uri.pathSegments.isNotEmpty
            ? reportFile.uri.pathSegments.last
            : reportFile.path;

        await LocalNotificationService.showDownloadNotification(
          fileName: fileName,
          filePath: reportFile.path,
        );

        return;
      }

      final grouped = _groupHistoryEntriesByDay(entries);
      final days = grouped.entries
          .map(
            (entry) => HistoryReportDay(
          date: entry.key,
          entries: entry.value
              .map(
                (item) => HistoryReportEntry(
              workName: item.workName,
              typeLabel: _resolveEntryTypeLabel(item.type, l),
              totalHours: resolveEntryTotalHours(item),
              salary: item.salary,
              contractTypeLabel:
                  (item.type == AttendanceHistoryEntryType.contract ||
                          item.isContractEntry == true)
                      ? _resolveContractTypeLabel(
                          item,
                          l,
                          contractTypeLookup: contractTypeLookup,
                        )
                      : null,
            ),
          )
              .toList(growable: false),
        ),
      )
          .toList(growable: false);

      final reportFile = await PdfReportService.generateAttendanceHistoryReport(
        workName: workLabel,
        monthLabel: _selectedMonth,
        currencySymbol: history.currencySymbol,
        days: days,
        summary: summary,
      );

      _showSnack(
        l.reportDownloadSuccessMessage(reportFile.path),
        color: const Color(0xFF15803D),
      );

      final fileName = reportFile.uri.pathSegments.isNotEmpty
          ? reportFile.uri.pathSegments.last
          : reportFile.path;

      await LocalNotificationService.showDownloadNotification(
        fileName: fileName,
        filePath: reportFile.path,
      );
    } on UnsupportedError catch (e) {
      final msg = e.message?.trim().isEmpty ?? true
          ? l.reportDownloadFailedMessage
          : e.message!;
      _showSnack(msg, color: const Color(0xFFB91C1C));
    } on AttendanceHistoryAuthException {
      _showSnack(l.reportDownloadFailedMessage, color: const Color(0xFFB91C1C));
    } on AttendanceHistoryRepositoryException catch (e) {
      final msg = e.message.trim().isEmpty ? l.reportDownloadFailedMessage : e.message;
      _showSnack(msg, color: const Color(0xFFB91C1C));
    } catch (_) {
      _showSnack(l.reportDownloadFailedMessage, color: const Color(0xFFB91C1C));
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
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
        canDownloadReport: true,
        isGeneratingReport: _isGeneratingReport,
        onDownloadReport: _downloadAttendanceHistoryReport,
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
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
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
    required this.canDownloadReport,
    required this.isGeneratingReport,
    required this.onDownloadReport,
  });

  final ReportSummary summary;
  final AppLocalizations localization;
  final String selectedMonth;
  final List<_ContractWorkItem> contractItems;
  final bool showContractSummary;
  final bool canDownloadReport;
  final bool isGeneratingReport;
  final VoidCallback onDownloadReport;

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
            typeLabel: localization.reportsContractDetailsTypeLabel,
            totalUnitsLabel: localization.reportsTotalUnitsLabel,
            salaryLabel: localization.reportsContractSalaryLabel,
            totalUnits: resolvedContractUnits,
            totalSalary: resolvedContractSalary,
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
        if (canDownloadReport) ...[
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isGeneratingReport ? null : onDownloadReport,
              icon: isGeneratingReport
                  ? SizedBox(
                width: 18,
                height: 18,
                child: AppLoader(
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
                  : const Icon(Icons.download),
              label: Text(localization.historyReportDownloadLabel),
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
    required this.typeLabel,
    required this.totalUnitsLabel,
    required this.salaryLabel,
    required this.totalUnits,
    required this.totalSalary,
  });

  final List<ContractDetail> details;
  final String currencySymbol;
  final String subtitle;
  final String typeLabel;
  final String totalUnitsLabel;
  final String salaryLabel;
  final num totalUnits;
  final double totalSalary;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
    ) ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        );

    final summaryLabelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF6B7280),
      fontWeight: FontWeight.w600,
    ) ??
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        );
    final summaryValueStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF111827),
    ) ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111827),
        );
    final headerStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: const Color(0xFF475467),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    ) ??
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: Color(0xFF475467),
        );

    final resolvedTotalUnits = totalUnits > 0
        ? totalUnits
        : details.fold<num>(0, (sum, item) => sum + (item.totalUnits ?? 0));
    final resolvedTotalSalary = totalSalary > 0
        ? totalSalary
        : details.fold<double>(0, (sum, item) {
            final amount = item.salaryAmount ??
                ((item.ratePerUnit ?? 0) * (item.totalUnits ?? 0));
            return sum + amount;
          });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: subtitleStyle),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 760;
              final tableHeaderStyle = isCompact
                  ? headerStyle.copyWith(fontSize: (headerStyle.fontSize ?? 12) - 1)
                  : headerStyle;
              final tableLabelStyle = isCompact
                  ? summaryLabelStyle.copyWith(
                      fontSize: (summaryLabelStyle.fontSize ?? 12) - 1,
                    )
                  : summaryLabelStyle;
              final tableValueStyle = isCompact
                  ? summaryValueStyle.copyWith(
                      fontSize: (summaryValueStyle.fontSize ?? 20) - 4,
                    )
                  : summaryValueStyle;
              final rowPadding = EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: isCompact ? 10 : 12,
              );

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 10 : 12,
                        vertical: isCompact ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          _ContractHeaderCell(
                            text: '#',
                            flex: 1,
                            style: tableHeaderStyle,
                          ),
                          _ContractHeaderCell(
                            text: typeLabel,
                            flex: 5,
                            style: tableHeaderStyle,
                          ),
                          _ContractHeaderCell(
                            text: totalUnitsLabel,
                            flex: 3,
                            style: tableHeaderStyle,
                            alignment: Alignment.centerRight,
                          ),
                          _ContractHeaderCell(
                            text: salaryLabel,
                            flex: 3,
                            style: tableHeaderStyle,
                            alignment: Alignment.centerRight,
                          ),
                        ],
                      ),
                    ),
                    ...List.generate(details.length, (index) {
                      final detail = details[index];
                      final salary = detail.salaryAmount ??
                          ((detail.ratePerUnit ?? 0) * (detail.totalUnits ?? 0));
                      final salaryText = salary > 0
                          ? _formatCurrencyValue(salary, currencySymbol)
                          : '--';
                      final unitText = _formatUnitCount(detail.totalUnits);
                      final typeText = (detail.type?.trim().isNotEmpty ?? false)
                          ? detail.type!.trim()
                          : detail.name;
                      final isLast = index == details.length - 1;
                      final radius = isLast
                          ? const BorderRadius.vertical(bottom: Radius.circular(20))
                          : BorderRadius.zero;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              index.isEven ? Colors.white : const Color(0xFFF9FAFB),
                          borderRadius: radius,
                          border: isLast
                              ?  Border.all(color: Color(0xFFE5E7EB))
                              : const Border(
                                  top: BorderSide(color: Color(0xFFE5E7EB)),
                                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                        ),
                        child: Padding(
                          padding: rowPadding,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${index + 1}.',
                                  style: tableLabelStyle.copyWith(
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  typeText,
                                  style: tableLabelStyle.copyWith(
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(unitText, style: tableValueStyle),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(salaryText, style: tableValueStyle),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${totalUnitsLabel.toUpperCase()} = ${_formatUnitCount(resolvedTotalUnits)}',
                  style: summaryValueStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${salaryLabel.toUpperCase()} = ${_formatCurrencyValue(resolvedTotalSalary, currencySymbol)}',
                  style: summaryValueStyle.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractHeaderCell extends StatelessWidget {
  const _ContractHeaderCell({
    required this.text,
    required this.flex,
    required this.style,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final int flex;
  final TextStyle style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: Text(text.toUpperCase(), style: style),
        ),
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

class _ContractHighlightTile extends StatelessWidget {
  const _ContractHighlightTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF4B5563),
    ) ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        );
    final valueStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF0F172A),
    ) ??
        const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFFBFCFF),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: emphasizeValue
                      ? valueStyle.copyWith(color: accentColor)
                      : valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
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
  final num totalUnits;
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

String _formatHoursValue(double value) {
  final isWhole = value.floorToDouble() == value;
  return value.toStringAsFixed(isWhole ? 0 : 1);
}

String _formatNumber(num value) {
  final formatter = NumberFormat.decimalPattern();
  return formatter.format(value);
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

String _formatUnitCount(num? units) {
  if (units == null) {
    return '--';
  }

  final doubleValue = units.toDouble();
  final isWholeNumber = doubleValue.floorToDouble() == doubleValue;
  return isWholeNumber ? doubleValue.toInt().toString() : doubleValue.toString();
}

String _formatCurrencyValue(num value, String symbol) {
  final doubleValue = value.toDouble();
  final resolvedSymbol = symbol.trim().isEmpty ? '€' : symbol.trim();
  final isWhole = doubleValue.floorToDouble() == doubleValue;
  final formatted = doubleValue.abs().toStringAsFixed(isWhole ? 0 : 2);
  final prefix = doubleValue < 0 ? '-' : '';
  return '$prefix$resolvedSymbol$formatted';
}

String _formatHours(double hours) {
  final totalMinutes = (hours * 60).round();
  final clampedMinutes = totalMinutes < 0 ? 0 : totalMinutes;
  final resolvedHours = clampedMinutes ~/ 60;
  final minutes = clampedMinutes % 60;
  return '${resolvedHours}h ${minutes}m';
}

String _normalizeTimeLabel(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '';
  }

  final dateTimeCandidate = DateTime.tryParse(
    trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T'),
  );
  if (dateTimeCandidate != null) {
    return _formatTimeLabel(
      TimeOfDay(
        hour: dateTimeCandidate.hour,
        minute: dateTimeCandidate.minute,
      ),
    );
  }

  final timeMatch = RegExp(r'(\d{1,2}):(\d{1,2})').firstMatch(trimmed);
  if (timeMatch != null) {
    final hour = int.tryParse(timeMatch.group(1) ?? '');
    final minute = int.tryParse(timeMatch.group(2) ?? '');
    if (hour != null && minute != null) {
      return _formatTimeLabel(TimeOfDay(hour: hour, minute: minute));
    }
  }

  return trimmed;
}

String _formatTimeLabel(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

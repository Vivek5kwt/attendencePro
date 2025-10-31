import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../bloc/work_bloc.dart';
import '../bloc/work_state.dart';
import '../models/monthly_report.dart';
import '../models/report_summary.dart';
import '../models/work.dart';
import '../repositories/reports_repository.dart';
import '../widgets/work_selection_dialog.dart';

class ReportsSummaryScreen extends StatefulWidget {
  const ReportsSummaryScreen({super.key, this.initialWorkId});

  final String? initialWorkId;

  @override
  State<ReportsSummaryScreen> createState() => _ReportsSummaryScreenState();
}

class _ReportsSummaryScreenState extends State<ReportsSummaryScreen> {
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
  MonthlyReportType _selectedMonthlyType = MonthlyReportType.hourly;
  MonthlyReport? _monthlyReport;
  bool _isLoadingMonthlyReport = false;
  String? _monthlyReportError;
  int _monthlyRequestId = 0;
  bool _hasAttemptedMonthlyReportLoad = false;

  @override
  void initState() {
    super.initState();
    _selectedWorkId = widget.initialWorkId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final l = AppLocalizations.of(context);
    final defaultMonth = l.reportsSummaryMonth;
    final baseDate = _parseMonth(defaultMonth) ?? DateTime.now();
    _availableMonths = List.generate(
      12,
      (index) => _formatMonth(
        DateTime(baseDate.year, baseDate.month - index, 1),
      ),
    );
    _selectedMonth = _availableMonths.firstWhere(
      (month) => month == defaultMonth,
      orElse: () => _availableMonths.first,
    );
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSummary();
      }
    });
  }

  DateTime? _parseMonth(String value) {
    final parts = value.split(' ');
    if (parts.length != 2) {
      return null;
    }
    final monthIndex = _monthNames
        .indexWhere((month) => month.toLowerCase() == parts[0].toLowerCase());
    final year = int.tryParse(parts[1]);
    if (monthIndex == -1 || year == null) {
      return null;
    }
    return DateTime(year, monthIndex + 1, 1);
  }

  String _formatMonth(DateTime date) {
    final monthName = _monthNames[date.month - 1];
    return '$monthName ${date.year}';
  }

  void _onMonthSelected(String month) {
    if (month == _selectedMonth) {
      return;
    }
    setState(() {
      _selectedMonth = month;
    });
    _loadSummary();
  }

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
        _monthlyReport = null;
        _monthlyReportError = null;
        _isLoadingMonthlyReport = false;
        _hasAttemptedMonthlyReportLoad = false;
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

    _loadMonthlyReport(targetDate: targetDate, work: selectedWork);

    try {
      final repository = context.read<ReportsRepository>();
      final summary = await repository.fetchSummary(
        workId: selectedWork.id,
        month: targetDate.month,
        year: targetDate.year,
      );
      if (!mounted || requestId != _summaryRequestId) {
        return;
      }
      setState(() {
        _summary = summary;
        _summaryError = null;
        _missingWork = false;
        _isLoadingSummary = false;
      });
    } on ReportsRepositoryException catch (e) {
      if (!mounted || requestId != _summaryRequestId) {
        return;
      }
      final message = (e.message).trim().isEmpty
          ? l.reportsLoadFailedMessage
          : e.message;
      setState(() {
        _summary = null;
        _summaryError = message;
        _missingWork = false;
        _isLoadingSummary = false;
      });
    } catch (_) {
      if (!mounted || requestId != _summaryRequestId) {
        return;
      }
      setState(() {
        _summary = null;
        _summaryError = l.reportsLoadFailedMessage;
        _missingWork = false;
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _loadMonthlyReport({
    required DateTime targetDate,
    required Work work,
  }) async {
    final l = AppLocalizations.of(context);
    final requestId = ++_monthlyRequestId;
    final fallbackUserId = _resolveUserIdFromWork(work);

    setState(() {
      _isLoadingMonthlyReport = true;
      _monthlyReportError = null;
      _hasAttemptedMonthlyReportLoad = true;
    });

    try {
      final repository = context.read<ReportsRepository>();
      final report = await repository.fetchMonthlyReport(
        month: targetDate.month,
        year: targetDate.year,
        type: _selectedMonthlyType,
        fallbackUserId: fallbackUserId,
      );
      if (!mounted || requestId != _monthlyRequestId) {
        return;
      }
      setState(() {
        _monthlyReport = report;
        _monthlyReportError = null;
        _isLoadingMonthlyReport = false;
      });
    } on ReportsRepositoryException catch (e) {
      if (!mounted || requestId != _monthlyRequestId) {
        return;
      }
      final trimmed = e.message.trim();
      final message = (trimmed.isEmpty ||
              trimmed == 'Unable to determine user for monthly report.')
          ? l.reportsLoadFailedMessage
          : trimmed;
      setState(() {
        _monthlyReport = null;
        _monthlyReportError = message;
        _isLoadingMonthlyReport = false;
      });
    } catch (_) {
      if (!mounted || requestId != _monthlyRequestId) {
        return;
      }
      setState(() {
        _monthlyReport = null;
        _monthlyReportError = l.reportsLoadFailedMessage;
        _isLoadingMonthlyReport = false;
      });
    }
  }

  void _retryMonthlyReport() {
    final targetDate = _parseMonth(_selectedMonth) ?? DateTime.now();
    final selectedWork = _resolveSelectedWork(context.read<WorkBloc>().state);
    if (selectedWork == null) {
      return;
    }
    _loadMonthlyReport(targetDate: targetDate, work: selectedWork);
  }

  void _onMonthlyTypeSelected(MonthlyReportType type) {
    if (type == _selectedMonthlyType) {
      return;
    }
    setState(() {
      _selectedMonthlyType = type;
    });
    final targetDate = _parseMonth(_selectedMonth) ?? DateTime.now();
    final selectedWork = _resolveSelectedWork(context.read<WorkBloc>().state);
    if (selectedWork == null) {
      return;
    }
    _loadMonthlyReport(targetDate: targetDate, work: selectedWork);
  }

  Future<void> _handleChangeWork(List<Work> works) async {
    if (!mounted || works.isEmpty) {
      return;
    }
    final l = AppLocalizations.of(context);
    final selected = await showWorkSelectionDialog(
      context: context,
      works: works,
      localization: l,
      initialSelectedWorkId:
          _selectedWorkId ?? _resolveSelectedWork(context.read<WorkBloc>().state)?.id,
    );
    if (!mounted || selected == null) {
      return;
    }
    if (selected.id == _selectedWorkId) {
      return;
    }
    setState(() {
      _selectedWorkId = selected.id;
      _selectedWorkName = selected.name;
    });
    _loadSummary();
  }

  Work? _findActiveWorkFromState(WorkState state) {
    if (state.works.isEmpty) {
      return null;
    }
    for (final work in state.works) {
      if (_isWorkActive(work)) {
        return work;
      }
    }
    return state.works.first;
  }

  Work? _resolveSelectedWork(WorkState state) {
    if (state.works.isEmpty) {
      return null;
    }

    final selectedId = _selectedWorkId;
    if (selectedId != null) {
      for (final work in state.works) {
        if (work.id == selectedId) {
          return work;
        }
      }
    }

    return _findActiveWorkFromState(state);
  }

  String? _resolveUserIdFromWork(Work work) {
    final data = work.additionalData;
    const candidateKeys = [
      'user_id',
      'userId',
      'owner_id',
      'ownerId',
      'employee_id',
      'employeeId',
    ];

    for (final key in candidateKeys) {
      final value = data[key];
      if (value == null) {
        continue;
      }
      if (value is int) {
        return value.toString();
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return null;
  }

  Widget _buildMonthlyReportSection({
    required AppLocalizations localization,
    required String selectedMonthLabel,
    required String currencySymbol,
  }) {
    if (_missingWork || !_hasAttemptedMonthlyReportLoad) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final typeLabel = _selectedMonthlyType == MonthlyReportType.fixed
        ? localization.reportsMonthlyTypeFixed
        : localization.reportsMonthlyTypeHourly;
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _SectionTitle(text: localization.reportsMonthlySectionTitle),
        const SizedBox(height: 6),
        Text('$selectedMonthLabel • $typeLabel', style: subtitleStyle),
        const SizedBox(height: 12),
        _MonthlyTypeSelector(
          selectedType: _selectedMonthlyType,
          hourlyLabel: localization.reportsMonthlyTypeHourly,
          fixedLabel: localization.reportsMonthlyTypeFixed,
          onSelected: _onMonthlyTypeSelected,
        ),
        const SizedBox(height: 16),
        _MonthlyReportContainer(
          isLoading: _isLoadingMonthlyReport,
          error: _monthlyReportError,
          report: _monthlyReport,
          currencySymbol: currencySymbol,
          localization: localization,
          emptyMessage: localization.reportsMonthlyEmptyMessage,
          onRetry: _retryMonthlyReport,
        ),
      ],
    );
  }

  bool _isWorkActive(Work work) {
    if (work.isActive) {
      return true;
    }

    final data = work.additionalData;
    const possibleKeys = {
      'is_active',
      'isActive',
      'active',
      'is_current',
      'isCurrent',
      'currently_active',
    };

    bool? resolve(dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized.isEmpty) {
          return null;
        }
        if (['true', '1', 'yes', 'active', 'current'].contains(normalized)) {
          return true;
        }
        if (['false', '0', 'no', 'inactive'].contains(normalized)) {
          return false;
        }
      }
      return null;
    }

    for (final key in possibleKeys) {
      final value = data[key];
      final resolved = resolve(value);
      if (resolved != null) {
        return resolved;
      }
    }

    return false;
  }

  List<_ContractWorkItem> _mapContractItems(
    ReportSummary summary,
    AppLocalizations l,
  ) {
    final items = summary.contractSummary.items;
    if (items.isEmpty) {
      return const <_ContractWorkItem>[];
    }

    final result = <_ContractWorkItem>[];
    for (var index = 0; index < items.length; index++) {
      final data = items[index];
      final colorValue = data.indicatorColorValue;
      final color = colorValue != null
          ? Color(colorValue)
          : _contractColorPalette[index % _contractColorPalette.length];
      final subtitle = _buildContractSubtitle(data, l);
      result.add(
        _ContractWorkItem(
          title: data.title,
          subtitle: subtitle,
          amount: data.resolveAmountLabel(summary.currencySymbol),
          indicatorColor: color,
        ),
      );
    }
    return result;
  }

  String _buildContractSubtitle(
    ContractWorkItemData data,
    AppLocalizations l,
  ) {
    if (data.subtitle.isNotEmpty) {
      return data.subtitle;
    }
    if (data.unitsCompleted != null) {
      return '${data.unitsCompleted} ${l.reportsUnitsCompletedSuffix}';
    }
    return l.notAvailableLabel;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selectedMonth =
        _selectedMonth.isEmpty ? l.reportsSummaryMonth : _selectedMonth;
    final months =
        _availableMonths.isEmpty ? <String>[selectedMonth] : _availableMonths;

    final workState = context.watch<WorkBloc>().state;
    final selectedWork = _resolveSelectedWork(workState);
    final storedWorkName = _selectedWorkName?.trim() ?? '';
    final resolvedWorkNameCandidate = storedWorkName.isNotEmpty
        ? storedWorkName
        : (selectedWork?.name ?? '').trim();
    final hasSelectedWork =
        selectedWork != null || resolvedWorkNameCandidate.isNotEmpty;
    final activeWorkName = resolvedWorkNameCandidate.isNotEmpty
        ? resolvedWorkNameCandidate
        : l.notAvailableLabel;
    final summary = _summary;
    final error = _summaryError;
    final isLoading = _isLoadingSummary;
    final currencySymbol =
        summary?.currencySymbol ?? _monthlyReport?.currencySymbol ?? '€';

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
      final contractItems = _mapContractItems(summary, l);
      summaryBody = _SummaryLoadedContent(
        key: const ValueKey('content'),
        summary: summary,
        localization: l,
        selectedMonth: selectedMonth,
        contractItems: contractItems,
      );
    } else {
      summaryBody = _SummaryEmptyView(
        key: const ValueKey('empty'),
        message: l.notAvailableLabel,
      );
    }

    final monthlySection = _buildMonthlyReportSection(
      localization: l,
      selectedMonthLabel: selectedMonth,
      currencySymbol: currencySymbol,
    );

    return BlocListener<WorkBloc, WorkState>(
      listenWhen: (previous, current) {
        if (previous.works.length != current.works.length) {
          return true;
        }
        final previousIds = previous.works.map((work) => work.id).toSet();
        final currentIds = current.works.map((work) => work.id).toSet();
        if (previousIds.length != currentIds.length) {
          return true;
        }
        if (!previousIds.containsAll(currentIds) ||
            !currentIds.containsAll(previousIds)) {
          return true;
        }
        final previousActiveId = _findActiveWorkFromState(previous)?.id;
        final currentActiveId = _findActiveWorkFromState(current)?.id;
        if (previousActiveId != currentActiveId) {
          return true;
        }
        if (_selectedWorkId != null) {
          final previousHasSelected = previousIds.contains(_selectedWorkId);
          final currentHasSelected = currentIds.contains(_selectedWorkId);
          if (previousHasSelected != currentHasSelected) {
            return true;
          }
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
                child: Image.asset(
                  AppAssets.reports,
                  width: 24,
                  height: 24,
                ),
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
              if (hasSelectedWork) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ActiveWorkBadge(workName: activeWorkName),
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
              ],
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: summaryBody,
              ),
              monthlySection,
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryLoadedContent extends StatelessWidget {
  const _SummaryLoadedContent({
    super.key,
    required this.summary,
    required this.localization,
    required this.selectedMonth,
    required this.contractItems,
  });

  final ReportSummary summary;
  final AppLocalizations localization;
  final String selectedMonth;
  final List<_ContractWorkItem> contractItems;

  @override
  Widget build(BuildContext context) {
    final currency = summary.currencySymbol;
    final resolvedHoursWorked = _resolveDoubleMetric(
      summary.combinedSalary.hoursWorked,
      summary.hourlySummary.totalHours,
    );
    final resolvedUnitsCompleted = _resolveIntMetric(
      summary.combinedSalary.unitsCompleted,
      summary.contractSummary.totalUnits,
    );
    final resolvedContractTotal = _resolveDoubleMetric(
      summary.breakdown.contractTotal,
      summary.contractSummary.salaryAmount,
    );
    var resolvedHourlyTotal = _resolveDoubleMetric(
      summary.breakdown.hourlyTotal,
      summary.combinedSalary.amount - resolvedContractTotal,
    );
    if (_isEffectivelyZero(resolvedHourlyTotal)) {
      resolvedHourlyTotal = _resolveDoubleMetric(
        resolvedHourlyTotal,
        summary.hourlySummary.hourlySalary,
      );
    }
    final resolvedGrandTotal = _resolveDoubleMetric(
      summary.breakdown.grandTotal,
      summary.combinedSalary.amount,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CombinedSalaryCard(
          title: localization.reportsCombinedSalaryTitle,
          amount: summary.combinedSalary.amount,
          hoursWorked: resolvedHoursWorked,
          unitsCompleted: resolvedUnitsCompleted,
          hoursLabel: localization.reportsHoursWorkedSuffix,
          unitsLabel: localization.reportsUnitsCompletedSuffix,
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
          averageHoursLabel: localization.reportsAverageHoursPerDayLabel,
          averageHours: summary.hourlySummary.averageHoursPerDay,
          lastPayoutLabel: localization.reportsLastPayoutLabel,
          lastPayout: summary.hourlySummary.lastPayout,
          currencySymbol: currency,
        ),
        const SizedBox(height: 24),
        _SectionTitle(text: localization.contractWorkSummaryTitle),
        const SizedBox(height: 12),
        _ContractWorkSummaryCard(
          totalUnitsLabel: localization.reportsTotalUnitsLabel,
          totalUnits: summary.contractSummary.totalUnits,
          salaryLabel: localization.reportsContractSalaryLabel,
          salaryAmount: summary.contractSummary.salaryAmount,
          currencySymbol: currency,
          items: contractItems,
          emptyMessage: localization.notAvailableLabel,
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          text: '$selectedMonth ${localization.reportsBreakdownSuffix}',
        ),
        const SizedBox(height: 12),
        _MonthlyBreakdownCard(
          hourlyWorkLabel: localization.hourlyWorkLabel,
          hourlyTotal: resolvedHourlyTotal,
          contractWorkLabel: localization.contractWorkLabel,
          contractTotal: resolvedContractTotal,
          grandTotalLabel: localization.reportsGrandTotalLabel,
          grandTotal: resolvedGrandTotal,
          currencySymbol: currency,
        ),
      ],
    );
  }
}

class _SummaryLoadingView extends StatelessWidget {
  const _SummaryLoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
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
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
          fontSize: 18,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7280),
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
        );
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
          Text(message, style: bodyStyle),
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
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7280),
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
        );

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
          const Icon(Icons.insights_outlined, color: Color(0xFF9CA3AF), size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: bodyStyle,
          ),
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
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
          fontSize: 13,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          fontSize: 13,
        );
    final workNameStyle = labelStyle.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
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
                Text(
                  'Active Work',
                  style: labelStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  workName,
                  style: workNameStyle,
                  softWrap: true,
                ),
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
                  'assets/images/ic_calender.png',
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
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    if (months.isEmpty) {
      return;
    }
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
        final heightFactor =
        (estimatedHeight / screenHeight).clamp(0.35, 0.85).toDouble();
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
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: const Color(0xFF111827),
                              ) ??
                                  TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
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
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: Color(0xFFE5E7EB),
                        ),
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
    required this.hoursWorked,
    required this.unitsCompleted,
    required this.hoursLabel,
    required this.unitsLabel,
    required this.currencySymbol,
  });

  final String title;
  final double amount;
  final double hoursWorked;
  final int unitsCompleted;
  final String hoursLabel;
  final String unitsLabel;
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
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                ),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Updated',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(
                icon: Icons.access_time,
                label: '${_formatHoursValue(hoursWorked)} $hoursLabel',
              ),
              _MetricChip(
                icon: Icons.task_alt,
                label: '$unitsCompleted $unitsLabel',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
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
    required this.averageHoursLabel,
    required this.averageHours,
    required this.lastPayoutLabel,
    required this.lastPayout,
    required this.currencySymbol,
  });

  final String totalHoursLabel;
  final double totalHours;
  final String hourlySalaryLabel;
  final double hourlySalary;
  final String workingDaysLabel;
  final int workingDays;
  final String averageHoursLabel;
  final double averageHours;
  final String lastPayoutLabel;
  final double lastPayout;
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
          Row(
            children: [
              Expanded(
                child: _SummaryDetailTile(
                  label: workingDaysLabel,
                  value: workingDays.toString(),
                  icon: Icons.calendar_month,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryDetailTile(
                  label: averageHoursLabel,
                  value: '${_formatHoursValue(averageHours)} h',
                  icon: Icons.timer,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryDetailTile(
            label: lastPayoutLabel,
            value: _formatCurrencyValue(lastPayout, currencySymbol),
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFF2563EB),
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
                  fontWeight:
                      emphasizeValue ? FontWeight.w700 : FontWeight.w600,
                  color: emphasizeValue
                      ? const Color(0xFF059669)
                      : const Color(0xFF111827),
                ) ??
                TextStyle(
                  fontSize: 20,
                  fontWeight:
                      emphasizeValue ? FontWeight.w700 : FontWeight.w600,
                  color: emphasizeValue
                      ? const Color(0xFF059669)
                      : const Color(0xFF111827),
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
  });

  final String totalUnitsLabel;
  final int totalUnits;
  final String salaryLabel;
  final double salaryAmount;
  final String currencySymbol;
  final List<_ContractWorkItem> items;
  final String emptyMessage;

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
                    const TextStyle(
                      color: Color(0xFF6B7280),
                    ),
              ),
            )
          else
            for (var i = 0; i < items.length; i++)
              Padding(
                padding:
                    EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
                child: _ContractWorkTile(item: items[i]),
              ),
        ],
      ),
    );
  }
}

class _ContractWorkItem {
  const _ContractWorkItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.indicatorColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color indicatorColor;
}

class _ContractWorkTile extends StatelessWidget {
  const _ContractWorkTile({required this.item});

  final _ContractWorkItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.subtitle,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ) ??
                                const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        ],
      ),
    );
  }
}

class _MonthlyTypeSelector extends StatelessWidget {
  const _MonthlyTypeSelector({
    required this.selectedType,
    required this.hourlyLabel,
    required this.fixedLabel,
    required this.onSelected,
  });

  final MonthlyReportType selectedType;
  final String hourlyLabel;
  final String fixedLabel;
  final ValueChanged<MonthlyReportType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _MonthlyTypeChip(
          label: hourlyLabel,
          type: MonthlyReportType.hourly,
          selected: selectedType == MonthlyReportType.hourly,
          onSelected: onSelected,
        ),
        _MonthlyTypeChip(
          label: fixedLabel,
          type: MonthlyReportType.fixed,
          selected: selectedType == MonthlyReportType.fixed,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _MonthlyTypeChip extends StatelessWidget {
  const _MonthlyTypeChip({
    required this.label,
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final MonthlyReportType type;
  final bool selected;
  final ValueChanged<MonthlyReportType> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = const Color(0xFF2563EB);
    final textColor = selected ? Colors.white : const Color(0xFF1F2937);

    return ChoiceChip(
      label: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ) ??
            TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => onSelected(type),
      selectedColor: selectedColor,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? selectedColor : const Color(0xFFE5E7EB),
        ),
      ),
      pressElevation: 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MonthlyReportContainer extends StatelessWidget {
  const _MonthlyReportContainer({
    required this.isLoading,
    required this.error,
    required this.report,
    required this.currencySymbol,
    required this.localization,
    required this.emptyMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final MonthlyReport? report;
  final String currencySymbol;
  final AppLocalizations localization;
  final String emptyMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _MonthlyReportLoadingView(message: localization.reportsLoadingMessage);
    }

    if (error != null && error!.trim().isNotEmpty) {
      return _MonthlyReportMessageCard(
        icon: Icons.error_outline,
        message: error!,
        actionLabel: localization.retryButtonLabel,
        onAction: onRetry,
        isError: true,
      );
    }

    final resolvedReport = report;
    if (resolvedReport == null || resolvedReport.days.isEmpty) {
      return _MonthlyReportMessageCard(
        icon: Icons.calendar_today_outlined,
        message: emptyMessage,
      );
    }

    final sections = _buildSections(
      resolvedReport.days,
      localization,
    );
    final defaultCurrencySymbol =
        resolvedReport.currencySymbol ?? currencySymbol;

    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final sectionWidgets = sections
        .map(
          (section) => _MonthlyReportTypeSection(
            title: section.label,
            days: section.days,
            localization: localization,
            currencyFallback: defaultCurrencySymbol,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _insertSectionSpacing(sectionWidgets),
    );
  }

  List<_MonthlyReportSectionData> _buildSections(
    List<MonthlyReportDay> days,
    AppLocalizations localization,
  ) {
    final lookup = <String, _MonthlyReportSectionData>{};
    final ordered = <_MonthlyReportSectionData>[];

    for (final day in days) {
      final label = _resolveSectionLabel(day, localization);
      final key = label.toLowerCase();

      final existing = lookup[key];
      if (existing != null) {
        existing.days.add(day);
        continue;
      }

      final section = _MonthlyReportSectionData(label: label, days: [day]);
      lookup[key] = section;
      ordered.add(section);
    }

    return ordered;
  }

  String _resolveSectionLabel(
    MonthlyReportDay day,
    AppLocalizations localization,
  ) {
    final type = monthlyReportTypeFromString(day.type);
    switch (type) {
      case MonthlyReportType.hourly:
        return localization.reportsMonthlyTypeHourly;
      case MonthlyReportType.fixed:
        return localization.reportsMonthlyTypeFixed;
      case MonthlyReportType.unknown:
        final raw = day.type;
        if (raw == null) {
          return localization.notAvailableLabel;
        }
        final trimmed = raw.trim();
        if (trimmed.isEmpty) {
          return localization.notAvailableLabel;
        }
        final normalized = trimmed.toLowerCase();
        if (normalized == 'hourly' || normalized == 'hourly_work') {
          return localization.reportsMonthlyTypeHourly;
        }
        if (normalized == 'fixed' ||
            normalized == 'fixed_salary' ||
            normalized == 'salary' ||
            normalized == 'contract') {
          return localization.reportsMonthlyTypeFixed;
        }
        return trimmed[0].toUpperCase() + trimmed.substring(1);
    }
  }

  List<Widget> _insertSectionSpacing(List<Widget> sections) {
    if (sections.length <= 1) {
      return sections;
    }

    final spaced = <Widget>[];
    for (var index = 0; index < sections.length; index++) {
      spaced.add(sections[index]);
      if (index != sections.length - 1) {
        spaced.add(const SizedBox(height: 20));
      }
    }
    return spaced;
  }
}

class _MonthlyReportSectionData {
  _MonthlyReportSectionData({
    required this.label,
    required this.days,
  });

  final String label;
  final List<MonthlyReportDay> days;
}

class _MonthlyReportTypeSection extends StatelessWidget {
  const _MonthlyReportTypeSection({
    required this.title,
    required this.days,
    required this.localization,
    required this.currencyFallback,
  });

  final String title;
  final List<MonthlyReportDay> days;
  final AppLocalizations localization;
  final String currencyFallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Color(0xFF111827),
        );

    final children = <Widget>[
      Text(title, style: titleStyle),
      const SizedBox(height: 12),
    ];

    for (var index = 0; index < days.length; index++) {
      final day = days[index];
      children.add(
        _MonthlyReportDayCard(
          day: day,
          currencySymbol: day.currencySymbol ?? currencyFallback,
          localization: localization,
        ),
      );
      if (index != days.length - 1) {
        children.add(const SizedBox(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _MonthlyReportMessageCard extends StatelessWidget {
  const _MonthlyReportMessageCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = isError ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    final backgroundColor = isError ? const Color(0xFFFFF5F5) : const Color(0xFFEFF6FF);
    final messageStyle = theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14111827),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: backgroundColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(message, style: messageStyle),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ) ??
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyReportLoadingView extends StatelessWidget {
  const _MonthlyReportLoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messageStyle = theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14111827),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(message, style: messageStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MonthlyReportDayCard extends StatelessWidget {
  const _MonthlyReportDayCard({
    required this.day,
    required this.currencySymbol,
    required this.localization,
  });

  final MonthlyReportDay day;
  final String currencySymbol;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Color(0xFF111827),
        );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        );

    final subtitleParts = <String>[];
    if (day.status != null && day.status!.trim().isNotEmpty) {
      subtitleParts.add(day.status!.trim());
    }
    final typeLabel = _resolveTypeLabel(localization);
    if (typeLabel.isNotEmpty) {
      subtitleParts.add(typeLabel);
    }
    final subtitle = subtitleParts.join(' • ');

    final chips = <Widget>[];
    final hoursLabel = day.resolveHoursLabel();
    if (hoursLabel != null && hoursLabel.isNotEmpty) {
      chips.add(
        _MonthlyInfoChip(
          icon: Icons.access_time,
          label: hoursLabel,
          color: const Color(0xFF2563EB),
        ),
      );
    }
    if (day.overtimeHours != null && day.overtimeHours! > 0) {
      final value = day.overtimeHours!;
      final decimals = value == value.roundToDouble() ? 0 : 2;
      chips.add(
        _MonthlyInfoChip(
          icon: Icons.timer_outlined,
          label: 'OT ${value.toStringAsFixed(decimals)} h',
          color: const Color(0xFF7C3AED),
        ),
      );
    }
    final salaryLabel = day.resolveSalaryLabel(currencySymbol);
    if (salaryLabel.isNotEmpty) {
      chips.add(
        _MonthlyInfoChip(
          icon: Icons.payments_outlined,
          label: salaryLabel,
          color: const Color(0xFF059669),
        ),
      );
    }
    if (day.unitsCompleted != null) {
      chips.add(
        _MonthlyInfoChip(
          icon: Icons.check_circle_outline,
          label:
              '${day.unitsCompleted} ${localization.reportsUnitsCompletedSuffix}',
          color: const Color(0xFFF97316),
        ),
      );
    }

    final detailStyle = theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12111827),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day.label, style: titleStyle),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: subtitleStyle),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: chips,
            ),
          ],
          if (day.details.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final detail in day.details)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(detail.label, style: detailStyle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _MonthlyDetailValue(
                        detail: detail,
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (day.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final note in day.notes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• $note',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ) ??
                      const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _resolveTypeLabel(AppLocalizations localization) {
    final raw = day.type;
    if (raw == null) {
      return '';
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final normalized = trimmed.toLowerCase();
    if (normalized == 'hourly' || normalized == 'hourly_work') {
      return localization.reportsMonthlyTypeHourly;
    }
    if (normalized == 'fixed' ||
        normalized == 'fixed_salary' ||
        normalized == 'salary' ||
        normalized == 'contract' ||
        normalized == 'bundle' ||
        normalized == 'bundled' ||
        normalized == 'package') {
      return localization.reportsMonthlyTypeFixed;
    }
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}

class _MonthlyDetailValue extends StatelessWidget {
  const _MonthlyDetailValue({
    required this.detail,
    required this.style,
  });

  final MonthlyReportDayDetail detail;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final entriesSection = _buildEntriesSection(context);
    if (entriesSection != null) {
      return entriesSection;
    }

    final structured = _buildFromRaw(detail.rawValue);
    if (structured != null) {
      return structured;
    }

    final fallback = detail.value.trim();
    if (fallback.isEmpty) {
      return Text('-', style: style);
    }
    return Text(fallback, style: style);
  }

  Widget? _buildEntriesSection(BuildContext context) {
    final normalizedLabel = detail.label.trim().toLowerCase();
    if (normalizedLabel.isEmpty ||
        (!normalizedLabel.contains('entries') &&
            !normalizedLabel.contains('entry'))) {
      return null;
    }

    final rawEntries = _extractEntryMaps(detail.rawValue);
    if (rawEntries.isEmpty) {
      return null;
    }

    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ) ??
        style.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ) ??
        style.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        );
    final labelStyle = style.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF6B7280),
    );
    final valueStyle = style.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF111827),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < rawEntries.length; index++)
          _buildEntryCard(
            entry: rawEntries[index],
            index: index,
            headingStyle: headingStyle,
            subtitleStyle: subtitleStyle,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
      ],
    );
  }

  Widget _buildEntryCard({
    required Map<String, dynamic> entry,
    required int index,
    required TextStyle headingStyle,
    required TextStyle subtitleStyle,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
  }) {
    final sanitized = Map<String, dynamic>.from(entry);

    final headingKey = _takeMatchingKey(sanitized, _headingKeys);
    final headingValue = headingKey != null
        ? _stringifyPrimitive(entry[headingKey])
        : null;

    final statusKey = _takeMatchingKey(sanitized, _entryStatusKeys);
    String? statusLabel;
    if (statusKey != null) {
      statusLabel = _stringifyPrimitive(entry[statusKey]);
    }
    statusLabel ??= _resolvePendingStatus(entry, sanitized);

    for (final key in sanitized.keys.toList()) {
      final normalized = key.toLowerCase();
      if (_entryHiddenKeys.contains(normalized)) {
        sanitized.remove(key);
      }
    }

    final entryHeading = (headingValue != null && headingValue.trim().isNotEmpty)
        ? headingValue.trim()
        : 'Entry ${index + 1}';

    final cards = <Widget>[];
    sanitized.forEach((key, value) {
      final indicatorColor = _resolveMetricColor(key);
      final widget = _buildEntryValue(
        key: key,
        value: value,
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        indicatorColor: indicatorColor,
      );
      if (widget != null) {
        cards.add(widget);
      }
    });

    return Container(
      margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(entryHeading, style: headingStyle),
              ),
              if (statusLabel != null && statusLabel.trim().isNotEmpty)
                _buildStatusChip(statusLabel.trim(), subtitleStyle),
            ],
          ),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _intersperse(cards, 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, TextStyle textStyle) {
    final normalized = status.toLowerCase();
    final color = _resolveStatusColor(normalized);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(_formatStatusLabel(status), style: textStyle.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget? _buildEntryValue({
    required String key,
    required dynamic value,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
    Color? indicatorColor,
  }) {
    if (value is Map) {
      final nested = _buildMap(value);
      if (nested == null) {
        return null;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatKey(key), style: labelStyle),
          const SizedBox(height: 6),
          nested,
        ],
      );
    }

    if (value is List) {
      final nested = _buildList(value);
      if (nested == null) {
        return null;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatKey(key), style: labelStyle),
          const SizedBox(height: 6),
          nested,
        ],
      );
    }

    final text = _stringifyPrimitive(value);
    if (text == null || text.isEmpty) {
      return null;
    }

    if (indicatorColor != null) {
      return _BreakdownRow(
        label: _formatKey(key),
        value: text,
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        indicatorColor: indicatorColor,
      );
    }

    return RichText(
      text: TextSpan(
        style: valueStyle,
        children: [
          TextSpan(
            text: '${_formatKey(key)}: ',
            style: labelStyle,
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractEntryMaps(Object? rawValue) {
    final result = <Map<String, dynamic>>[];

    void addMap(dynamic value) {
      if (value is Map) {
        result.add(value.map((key, dynamic v) => MapEntry(key.toString(), v)));
      }
    }

    if (rawValue is List) {
      for (final item in rawValue) {
        addMap(item);
      }
      return result;
    }

    if (rawValue is Map) {
      var added = false;
      rawValue.forEach((key, value) {
        final normalizedKey = key.toString().toLowerCase();
        if (normalizedKey == 'entries' && value is List) {
          for (final item in value) {
            addMap(item);
          }
          added = true;
        }
      });

      if (!added) {
        addMap(rawValue);
      }
    }

    return result;
  }

  String? _takeMatchingKey(Map<String, dynamic> values, Set<String> keys) {
    for (final key in values.keys.toList()) {
      if (keys.contains(key.toLowerCase())) {
        values.remove(key);
        return key;
      }
    }
    return null;
  }

  String? _resolvePendingStatus(
    Map<String, dynamic> entry,
    Map<String, dynamic> sanitized,
  ) {
    for (final key in entry.keys) {
      final normalized = key.toLowerCase();
      if (normalized == 'is_pending' || normalized == 'pending') {
        final value = entry[key];
        _removeKeyIgnoreCase(sanitized, normalized);
        if (value is bool) {
          return value ? 'Pending' : 'Completed';
        }
        final text = _stringifyPrimitive(value);
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }

  void _removeKeyIgnoreCase(Map<String, dynamic> values, String target) {
    for (final key in values.keys.toList()) {
      if (key.toLowerCase() == target.toLowerCase()) {
        values.remove(key);
        break;
      }
    }
  }

  Color _resolveStatusColor(String status) {
    if (status.contains('pending')) {
      return const Color(0xFFF97316);
    }
    if (status.contains('approved') || status.contains('completed') || status.contains('paid')) {
      return const Color(0xFF059669);
    }
    if (status.contains('rejected') || status.contains('declined')) {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF2563EB);
  }

  String _formatStatusLabel(String status) {
    if (status.trim().isEmpty) {
      return status;
    }
    final words = status
        .replaceAll(RegExp(r'[\-_]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((element) => element.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .toList();
    return words.join(' ');
  }

  Color? _resolveMetricColor(String key) {
    final normalized = key.toLowerCase();
    if (normalized.contains('pending')) {
      return const Color(0xFFF97316);
    }
    if (normalized.contains('approved') || normalized.contains('completed') || normalized.contains('paid')) {
      return const Color(0xFF059669);
    }
    if (normalized.contains('rejected') || normalized.contains('declined') || normalized.contains('failed')) {
      return const Color(0xFFDC2626);
    }
    return null;
  }

  static const Set<String> _entryHiddenKeys = {
    'id',
    'entry_id',
    'entryid',
    'record_id',
    'recordid',
    'work_id',
    'workid',
  };

  static const Set<String> _entryStatusKeys = {
    'status',
    'state',
    'result',
  };

  Widget? _buildFromRaw(Object? rawValue) {
    if (rawValue == null) {
      return null;
    }
    if (rawValue is List) {
      return _buildList(rawValue);
    }
    if (rawValue is Map) {
      return _buildMap(rawValue);
    }

    final text = _stringifyPrimitive(rawValue);
    if (text == null || text.isEmpty) {
      return null;
    }
    return Text(text, style: style);
  }

  Widget? _buildList(List<dynamic> values) {
    if (values.isEmpty) {
      return null;
    }

    final children = <Widget>[];
    final mapCount = values.whereType<Map>().length;

    for (var index = 0; index < values.length; index++) {
      final item = values[index];

      if (item is Map) {
        final heading = _extractHeading(item);
        final content = _buildMap(
          item,
          overrideHeading: null,
          skipKeys: heading == null ? const <String>{} : _headingKeys,
        );
        if (content == null) {
          continue;
        }

        final resolvedHeading = heading ??
            (mapCount > 1 ? 'Entry ${index + 1}' : null);

        Widget child = content;
        if (resolvedHeading != null && resolvedHeading.isNotEmpty) {
          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedHeading,
                style: style.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              content,
            ],
          );
        }

        children.add(
          Container(
            margin: EdgeInsets.only(top: children.isEmpty ? 0 : 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: child,
          ),
        );
        continue;
      }

      if (item is List) {
        final nested = _buildList(item);
        if (nested == null) {
          continue;
        }
        children.add(
          Container(
            margin: EdgeInsets.only(top: children.isEmpty ? 0 : 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: nested,
          ),
        );
        continue;
      }

      final text = _stringifyPrimitive(item);
      if (text == null || text.isEmpty) {
        continue;
      }

      children.add(
        Padding(
          padding: EdgeInsets.only(top: children.isEmpty ? 0 : 4),
          child: Text('• $text', style: style),
        ),
      );
    }

    if (children.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget? _buildMap(
    Map<dynamic, dynamic> rawMap, {
    String? overrideHeading,
    Set<String> skipKeys = const <String>{},
  }) {
    if (rawMap.isEmpty) {
      return null;
    }

    final sanitized = <String, dynamic>{};
    final normalizedLookup = <String, String>{};
    rawMap.forEach((key, value) {
      final stringKey = key.toString();
      final normalizedKey = stringKey.toLowerCase();
      if (skipKeys.contains(normalizedKey)) {
        return;
      }
      sanitized[stringKey] = value;
      normalizedLookup[normalizedKey] = stringKey;
    });

    String? heading = overrideHeading;
    if (heading == null) {
      for (final candidate in _headingKeys) {
        final originalKey = normalizedLookup[candidate];
        if (originalKey == null) {
          continue;
        }
        final rawHeading = sanitized.remove(originalKey);
        final formatted = _stringifyPrimitive(rawHeading);
        if (formatted != null && formatted.isNotEmpty) {
          heading = formatted;
          break;
        }
      }
    }

    final entryWidgets = <Widget>[];
    sanitized.forEach((key, value) {
      final widget = _buildMapEntry(key, value);
      if (widget != null) {
        entryWidgets.add(widget);
      }
    });

    if (entryWidgets.isEmpty) {
      if (heading != null) {
        return Text(
          heading,
          style: style.copyWith(fontWeight: FontWeight.w600),
        );
      }
      return null;
    }

    final spacedEntries = _intersperse(entryWidgets, 6);
    if (heading != null && heading.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...spacedEntries,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spacedEntries,
    );
  }

  Widget? _buildMapEntry(String key, dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      final nested = _buildMap(value);
      if (nested == null) {
        return null;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatKey(key),
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          nested,
        ],
      );
    }

    if (value is List) {
      final nested = _buildList(value);
      if (nested == null) {
        return null;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatKey(key),
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          nested,
        ],
      );
    }

    final text = _stringifyPrimitive(value);
    if (text == null || text.isEmpty) {
      return null;
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(
            text: '${_formatKey(key)}: ',
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }

  String? _extractHeading(Map<dynamic, dynamic> value) {
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (_headingKeys.contains(key.toLowerCase())) {
        final text = _stringifyPrimitive(entry.value);
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }

  String? _stringifyPrimitive(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return value.toString();
  }

  List<Widget> _intersperse(List<Widget> widgets, double spacing) {
    if (widgets.length <= 1) {
      return widgets;
    }
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i != widgets.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }

  String _formatKey(String key) {
    if (key.trim().isEmpty) {
      return key;
    }
    final buffer = StringBuffer();
    var uppercaseNext = true;
    for (var i = 0; i < key.length; i++) {
      final char = key[i];
      if (char == '_' || char == '-') {
        buffer.write(' ');
        uppercaseNext = true;
        continue;
      }
      if (uppercaseNext) {
        buffer.write(char.toUpperCase());
        uppercaseNext = false;
      } else if (char.toUpperCase() == char && char.toLowerCase() != char) {
        buffer.write(' ');
        buffer.write(char);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString().trim();
  }

  static const Set<String> _headingKeys = {
    'label',
    'title',
    'name',
    'entry',
    'header',
  };
}

class _MonthlyInfoChip extends StatelessWidget {
  const _MonthlyInfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: resolvedColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: resolvedColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
                  color: resolvedColor,
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(
                  color: resolvedColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBreakdownCard extends StatelessWidget {
  const _MonthlyBreakdownCard({
    required this.hourlyWorkLabel,
    required this.hourlyTotal,
    required this.contractWorkLabel,
    required this.contractTotal,
    required this.grandTotalLabel,
    required this.grandTotal,
    required this.currencySymbol,
  });

  final String hourlyWorkLabel;
  final double hourlyTotal;
  final String contractWorkLabel;
  final double contractTotal;
  final String grandTotalLabel;
  final double grandTotal;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    TextStyle labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        );

    TextStyle valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        );

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
        children: [
          _BreakdownRow(
            label: hourlyWorkLabel,
            value: _formatCurrencyValue(hourlyTotal, currencySymbol),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
            indicatorColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: contractWorkLabel,
            value: _formatCurrencyValue(contractTotal, currencySymbol),
            labelStyle: labelStyle,
            valueStyle: valueStyle,
            indicatorColor: const Color(0xFF059669),
          ),
          const Divider(height: 32, color: Color(0xFFE5E7EB)),
          _BreakdownRow(
            label: grandTotalLabel,
            value: _formatCurrencyValue(grandTotal, currencySymbol),
            labelStyle: labelStyle.copyWith(
              color: const Color(0xFF111827),
            ),
            valueStyle: valueStyle.copyWith(
              color: const Color(0xFF059669),
            ),
            indicatorColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    required this.indicatorColor,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final Color indicatorColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: labelStyle),
        ),
        Text(value, style: valueStyle),
      ],
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

double _resolveDoubleMetric(double primary, double fallback) {
  if (_isEffectivelyZero(primary) && !_isEffectivelyZero(fallback)) {
    return fallback;
  }
  return primary;
}

int _resolveIntMetric(int primary, int fallback) {
  if (primary <= 0 && fallback > 0) {
    return fallback;
  }
  return primary;
}

bool _isEffectivelyZero(double value) {
  return value.abs() < 0.0001;
}

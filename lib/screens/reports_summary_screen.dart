import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../bloc/work_bloc.dart';
import '../bloc/work_state.dart';
import '../models/report_summary.dart';
import '../models/work.dart';
import '../repositories/reports_repository.dart';

class ReportsSummaryScreen extends StatefulWidget {
  const ReportsSummaryScreen({super.key});

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
    final activeWork = _findActiveWorkFromState(workState);
    final l = AppLocalizations.of(context);

    if (activeWork == null) {
      setState(() {
        _summary = null;
        _summaryError = null;
        _missingWork = true;
        _isLoadingSummary = false;
      });
      return;
    }

    final requestId = ++_summaryRequestId;
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
      _missingWork = false;
    });

    try {
      final repository = context.read<ReportsRepository>();
      final summary = await repository.fetchSummary(
        workId: activeWork.id,
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
    final activeWork = _findActiveWorkFromState(workState);
    final summary = _summary;
    final error = _summaryError;
    final isLoading = _isLoadingSummary;

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

    return BlocListener<WorkBloc, WorkState>(
      listenWhen: (previous, current) {
        final previousId = _findActiveWorkFromState(previous)?.id;
        final currentId = _findActiveWorkFromState(current)?.id;
        return previousId != currentId;
      },
      listener: (context, state) {
        final active = _findActiveWorkFromState(state);
        if (active == null) {
          setState(() {
            _summary = null;
            _summaryError = null;
            _missingWork = true;
            _isLoadingSummary = false;
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
              if (activeWork != null) ...[
                const SizedBox(height: 12),
                _ActiveWorkBadge(workName: activeWork.name),
              ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CombinedSalaryCard(
          title: localization.reportsCombinedSalaryTitle,
          amount: summary.combinedSalary.amount,
          hoursWorked: summary.combinedSalary.hoursWorked,
          unitsCompleted: summary.combinedSalary.unitsCompleted,
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
          hourlyTotal: summary.breakdown.hourlyTotal,
          contractWorkLabel: localization.contractWorkLabel,
          contractTotal: summary.breakdown.contractTotal,
          grandTotalLabel: localization.reportsGrandTotalLabel,
          grandTotal: summary.breakdown.grandTotal,
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
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
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
          Text(workName, style: textStyle),
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
                child: const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF2563EB),
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
        final estimatedHeight =
            baseHeaderExtent + (months.length * 56.0);
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

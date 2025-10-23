import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';

const List<String> _kMonthNames = <String>[
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

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  late final List<String> _availableMonths;
  late final List<String> _availableWorks;

  String _selectedMonth = '';
  String _selectedWork = '';
  String _allWorksLabel = '';
  bool _initialized = false;

  final List<_AttendanceEntry> _entries = <_AttendanceEntry>[

  ];

  final List<_PendingEntry> _pendingEntries = <_PendingEntry>[
    _PendingEntry(
      date: DateTime(2025, 10, 15),
      message: 'Select hours or mark leave',
    ),
    _PendingEntry(
      date: DateTime(2025, 10, 14),
      message: 'Add start and end time',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = DateTime.now();
    if (!_initialized) {
      _availableMonths = List<String>.generate(
        6,
        (index) {
          final date = DateTime(now.year, now.month - index, 1);
          return '${_kMonthNames[date.month - 1]} ${date.year}';
        },
      );
      _selectedMonth = _availableMonths.first;
      _availableWorks = _entries
          .map((entry) => entry.workName)
          .toSet()
          .toList()
        ..sort();
      _selectedWork =
          _availableWorks.isEmpty ? '' : _availableWorks.first;
      _initialized = true;
    }
    final l = AppLocalizations.of(context);
    final newAllWorksLabel = l.attendanceHistoryAllWorks;
    final wasAllWorksSelected =
        _selectedWork.isEmpty || _selectedWork == _allWorksLabel;
    if (_allWorksLabel.isNotEmpty) {
      _availableWorks.remove(_allWorksLabel);
    }
    _allWorksLabel = newAllWorksLabel;
    if (!_availableWorks.contains(_allWorksLabel)) {
      _availableWorks.insert(0, _allWorksLabel);
    }
    if (wasAllWorksSelected || _selectedWork == _allWorksLabel) {
      _selectedWork = _allWorksLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filteredEntries =
        _selectedWork == _allWorksLabel || _selectedWork.isEmpty
        ? _entries
        : _entries.where((entry) => entry.workName == _selectedWork).toList();

    final workedDays =
        filteredEntries.where((entry) => entry.type != _AttendanceEntryType.leave).length;
    final leaveDays = filteredEntries
        .where((entry) => entry.type == _AttendanceEntryType.leave)
        .length;
    final totalHours = filteredEntries.fold<double>(
      0,
      (previousValue, element) => previousValue + element.hoursWorked,
    );
    final overtimeHours = filteredEntries.fold<double>(
      0,
      (previousValue, element) => previousValue + element.overtimeHours,
    );
    final totalSalary = filteredEntries.fold<double>(
      0,
      (previousValue, element) => previousValue + element.salary,
    );

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
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                AppAssets.history,
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l.attendanceHistoryLabel,
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
            _FilterBar(
              months: _availableMonths,
              selectedMonth: _selectedMonth,
              works: _availableWorks,
              selectedWork: _selectedWork,
              onMonthChanged: (value) {
                setState(() {
                  _selectedMonth = value;
                });
              },
              onWorkChanged: (value) {
                setState(() {
                  _selectedWork = value;
                });
              },
            ),
            const SizedBox(height: 20),
     /*       if (_pendingEntries.isNotEmpty)
              _PendingEntriesCard(
                entries: _pendingEntries,
                onResolvePressed: () => _showComingSoonMessage(context),
              )
            else
              _AllCaughtUpBanner(onPressed: () => _showComingSoonMessage(context)),*/
            const SizedBox(height: 20),
            _SummaryCard(
              title: l.attendanceHistorySummaryTitle,
              workedDaysLabel: l.attendanceHistoryWorkedDaysLabel,
              leaveDaysLabel: l.attendanceHistoryLeaveDaysLabel,
              overtimeLabel: l.attendanceHistoryOvertimeLabel,
              totalHoursLabel: l.totalHoursLabel,
              totalSalaryLabel: l.totalSalaryLabel,
              workedDays: workedDays,
              leaveDays: leaveDays,
              totalHours: totalHours,
              overtimeHours: overtimeHours,
              totalSalary: totalSalary,
            ),
            const SizedBox(height: 24),
            _SectionTitle(text: l.attendanceHistoryTimelineTitle),
            const SizedBox(height: 12),
            if (filteredEntries.isEmpty)
              _EmptyState(message: l.attendanceHistoryNoEntriesLabel)
            else
              Column(
                children: filteredEntries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AttendanceEntryTile(
                            entry: entry,
                            localization: l,
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonMessage(BuildContext context) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.helpSupportComingSoon)),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.months,
    required this.selectedMonth,
    required this.works,
    required this.selectedWork,
    required this.onMonthChanged,
    required this.onWorkChanged,
  });

  final List<String> months;
  final String selectedMonth;
  final List<String> works;
  final String selectedWork;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<String> onWorkChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.attendanceHistoryMonthLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
          ),
          const SizedBox(height: 12),
          _DropdownField(
            value: selectedMonth,
            values: months,
            onChanged: onMonthChanged,
          ),
          const SizedBox(height: 18),
          Text(
            l.activeWorkLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
          ),
          const SizedBox(height: 12),
          _DropdownField(
            value: selectedWork,
            values: works,
            onChanged: onWorkChanged,
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFF9FAFB),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          items: values
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}

class _PendingEntriesCard extends StatelessWidget {
  const _PendingEntriesCard({
    required this.entries,
    required this.onResolvePressed,
  });

  final List<_PendingEntry> entries;
  final VoidCallback onResolvePressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD7AA)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFFB923C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.attendanceHistoryPendingTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ) ??
                          const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.attendanceHistoryPendingDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF92400E),
                          ) ??
                          const TextStyle(
                            color: Color(0xFF92400E),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0D5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.dayLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.formattedDate,
                                style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF78350F),
                                        ) ??
                                    const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF78350F),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.message,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF92400E),
                                    ) ??
                                    const TextStyle(
                                      color: Color(0xFF92400E),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEA580C),
              ),
              onPressed: onResolvePressed,
              child: Text(l.attendanceHistoryResolveButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCaughtUpBanner extends StatelessWidget {
  const _AllCaughtUpBanner({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.attendanceHistoryAllCaughtUp,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ) ??
                          const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.attendanceHistoryAllCaughtUpDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF15803D),
                          ) ??
                          const TextStyle(
                            color: Color(0xFF15803D),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF16A34A),
            ),
            child: Text(l.attendanceHistoryResolveButton),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.workedDaysLabel,
    required this.leaveDaysLabel,
    required this.overtimeLabel,
    required this.totalHoursLabel,
    required this.totalSalaryLabel,
    required this.workedDays,
    required this.leaveDays,
    required this.totalHours,
    required this.overtimeHours,
    required this.totalSalary,
  });

  final String title;
  final String workedDaysLabel;
  final String leaveDaysLabel;
  final String overtimeLabel;
  final String totalHoursLabel;
  final String totalSalaryLabel;
  final int workedDays;
  final int leaveDays;
  final double totalHours;
  final double overtimeHours;
  final double totalSalary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _SummaryStat(
                label: workedDaysLabel,
                value: workedDays.toString(),
              ),
              const SizedBox(width: 24),
              _SummaryStat(
                label: leaveDaysLabel,
                value: leaveDays.toString(),
              ),
              const SizedBox(width: 24),
              _SummaryStat(
                label: overtimeLabel,
                value: '${overtimeHours.toStringAsFixed(1)}h',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalHoursLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${totalHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalSalaryLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '€${totalSalary.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
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
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
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
            Icons.calendar_today_rounded,
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

class _AttendanceEntryTile extends StatelessWidget {
  const _AttendanceEntryTile({
    required this.entry,
    required this.localization,
  });

  final _AttendanceEntry entry;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final colorScheme = _resolveColors();
    final statusLabel = _resolveLabel();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.badgeColor,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.badgeTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.formattedDate,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                ),
              ),
              Text(
                '€${entry.salary.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ) ??
                    const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildBody(context),
        ],
      ),
    );
  }

  _EntryColorScheme _resolveColors() {
    switch (entry.type) {
      case _AttendanceEntryType.hourly:
        return const _EntryColorScheme(
          badgeColor: Color(0xFFEFF6FF),
          badgeTextColor: Color(0xFF1D4ED8),
          borderColor: Color(0xFFE0EAFF),
        );
      case _AttendanceEntryType.contract:
        return const _EntryColorScheme(
          badgeColor: Color(0xFFF0FDF4),
          badgeTextColor: Color(0xFF15803D),
          borderColor: Color(0xFFD1FAE5),
        );
      case _AttendanceEntryType.leave:
        return const _EntryColorScheme(
          badgeColor: Color(0xFFFFF7ED),
          badgeTextColor: Color(0xFFB45309),
          borderColor: Color(0xFFFDE68A),
        );
    }
  }

  String _resolveLabel() {
    switch (entry.type) {
      case _AttendanceEntryType.hourly:
        return localization.attendanceHistoryHourlyEntry;
      case _AttendanceEntryType.contract:
        return localization.attendanceHistoryContractEntry;
      case _AttendanceEntryType.leave:
        return localization.attendanceHistoryLeaveEntry;
    }
  }

  List<Widget> _buildBody(BuildContext context) {
    switch (entry.type) {
      case _AttendanceEntryType.hourly:
        return <Widget>[
          _EntryRow(
            label: localization.startTimeLabel,
            value: entry.startTime ?? '--',
          ),
          const SizedBox(height: 8),
          _EntryRow(
            label: localization.endTimeLabel,
            value: entry.endTime ?? '--',
          ),
          const SizedBox(height: 8),
          _EntryRow(
            label: localization.breakLabel,
            value: entry.breakDuration ?? '--',
          ),
          const SizedBox(height: 12),
          _EntryRow(
            label: localization.totalHoursLabel,
            value: '${entry.hoursWorked.toStringAsFixed(1)}h',
          ),
          if (entry.overtimeHours > 0) ...[
            const SizedBox(height: 6),
            _EntryRow(
              label: localization.attendanceHistoryOvertimeEntryLabel,
              value: '${entry.overtimeHours.toStringAsFixed(1)}h',
            ),
          ],
        ];
      case _AttendanceEntryType.contract:
        return <Widget>[
          _EntryRow(
            label: localization.contractWorkLabel,
            value: entry.contractType ?? '--',
          ),
          const SizedBox(height: 8),
          _EntryRow(
            label: localization.contractWorkUnitsLabel,
            value: entry.unitsCompleted?.toString() ?? '0',
          ),
          const SizedBox(height: 8),
          _EntryRow(
            label: localization.contractWorkRateLabel,
            value:
                entry.ratePerUnit != null ? '€${entry.ratePerUnit!.toStringAsFixed(2)}' : '--',
          ),
          if (entry.hoursWorked > 0) ...[
            const SizedBox(height: 12),
            _EntryRow(
              label: localization.attendanceHistoryLoggedHoursLabel,
              value: '${entry.hoursWorked.toStringAsFixed(1)}h',
            ),
          ],
        ];
      case _AttendanceEntryType.leave:
        return <Widget>[
          _EntryRow(
            label: localization.attendanceHistoryReasonLabel,
            value: entry.leaveReason ?? '--',
          ),
        ];
    }
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ) ??
              const TextStyle(
                color: Color(0xFF6B7280),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ) ??
              const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
        ),
      ],
    );
  }
}

class _AttendanceEntry {
  _AttendanceEntry({
    required this.date,
    required this.workName,
    required this.type,
    this.startTime,
    this.endTime,
    this.breakDuration,
    this.hoursWorked = 0,
    this.overtimeHours = 0,
    this.contractType,
    this.unitsCompleted,
    this.ratePerUnit,
    this.leaveReason,
    required this.salary,
  });

  final DateTime date;
  final String workName;
  final _AttendanceEntryType type;
  final String? startTime;
  final String? endTime;
  final String? breakDuration;
  final double hoursWorked;
  final double overtimeHours;
  final String? contractType;
  final int? unitsCompleted;
  final double? ratePerUnit;
  final String? leaveReason;
  final double salary;

  String get formattedDate {
    final month = _kMonthNames[date.month - 1].substring(0, 3);
    return '$month ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }
}

class _PendingEntry {
  _PendingEntry({required this.date, required this.message});

  final DateTime date;
  final String message;

  String get formattedDate {
    final month = _kMonthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  String get dayLabel => date.day.toString().padLeft(2, '0');
}

class _EntryColorScheme {
  const _EntryColorScheme({
    required this.badgeColor,
    required this.badgeTextColor,
    required this.borderColor,
  });

  final Color badgeColor;
  final Color badgeTextColor;
  final Color borderColor;
}

enum _AttendanceEntryType { hourly, contract, leave }

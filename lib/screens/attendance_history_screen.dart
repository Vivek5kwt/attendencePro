import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/attendance_history.dart';
import '../models/work.dart';
import '../repositories/attendance_history_repository.dart';
import '../repositories/work_repository.dart';
import '../utils/responsive.dart';

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
  late final AttendanceHistoryRepository _historyRepository;
  late final WorkRepository _workRepository;

  final List<String> _availableMonths = <String>[];
  List<String> _availableWorks = <String>[];

  final List<_AttendanceEntry> _entries = <_AttendanceEntry>[];
  final List<String> _workNames = <String>[];
  final Map<String, Work> _workLookup = <String, Work>{};

  String _selectedMonth = '';
  String _selectedWork = '';
  String _allWorksLabel = '';
  bool _initialized = false;

  bool _isLoadingWorks = false;
  bool _isLoadingEntries = false;
  bool _missingWork = false;
  bool _requiresAuthentication = false;
  String? _errorMessage;
  String _currencySymbol = '€';

  int _entriesRequestId = 0;

  @override
  void initState() {
    super.initState();
    _historyRepository = AttendanceHistoryRepository();
    _workRepository = WorkRepository();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeMonths();
      _initialized = true;
      _loadWorks();
    }
    final l = AppLocalizations.of(context);
    _updateAllWorksLabel(l.attendanceHistoryAllWorks);
  }

  void _initializeMonths() {
    final now = DateTime.now();
    _availableMonths
      ..clear()
      ..addAll(
        List<String>.generate(
          6,
          (index) {
            final date = DateTime(now.year, now.month - index, 1);
            return '${_kMonthNames[date.month - 1]} ${date.year}';
          },
        ),
      );
    _selectedMonth =
        _availableMonths.isNotEmpty ? _availableMonths.first : '';
  }

  void _updateAllWorksLabel(String label) {
    final wasSelected = _selectedWork == _allWorksLabel;
    _allWorksLabel = label;
    _availableWorks = _buildWorkOptions(_workNames);
    if (wasSelected && _allWorksLabel.isNotEmpty) {
      _selectedWork = _allWorksLabel;
    } else if (_selectedWork.isNotEmpty &&
        !_availableWorks.contains(_selectedWork)) {
      _selectedWork = _availableWorks.isNotEmpty ? _availableWorks.first : '';
    }
  }

  List<String> _buildWorkOptions(List<String> workNames) {
    if (workNames.isEmpty) {
      return _allWorksLabel.isNotEmpty
          ? <String>[_allWorksLabel]
          : const <String>[];
    }
    return <String>[
      if (_allWorksLabel.isNotEmpty) _allWorksLabel,
      ...workNames,
    ];
  }

  Future<void> _loadWorks() async {
    setState(() {
      _isLoadingWorks = true;
      _errorMessage = null;
      _requiresAuthentication = false;
      _missingWork = false;
    });

    try {
      final works = await _workRepository.fetchWorks();
      if (!mounted) {
        return;
      }
      final sortedNames = SplayTreeSet<String>.from(
        works.map((work) => work.name.trim()).where((name) => name.isNotEmpty),
      ).toList(growable: false);

      _workLookup
        ..clear()
        ..addEntries(
          works.map((work) => MapEntry(work.name, work)),
        );

      _workNames
        ..clear()
        ..addAll(sortedNames);

      _availableWorks = _buildWorkOptions(_workNames);

      final activeWork = _findActiveWork(works);
      final defaultSelection = _allWorksLabel.isNotEmpty
          ? _allWorksLabel
          : (activeWork?.name ??
              (_workNames.isNotEmpty ? _workNames.first : ''));

      setState(() {
        _isLoadingWorks = false;
        _missingWork = works.isEmpty;
        _selectedWork = defaultSelection.isNotEmpty
            ? defaultSelection
            : (_availableWorks.contains(_allWorksLabel)
                ? _allWorksLabel
                : '');
      });

      if (works.isNotEmpty) {
        await _loadEntries();
      } else {
        setState(() {
          _entries.clear();
          _currencySymbol = '€';
        });
      }
    } on WorkAuthException {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingWorks = false;
        _requiresAuthentication = true;
        _missingWork = true;
        _entries.clear();
        _workLookup.clear();
        _workNames.clear();
        _availableWorks = _buildWorkOptions(_workNames);
        _selectedWork =
            _availableWorks.contains(_allWorksLabel) ? _allWorksLabel : '';
        _currencySymbol = '€';
      });
    } on WorkRepositoryException catch (e) {
      final l = AppLocalizations.of(context);
      final message = e.message.trim().isEmpty
          ? l.worksLoadFailedMessage
          : e.message;
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingWorks = false;
        _errorMessage = message;
        _missingWork = true;
        _entries.clear();
        _workLookup.clear();
        _workNames.clear();
        _availableWorks = _buildWorkOptions(_workNames);
        _selectedWork =
            _availableWorks.contains(_allWorksLabel) ? _allWorksLabel : '';
        _currencySymbol = '€';
      });
    } catch (_) {
      final l = AppLocalizations.of(context);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingWorks = false;
        _errorMessage = l.worksLoadFailedMessage;
        _missingWork = true;
        _entries.clear();
        _workLookup.clear();
        _workNames.clear();
        _availableWorks = _buildWorkOptions(_workNames);
        _selectedWork =
            _availableWorks.contains(_allWorksLabel) ? _allWorksLabel : '';
        _currencySymbol = '€';
      });
    }
  }

  Future<void> _loadEntries() async {
    if (_selectedMonth.isEmpty) {
      return;
    }

    final targetDate = _parseMonthLabel(_selectedMonth) ?? DateTime.now();

    if (_selectedWork.isEmpty && _availableWorks.isNotEmpty) {
      _selectedWork = _availableWorks.first;
    }

    if (_selectedWork.isEmpty) {
      setState(() {
        _entries.clear();
        _currencySymbol = '€';
      });
      return;
    }

    final requestId = ++_entriesRequestId;
    setState(() {
      _isLoadingEntries = true;
      _errorMessage = null;
      _requiresAuthentication = false;
    });

    try {
      AttendanceHistoryData result;
      if (_selectedWork == _allWorksLabel) {
        result = await _fetchAllWorksHistory(
          month: targetDate.month,
          year: targetDate.year,
        );
      } else {
        final work = _workLookup[_selectedWork];
        if (work == null) {
          throw const AttendanceHistoryRepositoryException(
            'Selected work is unavailable.',
          );
        }
        result = await _historyRepository.fetchHistory(
          workId: work.id,
          workName: work.name,
          month: targetDate.month,
          year: targetDate.year,
        );
      }

      if (!mounted || requestId != _entriesRequestId) {
        return;
      }

      final mappedEntries = result.entries
          .map(_mapEntryFromData)
          .toList(growable: false)
        ..sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _entries
          ..clear()
          ..addAll(mappedEntries);
        _currencySymbol = result.currencySymbol;
        _isLoadingEntries = false;
        _errorMessage = null;
      });
    } on AttendanceHistoryAuthException {
      if (!mounted || requestId != _entriesRequestId) {
        return;
      }
      setState(() {
        _entries.clear();
        _currencySymbol = '€';
        _isLoadingEntries = false;
        _requiresAuthentication = true;
      });
    } on AttendanceHistoryRepositoryException catch (e) {
      final l = AppLocalizations.of(context);
      final message = e.message.trim().isEmpty
          ? l.attendanceHistoryLoadFailedMessage
          : e.message;
      if (!mounted || requestId != _entriesRequestId) {
        return;
      }
      setState(() {
        _entries.clear();
        _currencySymbol = '€';
        _isLoadingEntries = false;
        _errorMessage = message;
      });
    } catch (_) {
      final l = AppLocalizations.of(context);
      if (!mounted || requestId != _entriesRequestId) {
        return;
      }
      setState(() {
        _entries.clear();
        _currencySymbol = '€';
        _isLoadingEntries = false;
        _errorMessage = l.attendanceHistoryLoadFailedMessage;
      });
    }
  }

  Future<AttendanceHistoryData> _fetchAllWorksHistory({
    required int month,
    required int year,
  }) async {
    final entries = <AttendanceHistoryEntryData>[];
    String resolvedCurrency = _currencySymbol;

    for (final work in _workLookup.values) {
      final data = await _historyRepository.fetchHistory(
        workId: work.id,
        workName: work.name,
        month: month,
        year: year,
      );
      if (data.currencySymbol.trim().isNotEmpty) {
        resolvedCurrency = data.currencySymbol;
      }
      entries.addAll(data.entries);
    }

    return AttendanceHistoryData(
      entries: entries,
      currencySymbol:
          resolvedCurrency.trim().isNotEmpty ? resolvedCurrency : '€',
    );
  }

  DateTime? _parseMonthLabel(String label) {
    final parts = label.split(' ');
    if (parts.length != 2) {
      return null;
    }
    final monthIndex = _kMonthNames
        .indexWhere((month) => month.toLowerCase() == parts[0].toLowerCase());
    final year = int.tryParse(parts[1]);
    if (monthIndex == -1 || year == null) {
      return null;
    }
    return DateTime(year, monthIndex + 1, 1);
  }

  _AttendanceEntry _mapEntryFromData(AttendanceHistoryEntryData data) {
    return _AttendanceEntry(
      date: data.date,
      workName: data.workName,
      type: _mapEntryType(data.type),
      startTime: data.startTime,
      endTime: data.endTime,
      breakDuration: data.breakDuration,
      hoursWorked: data.hoursWorked,
      overtimeHours: data.overtimeHours,
      contractType: data.contractType,
      unitsCompleted: data.unitsCompleted,
      ratePerUnit: data.ratePerUnit,
      leaveReason: data.leaveReason,
      salary: data.salary,
    );
  }

  _AttendanceEntryType _mapEntryType(AttendanceHistoryEntryType type) {
    switch (type) {
      case AttendanceHistoryEntryType.hourly:
        return _AttendanceEntryType.hourly;
      case AttendanceHistoryEntryType.contract:
        return _AttendanceEntryType.contract;
      case AttendanceHistoryEntryType.leave:
        return _AttendanceEntryType.leave;
    }
  }

  Work? _findActiveWork(List<Work> works) {
    for (final work in works) {
      if (_isWorkActive(work)) {
        return work;
      }
    }
    return works.isNotEmpty ? works.first : null;
  }

  bool _isWorkActive(Work work) {
    if (work.isActive) {
      return true;
    }

    const possibleKeys = <String>{
      'is_active',
      'isActive',
      'active',
      'is_current',
      'isCurrent',
      'currently_active',
    };

    for (final key in possibleKeys) {
      final value = work.additionalData[key];
      final resolved = _resolveBoolean(value);
      if (resolved != null) {
        return resolved;
      }
    }

    return false;
  }

  bool? _resolveBoolean(dynamic value) {
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

  void _onMonthChanged(String value) {
    if (value == _selectedMonth) {
      return;
    }
    setState(() {
      _selectedMonth = value;
    });
    _loadEntries();
  }

  void _onWorkChanged(String value) {
    if (value == _selectedWork) {
      return;
    }
    setState(() {
      _selectedWork = value;
    });
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;
    final filteredEntries =
        _selectedWork == _allWorksLabel || _selectedWork.isEmpty
            ? _entries
            : _entries
                .where((entry) => entry.workName == _selectedWork)
                .toList();

    final workedDays = filteredEntries
        .where((entry) => entry.type != _AttendanceEntryType.leave)
        .length;
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

    Widget content;
    if (_isLoadingWorks && _entries.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_requiresAuthentication) {
      content = _StatusMessage(message: l.authenticationRequiredMessage);
    } else if (_errorMessage != null) {
      content = _StatusMessage(
        message: _errorMessage!,
        isError: true,
      );
    } else if (_missingWork && _entries.isEmpty) {
      content = _StatusMessage(message: l.startTrackingAttendance);
    } else {
      content = SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          responsive.scale(16),
          responsive.scale(16),
          responsive.scale(16),
          responsive.scale(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterBar(
              months: _availableMonths,
              selectedMonth: _selectedMonth,
              works: _availableWorks,
              selectedWork: _selectedWork,
              onMonthChanged: _onMonthChanged,
              onWorkChanged: _onWorkChanged,
            ),
            SizedBox(height: responsive.scale(20)),
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
              currencySymbol: _currencySymbol,
            ),
            SizedBox(height: responsive.scale(24)),
            _SectionTitle(text: l.attendanceHistoryTimelineTitle),
            SizedBox(height: responsive.scale(12)),
            if (filteredEntries.isEmpty)
              _EmptyState(message: l.attendanceHistoryNoEntriesLabel)
            else
              Column(
                children: filteredEntries
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: responsive.scale(12),
                        ),
                        child: _AttendanceEntryTile(
                          entry: entry,
                          localization: l,
                          currencySymbol: _currencySymbol,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );
    }

    final scaffoldBody = (_isLoadingEntries && _entries.isNotEmpty)
        ? Stack(
            children: [
              content,
              const _LoadingOverlay(),
            ],
          )
        : content;

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
      body: scaffoldBody,
    );
  }

  void _showComingSoonMessage(BuildContext context) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.helpSupportComingSoon)),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB91C1C) : const Color(0xFF6B7280);
    final background = isError ? const Color(0xFFFFE4E6) : Colors.white;
    final border = isError ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB);

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        );

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.08),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
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
    required this.currencySymbol,
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
  final String currencySymbol;

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
                      _formatCurrency(totalSalary),
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

  String _formatCurrency(double value) {
    final symbol = currencySymbol.trim().isEmpty ? '€' : currencySymbol.trim();
    return '$symbol${value.toStringAsFixed(2)}';
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
    required this.currencySymbol,
  });

  final _AttendanceEntry entry;
  final AppLocalizations localization;
  final String currencySymbol;

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
                _formatCurrency(entry.salary),
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

  String _formatCurrency(double value) {
    final symbol = currencySymbol.trim().isEmpty ? '€' : currencySymbol.trim();
    return '$symbol${value.toStringAsFixed(2)}';
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

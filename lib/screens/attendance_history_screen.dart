import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/attendance_history.dart';
import '../models/contract_type.dart';
import '../models/work.dart';
import '../repositories/attendance_entry_repository.dart';
import '../repositories/attendance_history_repository.dart';
import '../repositories/contract_type_repository.dart';
import '../repositories/work_repository.dart';
import '../utils/local_notification_service.dart';
import '../utils/pdf_report_service.dart';
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

const List<String> _kWeekdayNames = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

enum _HistoryViewMode { hours, contract }

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key, this.initialWork});

  final Work? initialWork;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  late final AttendanceHistoryRepository _historyRepository;
  late final AttendanceEntryRepository _entryRepository;
  late final ContractTypeRepository _contractTypeRepository;
  late final WorkRepository _workRepository;

  final List<String> _availableMonths = <String>[];
  List<String> _availableWorks = <String>[];

  final List<_AttendanceEntry> _entries = <_AttendanceEntry>[];
  final List<String> _workNames = <String>[];
  final Map<String, Work> _workLookup = <String, Work>{};
  List<ContractType> _contractTypes = <ContractType>[];

  String _selectedMonth = '';
  String _selectedWork = '';
  _HistoryViewMode _viewMode = _HistoryViewMode.hours;
  bool _initialized = false;
  bool _hasAppliedInitialWork = false;

  bool _isLoadingWorks = false;
  bool _isLoadingEntries = false;
  bool _isLoadingContractTypes = false;
  bool _missingWork = false;
  bool _requiresAuthentication = false;
  String? _errorMessage;
  String _currencySymbol = '€';

  int _entriesRequestId = 0;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _historyRepository = AttendanceHistoryRepository();
    _entryRepository = AttendanceEntryRepository();
    _contractTypeRepository = ContractTypeRepository();
    _workRepository = WorkRepository();
  }

  Future<void> _ensureContractTypesLoaded() async {
    if (_contractTypes.isNotEmpty || _isLoadingContractTypes) {
      return;
    }
    setState(() {
      _isLoadingContractTypes = true;
    });
    try {
      final collection = await _contractTypeRepository.fetchContractTypes();
      if (!mounted) {
        return;
      }
      setState(() {
        _contractTypes = <ContractType>[
          ...collection.userTypes,
          ...collection.globalTypes,
        ];
        _isLoadingContractTypes = false;
      });
    } on ContractTypeAuthException {
      if (!mounted) {
        return;
      }
      setState(() {
        _contractTypes = const <ContractType>[];
        _isLoadingContractTypes = false;
      });
      _showErrorSnackBar(
        AppLocalizations.of(context).authenticationRequiredMessage,
      );
    } on ContractTypeRepositoryException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _contractTypes = const <ContractType>[];
        _isLoadingContractTypes = false;
      });
      if (e.message.trim().isNotEmpty) {
        _showErrorSnackBar(e.message);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _contractTypes = const <ContractType>[];
        _isLoadingContractTypes = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeMonths();
      _initialized = true;
      _loadWorks();
    }
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

  List<String> _buildWorkOptions(List<String> workNames) {
    return List<String>.from(workNames);
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

      final availableWorks = _buildWorkOptions(_workNames);
      final activeWork = _findActiveWork(works);
      final shouldApplyInitialWork =
          !_hasAppliedInitialWork && widget.initialWork != null;
      final initialWork =
      shouldApplyInitialWork ? _resolveInitialWork(works) : null;

      String resolvedSelection = _selectedWork;
      final candidateName = initialWork?.name.trim();
      if (candidateName != null &&
          candidateName.isNotEmpty &&
          availableWorks.contains(candidateName)) {
        resolvedSelection = candidateName;
      }

      if (resolvedSelection.isEmpty ||
          !availableWorks.contains(resolvedSelection)) {
        final activeName = activeWork?.name.trim();
        if (activeName != null &&
            activeName.isNotEmpty &&
            availableWorks.contains(activeName)) {
          resolvedSelection = activeName;
        } else if (availableWorks.isNotEmpty) {
          resolvedSelection = availableWorks.first;
        } else {
          resolvedSelection = '';
        }
      }

      setState(() {
        _isLoadingWorks = false;
        _missingWork = works.isEmpty;
        _availableWorks = availableWorks;
        _selectedWork = resolvedSelection;
        if (shouldApplyInitialWork) {
          _hasAppliedInitialWork = true;
        }
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
        _selectedWork = _availableWorks.isNotEmpty ? _availableWorks.first : '';
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
        _selectedWork = _availableWorks.isNotEmpty ? _availableWorks.first : '';
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
        _selectedWork = _availableWorks.isNotEmpty ? _availableWorks.first : '';
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
      final work = _workLookup[_selectedWork];
      if (work == null) {
        throw const AttendanceHistoryRepositoryException(
          'Selected work is unavailable.',
        );
      }

      final result = await _historyRepository.fetchHistory(
        workId: work.id,
        workName: work.name,
        month: targetDate.month,
        year: targetDate.year,
      );

      if (!mounted || requestId != _entriesRequestId) {
        return;
      }

      final mappedEntries = result.entries
          .map((data) => _mapEntryFromData(data, workId: work.id))
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

  _AttendanceEntry _mapEntryFromData(
      AttendanceHistoryEntryData data, {
        String? workId,
      }) {
    return _AttendanceEntry(
      date: data.date,
      workName: data.workName,
      workId: workId ?? _resolveWorkId(data.workName),
      type: _mapEntryType(data.type),
      startTime: data.startTime,
      endTime: data.endTime,
      breakDuration: data.breakDuration,
      breakMinutes: _parseBreakMinutes(data.breakDuration),
      hoursWorked: data.hoursWorked,
      overtimeHours: data.overtimeHours,
      contractType: data.contractType,
      unitsCompleted: data.unitsCompleted,
      ratePerUnit: data.ratePerUnit,
      leaveReason: data.leaveReason,
      salary: data.salary,
    );
  }

  String? _resolveWorkId(String workName) {
    if (workName.trim().isEmpty) {
      return null;
    }
    final direct = _workLookup[workName]?.id;
    if (direct != null) {
      return direct;
    }
    final normalized = workName.trim().toLowerCase();
    for (final work in _workLookup.values) {
      if (work.name.trim().toLowerCase() == normalized) {
        return work.id;
      }
    }
    return null;
  }

  int _parseBreakMinutes(String? label) {
    if (label == null || label.trim().isEmpty) {
      return 0;
    }
    final normalized = label.toLowerCase();
    final hourMatch = RegExp(r'(\d+)h').firstMatch(normalized);
    final minuteMatch = RegExp(r'(\d+)m').firstMatch(normalized);
    final hours =
    hourMatch != null ? int.tryParse(hourMatch.group(1) ?? '') ?? 0 : 0;
    final minutes =
    minuteMatch != null ? int.tryParse(minuteMatch.group(1) ?? '') ?? 0 : 0;
    if (hours == 0 && minutes == 0) {
      final numeric =
      int.tryParse(normalized.replaceAll(RegExp('[^0-9]'), ''));
      return numeric ?? 0;
    }
    return hours * 60 + minutes;
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

  Work? _resolveInitialWork(List<Work> works) {
    final initialWork = widget.initialWork;
    if (initialWork == null) {
      return null;
    }

    for (final work in works) {
      if (work.id == initialWork.id) {
        return work;
      }
    }

    final normalizedInitialName = initialWork.name.trim().toLowerCase();
    if (normalizedInitialName.isEmpty) {
      return null;
    }

    for (final work in works) {
      if (work.name.trim().toLowerCase() == normalizedInitialName) {
        return work;
      }
    }

    return null;
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

  void _onViewModeChanged(_HistoryViewMode mode) {
    if (_viewMode == mode) {
      return;
    }
    setState(() {
      _viewMode = mode;
    });
  }

  Future<void> _downloadCurrentReport() async {
    if (_isGeneratingReport) {
      return;
    }

    final l = AppLocalizations.of(context);
    final targetEntries = _viewMode == _HistoryViewMode.contract
        ? _entries
            .where((entry) => entry.type == _AttendanceEntryType.contract)
            .toList(growable: false)
        : _entries
            .where(
              (entry) => entry.type == _AttendanceEntryType.hourly ||
                  entry.type == _AttendanceEntryType.leave,
            )
            .toList(growable: false);

    if (targetEntries.isEmpty) {
      _showInfoSnackBar(l.reportDownloadNoEntriesMessage);
      return;
    }

    if (_selectedMonth.isEmpty) {
      _showErrorSnackBar(l.reportDownloadFailedMessage);
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final workName = _selectedWork.trim().isEmpty
          ? l.attendanceHistoryAllWorks
          : _selectedWork.trim();
      if (_viewMode == _HistoryViewMode.contract) {
        final rows = targetEntries
            .map(
              (entry) => ContractReportRow(
                date: entry.date,
                contractType: entry.contractType ?? '',
                unitsCompleted: entry.unitsCompleted ?? 0,
                ratePerUnit: entry.ratePerUnit ?? 0,
                salary: entry.salary,
              ),
            )
            .toList(growable: false);

        final reportFile = await PdfReportService.generateMonthlyContractReport(
          workName: workName,
          monthLabel: _selectedMonth,
          currencySymbol: _currencySymbol,
          rows: rows,
        );

        if (!mounted) {
          return;
        }
        _showSuccessSnackBar(
          l.reportDownloadSuccessMessage(reportFile.path),
        );
        final fileName = reportFile.uri.pathSegments.isNotEmpty
            ? reportFile.uri.pathSegments.last
            : reportFile.path;
        await LocalNotificationService.showDownloadNotification(
          fileName: fileName,
          filePath: reportFile.path,
        );
      } else {
        final grouped = _groupEntriesByDay(targetEntries);
        final days = grouped.entries
            .map(
              (entry) => HistoryReportDay(
                date: entry.key,
                entries: entry.value
                    .map(
                      (item) => HistoryReportEntry(
                        workName: item.workName,
                        typeLabel: _resolveEntryTypeLabel(item.type, l),
                        detail: _buildHistoryDetail(item, l),
                        salary: item.salary,
                      ),
                    )
                    .toList(growable: false),
              ),
            )
            .toList(growable: false);

        final reportFile =
            await PdfReportService.generateAttendanceHistoryReport(
          workName: workName,
          monthLabel: _selectedMonth,
          currencySymbol: _currencySymbol,
          days: days,
        );

        if (!mounted) {
          return;
        }
        _showSuccessSnackBar(
          l.reportDownloadSuccessMessage(reportFile.path),
        );
        final fileName = reportFile.uri.pathSegments.isNotEmpty
            ? reportFile.uri.pathSegments.last
            : reportFile.path;
        await LocalNotificationService.showDownloadNotification(
          fileName: fileName,
          filePath: reportFile.path,
        );
      }
    } on UnsupportedError catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.message?.toString().trim();
      _showErrorSnackBar(
        (message == null || message.isEmpty)
            ? l.reportDownloadFailedMessage
            : message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar(l.reportDownloadFailedMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  String _resolveEntryTypeLabel(
    _AttendanceEntryType type,
    AppLocalizations localization,
  ) {
    switch (type) {
      case _AttendanceEntryType.hourly:
        return localization.attendanceHistoryHourlyEntry;
      case _AttendanceEntryType.contract:
        return localization.attendanceHistoryContractEntry;
      case _AttendanceEntryType.leave:
        return localization.attendanceHistoryLeaveEntry;
    }
  }

  String _buildHistoryDetail(
    _AttendanceEntry entry,
    AppLocalizations localization,
  ) {
    switch (entry.type) {
      case _AttendanceEntryType.hourly:
        final start = entry.startTime?.trim().isEmpty ?? true
            ? '--'
            : entry.startTime!.trim();
        final end = entry.endTime?.trim().isEmpty ?? true
            ? '--'
            : entry.endTime!.trim();
        final hours = _formatHours(entry.hoursWorked);
        final overtime = entry.overtimeHours > 0
            ? ' (+${_formatHours(entry.overtimeHours)} overtime)'
            : '';
        final breakLabel = entry.breakMinutes > 0
            ? ', Break: ${entry.breakMinutes}m'
            : '';
        return '$start - $end ($hours$overtime$breakLabel)';
      case _AttendanceEntryType.contract:
        final units = entry.unitsCompleted ?? 0;
        final rate = entry.ratePerUnit ?? 0;
        final typeLabel = entry.contractType?.trim().isEmpty ?? true
            ? localization.contractWorkUnitFallback
            : entry.contractType!.trim();
        final rateLabel = _formatCurrencyValue(_currencySymbol, rate);
        return '$units $typeLabel @ $rateLabel';
      case _AttendanceEntryType.leave:
        final reason = entry.leaveReason?.trim();
        if (reason == null || reason.isEmpty) {
          return localization.attendanceHistoryLeaveEntry;
        }
        return reason;
    }
  }

  Future<void> _showWorkPicker() async {
    if (_availableWorks.isEmpty) {
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).activeWorkLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ..._availableWorks.map(
                      (work) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: work == _selectedWork
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF9FAFB),
                      title: Text(
                        work,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(work),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected.isNotEmpty && selected != _selectedWork) {
      _onWorkChanged(selected);
    }
  }

  Future<void> _handleEditEntry(_AttendanceEntry entry) async {
    switch (entry.type) {
      case _AttendanceEntryType.hourly:
        await _openHourlyEditSheet(entry);
        break;
      case _AttendanceEntryType.contract:
        await _openContractEditSheet(entry);
        break;
      case _AttendanceEntryType.leave:
        _showInfoSnackBar(
          AppLocalizations.of(context).attendanceHistoryLeaveEntry,
        );
        break;
    }
  }

  Future<void> _openHourlyEditSheet(_AttendanceEntry entry) async {
    final l = AppLocalizations.of(context);
    final workId = entry.workId ?? _workLookup[_selectedWork]?.id;
    if (workId == null) {
      _showErrorSnackBar(l.attendanceHistoryLoadFailedMessage);
      return;
    }

    final startController =
    TextEditingController(text: entry.startTime ?? '');
    final endController = TextEditingController(text: entry.endTime ?? '');
    final breakController = TextEditingController(
      text: entry.breakMinutes > 0 ? entry.breakMinutes.toString() : '0',
    );

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.workName} · ${_formatDayLabel(entry.date)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: startController,
                      decoration: InputDecoration(
                        labelText: l.startTimeLabel,
                      ),
                      validator: _validateTimeInput,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: endController,
                      decoration: InputDecoration(
                        labelText: l.endTimeLabel,
                      ),
                      validator: _validateTimeInput,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: breakController,
                      decoration: InputDecoration(
                        labelText: l.breakLabel,
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateMinutesInput,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l.cancelButton),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                            if (!(formKey.currentState?.validate() ??
                                false)) {
                              return;
                            }
                            final start =
                            _parseTimeOfDay(startController.text);
                            final end =
                            _parseTimeOfDay(endController.text);
                            if (start == null || end == null) {
                              _showErrorSnackBar(
                                l.attendanceHistoryLoadFailedMessage,
                              );
                              return;
                            }
                            final breakMinutes = int.tryParse(
                                breakController.text.trim()) ??
                                0;
                            final workedMinutes =
                            _calculateWorkedMinutes(start, end);
                            if (workedMinutes <= breakMinutes) {
                              _showErrorSnackBar(
                                l.attendanceHistoryLoadFailedMessage,
                              );
                              return;
                            }
                            setModalState(() {
                              isSaving = true;
                            });
                            final success =
                            await _submitHourlyAttendance(
                              workId: workId,
                              date: entry.date,
                              start: start,
                              end: end,
                              breakMinutes: breakMinutes,
                            );
                            if (success && mounted) {
                              Navigator.of(context).pop();
                            }
                            if (mounted) {
                              setModalState(() {
                                isSaving = false;
                              });
                            }
                          },
                          child: isSaving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                              : Text(l.saveButtonLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openContractEditSheet(_AttendanceEntry entry) async {
    final l = AppLocalizations.of(context);
    final workId = entry.workId ?? _workLookup[_selectedWork]?.id;
    if (workId == null) {
      _showErrorSnackBar(l.attendanceHistoryLoadFailedMessage);
      return;
    }

    await _ensureContractTypesLoaded();
    if (_contractTypes.isEmpty) {
      _showErrorSnackBar(l.contractWorkLoadError);
      return;
    }

    ContractType? selectedType;
    final normalized = entry.contractType?.trim().toLowerCase();
    for (final type in _contractTypes) {
      if (type.name.trim().toLowerCase() == normalized) {
        selectedType = type;
        break;
      }
    }
    selectedType ??= _contractTypes.first;

    final quantityController = TextEditingController(
      text: entry.unitsCompleted != null && entry.unitsCompleted! > 0
          ? entry.unitsCompleted.toString()
          : '',
    );
    final rateController = TextEditingController(
      text: entry.ratePerUnit != null && entry.ratePerUnit! > 0
          ? entry.ratePerUnit!.toStringAsFixed(2)
          : '',
    );

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.workName} · ${_formatDayLabel(entry.date)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ContractType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: l.contractWorkLabel,
                      ),
                      items: _contractTypes
                          .map(
                            (type) => DropdownMenuItem<ContractType>(
                          value: type,
                          child: Text(type.name),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: l.contractWorkUnitsLabel,
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateUnitsInput,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: rateController,
                      decoration: InputDecoration(
                        labelText: l.contractWorkRateLabel,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateRateInput,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l.cancelButton),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                            if (!(formKey.currentState?.validate() ??
                                false)) {
                              return;
                            }
                            final type = selectedType;
                            if (type == null) {
                              _showErrorSnackBar(
                                l.contractWorkLoadError,
                              );
                              return;
                            }
                            final typeId =
                            int.tryParse(type.id.trim());
                            if (typeId == null) {
                              _showErrorSnackBar(
                                l.contractWorkLoadError,
                              );
                              return;
                            }
                            final units = int.tryParse(
                                quantityController.text.trim()) ??
                                0;
                            final rate = double.tryParse(
                                rateController.text.trim());
                            if (units <= 0 ||
                                rate == null ||
                                rate <= 0) {
                              _showErrorSnackBar(
                                l.contractWorkLoadError,
                              );
                              return;
                            }
                            setModalState(() {
                              isSaving = true;
                            });
                            final success =
                            await _submitContractAttendance(
                              workId: workId,
                              date: entry.date,
                              contractTypeId: typeId,
                              units: units,
                              ratePerUnit: rate,
                            );
                            if (success && mounted) {
                              Navigator.of(context).pop();
                            }
                            if (mounted) {
                              setModalState(() {
                                isSaving = false;
                              });
                            }
                          },
                          child: isSaving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                              : Text(l.saveButtonLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _submitHourlyAttendance({
    required String workId,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required int breakMinutes,
  }) async {
    final requestDate = DateTime(date.year, date.month, date.day);
    try {
      setState(() {
        _isLoadingEntries = true;
      });
      await _entryRepository.submitAttendance(
        workId: workId,
        date: requestDate,
        startTime: _formatTimeOfDay(start),
        endTime: _formatTimeOfDay(end),
        breakMinutes: breakMinutes,
      );
      await _loadEntries();
      _showSuccessSnackBar(
        AppLocalizations.of(context).attendanceSubmitSuccess,
      );
      return true;
    } on AttendanceAuthException {
      _showErrorSnackBar(
        AppLocalizations.of(context).authenticationRequiredMessage,
      );
    } on AttendanceRepositoryException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (_) {
      _showErrorSnackBar(
        AppLocalizations.of(context).attendanceHistoryLoadFailedMessage,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEntries = false;
        });
      }
    }
    return false;
  }

  Future<bool> _submitContractAttendance({
    required String workId,
    required DateTime date,
    required int contractTypeId,
    required int units,
    required double ratePerUnit,
  }) async {
    final requestDate = DateTime(date.year, date.month, date.day);
    try {
      setState(() {
        _isLoadingEntries = true;
      });
      await _entryRepository.submitAttendance(
        workId: workId,
        date: requestDate,
        isContractEntry: true,
        contractTypeId: contractTypeId,
        units: units,
        ratePerUnit: ratePerUnit,
      );
      await _loadEntries();
      _showSuccessSnackBar(
        AppLocalizations.of(context).attendanceSubmitSuccess,
      );
      return true;
    } on AttendanceAuthException {
      _showErrorSnackBar(
        AppLocalizations.of(context).authenticationRequiredMessage,
      );
    } on AttendanceRepositoryException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (_) {
      _showErrorSnackBar(
        AppLocalizations.of(context).attendanceHistoryLoadFailedMessage,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEntries = false;
        });
      }
    }
    return false;
  }

  void _showErrorSnackBar(String message) {
    final trimmed = message.trim();
    if (!mounted || trimmed.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(trimmed),
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final trimmed = message.trim();
    if (!mounted || trimmed.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(trimmed),
        backgroundColor: const Color(0xFF15803D),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    final trimmed = message.trim();
    if (!mounted || trimmed.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(trimmed)),
    );
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null) {
      return null;
    }
    final sanitized = value.trim();
    if (sanitized.isEmpty) {
      return null;
    }
    final parts = sanitized.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _calculateWorkedMinutes(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes - startMinutes;
  }

  String? _validateTimeInput(String? value) {
    if (_parseTimeOfDay(value) == null) {
      return AppLocalizations.of(context).attendanceHistoryLoadFailedMessage;
    }
    return null;
  }

  String? _validateMinutesInput(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      return AppLocalizations.of(context).attendanceHistoryLoadFailedMessage;
    }
    return null;
  }

  String? _validateUnitsInput(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return AppLocalizations.of(context).contractWorkLoadError;
    }
    return null;
  }

  String? _validateRateInput(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return AppLocalizations.of(context).contractWorkLoadError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;
    final filteredEntries = List<_AttendanceEntry>.from(_entries);

    final hoursEntries = filteredEntries
        .where((entry) =>
    entry.type == _AttendanceEntryType.hourly ||
        entry.type == _AttendanceEntryType.leave)
        .toList();

    final contractEntries = filteredEntries
        .where((entry) => entry.type == _AttendanceEntryType.contract)
        .toList();

    final viewEntries =
    _viewMode == _HistoryViewMode.hours ? hoursEntries : contractEntries;

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
      final historyWidget = viewEntries.isEmpty
          ? _EmptyState(
        message: _viewMode == _HistoryViewMode.hours
            ? l.attendanceHistoryNoEntriesLabel
            : l.contractWorkNoEntriesLabel,
      )
          : _viewMode == _HistoryViewMode.hours
          ? _HoursHistoryList(
        entries: hoursEntries,
        currencySymbol: _currencySymbol,
        localization: l,
        onEdit: _handleEditEntry,
      )
          : _ContractHistoryList(
        entries: contractEntries,
        currencySymbol: _currencySymbol,
        localization: l,
        onEdit: _handleEditEntry,
      );

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
            _HistoryFilterBar(
              months: _availableMonths,
              selectedMonth: _selectedMonth,
              viewMode: _viewMode,
              onMonthChanged: _onMonthChanged,
              onViewModeChanged: _onViewModeChanged,
            ),
            SizedBox(height: responsive.scale(16)),
            _SelectedWorkBanner(
              workName: _selectedWork,
              onChange: _availableWorks.length > 1 ? _showWorkPicker : null,
            ),
            SizedBox(height: responsive.scale(24)),
            if (viewEntries.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed:
                      _isGeneratingReport ? null : _downloadCurrentReport,
                  icon: _isGeneratingReport
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _viewMode == _HistoryViewMode.contract
                        ? l.contractReportDownloadLabel
                        : l.historyReportDownloadLabel,
                  ),
                ),
              ),
              SizedBox(height: responsive.scale(16)),
            ],
            historyWidget,
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: colorScheme.onSurface,
    ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: colorScheme.onSurface,
        );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                AppAssets.history,
                width: 24,
                height: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.attendanceHistoryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
          ],
        ),
        actions: [
          if (_availableWorks.length > 1)
            IconButton(
              icon: Icon(
                Icons.work_outline,
                color: colorScheme.primary,
              ),
              tooltip: l.changeWorkButton,
              onPressed: _showWorkPicker,
            ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
            ),
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

// ─────────────────────────────────────────────────────────────────────────────
// STATUS + LOADING
// ─────────────────────────────────────────────────────────────────────────────

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB91C1C) : const Color(0xFF6B7280);
    final background = isError ? const Color(0xFFFFE4E6) : Colors.white;
    final border = isError ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB);

    final textStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
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

// ─────────────────────────────────────────────────────────────────────────────
/* FILTER BAR (Month / View Mode pills row) */
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({
    required this.months,
    required this.selectedMonth,
    required this.viewMode,
    required this.onMonthChanged,
    required this.onViewModeChanged,
  });

  final List<String> months;
  final String selectedMonth;
  final _HistoryViewMode viewMode;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<_HistoryViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final resolvedMonth = months.contains(selectedMonth)
        ? selectedMonth
        : (months.isNotEmpty ? months.first : null);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFB200)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FBBF24),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown<String>(
              value: resolvedMonth,
              values: months,
              placeholder: l.attendanceHistoryMonthLabel,
              labelBuilder: (value) => value,
              onChanged: onMonthChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilterDropdown<_HistoryViewMode>(
              value: viewMode,
              values: const <_HistoryViewMode>[
                _HistoryViewMode.hours,
                _HistoryViewMode.contract,
              ],
              placeholder:
              '${l.attendanceHistoryHourlyEntry} / ${l.attendanceHistoryContractEntry}',
              labelBuilder: (mode) => mode == _HistoryViewMode.hours
                  ? l.attendanceHistoryHourlyEntry
                  : l.attendanceHistoryContractEntry,
              onChanged: onViewModeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    this.value,
    required this.values,
    required this.placeholder,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T? value;
  final List<T> values;
  final String placeholder;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && values.contains(value);
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1F2937),
    ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFC241),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFA000)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: hasValue ? value : null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF111827),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(18),
          hint: Text(
            placeholder,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ) ??
                const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
          ),
          items: values
              .map(
                (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: textStyle,
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

// ─────────────────────────────────────────────────────────────────────────────
/* SELECTED WORK BANNER */
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedWorkBanner extends StatelessWidget {
  const _SelectedWorkBanner({
    required this.workName,
    this.onChange,
  });

  final String workName;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasWork = workName.trim().isNotEmpty;
    final displayName =
    hasWork ? '${l.activeWorkLabel}: $workName' : l.activeWorkLabel;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.work_outline, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ) ??
                  const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
            ),
          ),
          if (onChange != null)
            TextButton(
              onPressed: onChange,
              child: Text(
                l.changeWorkButton,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/* HOURS HISTORY LIST */
// ─────────────────────────────────────────────────────────────────────────────

class _HoursHistoryList extends StatelessWidget {
  const _HoursHistoryList({
    required this.entries,
    required this.currencySymbol,
    required this.localization,
    required this.onEdit,
  });

  final List<_AttendanceEntry> entries;
  final String currencySymbol;
  final AppLocalizations localization;
  final ValueChanged<_AttendanceEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupEntriesByDay(entries);
    final dayGroups = grouped.entries.toList(growable: false);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: dayGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = dayGroups[index];
        return _HoursDayCard(
          date: entry.key,
          entries: entry.value,
          currencySymbol: currencySymbol,
          localization: localization,
          onEdit: onEdit,
        );
      },
    );
  }
}

class _HoursDayCard extends StatelessWidget {
  const _HoursDayCard({
    required this.date,
    required this.entries,
    required this.currencySymbol,
    required this.localization,
    required this.onEdit,
  });

  final DateTime date;
  final List<_AttendanceEntry> entries;
  final String currencySymbol;
  final AppLocalizations localization;
  final ValueChanged<_AttendanceEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final dayTotal = entries.fold<double>(
      0,
          (previousValue, element) => previousValue + element.salary,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header row: "Thu, 06 Feb" + total for the day
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDayLabel(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ) ??
                    const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
              ),
              Text(
                _formatCurrencyValue(currencySymbol, dayTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2563EB),
                ) ??
                    const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // list of entries for that date
          Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                _HourlyEntryTile(
                  entry: entries[i],
                  currencySymbol: currencySymbol,
                  localization: localization,
                  onEdit: onEdit,
                ),
                if (i != entries.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HourlyEntryTile extends StatelessWidget {
  const _HourlyEntryTile({
    required this.entry,
    required this.currencySymbol,
    required this.localization,
    required this.onEdit,
  });

  final _AttendanceEntry entry;
  final String currencySymbol;
  final AppLocalizations localization;
  final ValueChanged<_AttendanceEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final isLeave = entry.type == _AttendanceEntryType.leave;

    final workNameTextStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ) ??
            const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            );

    final amountTextStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF047857),
        ) ??
            const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF047857),
            );

    final labelStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6B7280),
          fontSize: 11,
        ) ??
            const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              fontSize: 11,
            );

    final valueStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
          fontSize: 13,
        ) ??
            const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              fontSize: 13,
            );

    final start = (entry.startTime ?? '').trim().isNotEmpty
        ? entry.startTime!.trim()
        : '--';
    final end = (entry.endTime ?? '').trim().isNotEmpty
        ? entry.endTime!.trim()
        : '--';
    final breakLabel = (entry.breakDuration ?? '').trim().isNotEmpty
        ? entry.breakDuration!.trim()
        : '--';
    final totalHours =
    entry.hoursWorked > 0 ? _formatHours(entry.hoursWorked) : '0h 0m';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLeave
              ? const Color(0xFFFCD34D) // leave highlight border
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Work + Leave badge + Edit button on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // left side (icon + work name + leave chip)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // small icon bubble
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLeave
                            ? const Color(0xFFFFF7E6)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLeave
                              ? const Color(0xFFFACC15)
                              : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Icon(
                        isLeave ? Icons.beach_access_rounded : Icons.work,
                        size: 16,
                        color: isLeave
                            ? const Color(0xFFCA8A04)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Work name + Leave badge
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 4,
                        spacing: 8,
                        children: [
                          Text(
                            isLeave
                                ? localization.attendanceHistoryLeaveEntry
                                : entry.workName,
                            style: workNameTextStyle,
                          ),
                          if (isLeave)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFACC15),
                                ),
                              ),
                              child: const Text(
                                'Leave',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFCA8A04),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // right side edit button
              const SizedBox(width: 12),
              _EditButtonTextOnly(
                enabled: !isLeave,
                onPressed: !isLeave ? () => onEdit(entry) : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Row 2: Time stats (responsive wrap)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoStatMiniCard(
                label: localization.startTimeLabel,
                value: start,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
              _InfoStatMiniCard(
                label: localization.endTimeLabel,
                value: end,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
              _InfoStatMiniCard(
                label: localization.breakLabel,
                value: breakLabel,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
              _InfoStatMiniCard(
                label: localization.totalHoursLabel,
                value: totalHours,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Row 3: Salary bottom right
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatCurrencyValue(currencySymbol, entry.salary),
              textAlign: TextAlign.right,
              style: amountTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}

// small stat chip (value on top, label below)
class _InfoStatMiniCard extends StatelessWidget {
  const _InfoStatMiniCard({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: valueStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// EDIT pill for hourly card (TEXT ONLY, responsive-safe)
class _EditButtonTextOnly extends StatelessWidget {
  const _EditButtonTextOnly({
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bgEnabled = const Color(0xFF2563EB);
    final bgDisabled = const Color(0xFF93C5FD);

    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? bgEnabled : bgDisabled,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Edit',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// EDIT pill with icon for contract rows (unchanged for now)
class _EditButton extends StatelessWidget {
  const _EditButton({
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bgEnabled = const Color(0xFF2563EB);
    final bgDisabled = const Color(0xFF93C5FD);

    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? bgEnabled : bgDisabled,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.edit,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            'Edit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/* CONTRACT HISTORY LIST */
// ─────────────────────────────────────────────────────────────────────────────

class _ContractHistoryList extends StatelessWidget {
  const _ContractHistoryList({
    required this.entries,
    required this.currencySymbol,
    required this.localization,
    required this.onEdit,
  });

  final List<_AttendanceEntry> entries;
  final String currencySymbol;
  final AppLocalizations localization;
  final ValueChanged<_AttendanceEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupEntriesByDay(entries);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: grouped.entries
          .map(
            (entry) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ContractDayCard(
            date: entry.key,
            entries: entry.value,
            currencySymbol: currencySymbol,
            localization: localization,
            onEdit: onEdit,
          ),
        ),
      )
          .toList(),
    );
  }
}

class _ContractDayCard extends StatelessWidget {
  const _ContractDayCard({
    required this.date,
    required this.entries,
    required this.currencySymbol,
    required this.localization,
    required this.onEdit,
  });

  final DateTime date;
  final List<_AttendanceEntry> entries;
  final String currencySymbol;
  final AppLocalizations localization;
  final ValueChanged<_AttendanceEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final dayTotal = entries.fold<double>(
      0,
          (previousValue, element) => previousValue + element.salary,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDayLabel(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ) ??
                    const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
              ),
              Text(
                _formatCurrencyValue(currencySymbol, dayTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2563EB),
                ) ??
                    const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _ResponsiveTable(
            minWidth: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ContractTableHeader(localization: localization),
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const SizedBox.shrink()
                else
                  ...List<Widget>.generate(entries.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return const Divider(
                        height: 20,
                        thickness: 1,
                        color: Color(0xFFE5E7EB),
                      );
                    }
                    final entry = entries[index ~/ 2];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _ContractTableRow(
                        entry: entry,
                        currencySymbol: currencySymbol,
                        localization: localization,
                        onEdit: onEdit,
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localization.contractWorkTotalSalaryLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                ),
                Text(
                  _formatCurrencyValue(currencySymbol, dayTotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF047857),
                  ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
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

class _ContractTableHeader extends StatelessWidget {
  const _ContractTableHeader({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF374151),
    ) ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        );

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            localization.contractWorkNameLabel,
            style: style,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '${localization.contractWorkUnitsLabel} (${localization.contractWorkRoleLabel})',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            localization.totalSalaryLabel,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            'Edit',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _ContractTableRow extends StatelessWidget {
  const _ContractTableRow({
    required this.entry,
    required this.currencySymbol,
    required this.localization,
    required this.onEdit,
  });

  final _AttendanceEntry entry;
  final String currencySymbol;
  final AppLocalizations localization;
  final ValueChanged<_AttendanceEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final units = entry.unitsCompleted;
    final contractLabel = entry.contractType?.isNotEmpty == true
        ? entry.contractType!
        : localization.contractWorkUnitFallback;
    final quantityLabel = units != null && units > 0
        ? '$units ($contractLabel)'
        : contractLabel;

    final workStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF111827),
    ) ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        );

    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF374151),
    ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              entry.workName,
              style: workStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              quantityLabel,
              textAlign: TextAlign.center,
              style: valueStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrencyValue(currencySymbol, entry.salary),
              textAlign: TextAlign.center,
              style: valueStyle.copyWith(
                color: const Color(0xFF047857),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: _EditButton(
              enabled: true,
              onPressed: () => onEdit(entry),
            ),
          ),
        ],
      ),
    );
  }
}

// Table is horizontal scrollable if screen is too narrow → responsive
class _ResponsiveTable extends StatelessWidget {
  const _ResponsiveTable({
    required this.child,
    this.minWidth = 620,
  });

  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < minWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth,
                maxWidth: minWidth,
              ),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/* UTIL + MODELS */
// ─────────────────────────────────────────────────────────────────────────────

SplayTreeMap<DateTime, List<_AttendanceEntry>> _groupEntriesByDay(
    List<_AttendanceEntry> entries,
    ) {
  final map = SplayTreeMap<DateTime, List<_AttendanceEntry>>(
        (a, b) => b.compareTo(a),
  );
  for (final entry in entries) {
    final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
    map.putIfAbsent(key, () => <_AttendanceEntry>[]).add(entry);
  }
  return map;
}

String _formatDayLabel(DateTime date) {
  final index = (date.weekday - 1).clamp(0, 6);
  final weekday = _kWeekdayNames[index.toInt()];
  final monthLabel = _kMonthNames[date.month - 1].substring(0, 3);
  final day = date.day.toString().padLeft(2, '0');
  return '$weekday, $day $monthLabel';
}

String _formatCurrencyValue(String symbol, double value) {
  final resolved = symbol.trim().isEmpty ? '€' : symbol.trim();
  return '$resolved${value.toStringAsFixed(2)}';
}

String _formatHours(double hours) {
  final totalMinutes = (hours * 60).round();
  final clampedMinutes = totalMinutes < 0 ? 0 : totalMinutes;
  final resolvedHours = clampedMinutes ~/ 60;
  final minutes = clampedMinutes % 60;
  return '${resolvedHours}h ${minutes}m';
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

class _AttendanceEntry {
  _AttendanceEntry({
    required this.date,
    required this.workName,
    this.workId,
    required this.type,
    this.startTime,
    this.endTime,
    this.breakDuration,
    this.breakMinutes = 0,
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
  final String? workId;
  final _AttendanceEntryType type;
  final String? startTime;
  final String? endTime;
  final String? breakDuration;
  final int breakMinutes;
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

enum _AttendanceEntryType { hourly, contract, leave }

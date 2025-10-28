import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_strings.dart';
import '../core/localization/app_localizations.dart';
import '../models/contract_type.dart';
import '../models/dashboard_summary.dart';
import '../models/missed_attendance_completion.dart';
import '../models/work.dart';
import '../repositories/attendance_entry_repository.dart';
import '../repositories/contract_type_repository.dart';
import '../repositories/dashboard_repository.dart';
import 'contract_work_screen.dart';

const List<int> _timeHourOptions = <int>[
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
];

const List<int> _timeMinuteOptions = <int>[
  0,
  5,
  10,
  15,
  20,
  25,
  30,
  35,
  40,
  45,
  50,
  55,
];

const List<int> _breakDurationOptions = <int>[
  0,
  5,
  10,
  15,
  20,
  25,
  30,
  35,
  40,
  45,
  50,
  55,
  60,
];

const List<int> _breakHourOptions = <int>[0, 1];

List<_TimeDropdownOption> _generateTimeDropdownOptions() {
  final options = <_TimeDropdownOption>[];
  for (final period in DayPeriod.values) {
    for (final hour in _timeHourOptions) {
      for (final minute in _timeMinuteOptions) {
        final value = _formatTimeDropdownValue(hour, minute, period);
        final label = _formatTimeDropdownLabel(hour, minute, period);
        options.add(_TimeDropdownOption(value: value, label: label));
      }
    }
  }
  return options;
}

final List<_TimeDropdownOption> _timeDropdownOptions =
    _generateTimeDropdownOptions();

final Set<String> _timeDropdownValueSet =
    _timeDropdownOptions.map((option) => option.value).toSet();

String _formatTimeDropdownValue(int hour, int minute, DayPeriod period) {
  final hour24 = _to24Hour(hour, period);
  final hourText = hour24.toString().padLeft(2, '0');
  final minuteText = minute.toString().padLeft(2, '0');
  return '$hourText:$minuteText';
}

String _formatTimeDropdownLabel(int hour, int minute, DayPeriod period) {
  final minuteText = minute.toString().padLeft(2, '0');
  final periodText = period == DayPeriod.am
      ? AppString.amLabel
      : AppString.pmLabel;
  return '$hour:$minuteText $periodText';
}

int _to24Hour(int hour, DayPeriod period) {
  var normalized = hour % 12;
  if (period == DayPeriod.pm) {
    normalized += 12;
  } else if (period == DayPeriod.am && hour == 12) {
    normalized = 0;
  }
  return normalized;
}

int _toDisplayHour(int hour24) {
  final hourOfPeriod = hour24 % 12;
  return hourOfPeriod == 0 ? 12 : hourOfPeriod;
}

List<int> _buildMinuteOptions(int selectedMinute) {
  final options = Set<int>.from(_timeMinuteOptions);
  if (selectedMinute >= 0 && selectedMinute < 60) {
    options.add(selectedMinute);
  }
  final sorted = options.toList()..sort();
  return sorted;
}

List<int> _breakMinutesForHour(int hour) {
  final minutes = _breakDurationOptions
      .where((value) => value ~/ 60 == hour)
      .map((value) => value % 60)
      .toSet()
      .toList()
    ..sort();
  return minutes.isEmpty ? <int>[0] : minutes;
}

List<DropdownMenuItem<String?>> _buildTimeDropdownMenuItems({TextStyle? textStyle}) {
  final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?> (
        value: null,
        child: Text(
          AppString.timePlaceholder,
          style: textStyle,
        ),
      ),
  ];
  for (final option in _timeDropdownOptions) {
    items.add(
      DropdownMenuItem<String?> (
        value: option.value,
        child: Text(
          option.label,
          style: textStyle,
        ),
      ),
    );
  }
  return items;
}

String? _normalizeTimeDropdownValue(String value) {
  final parsed = _parseFlexibleTime(value);
  if (parsed == null) {
    return null;
  }
  final normalized = _formatTimeOfDay(parsed);
  return _timeDropdownValueSet.contains(normalized) ? normalized : null;
}

TimeOfDay? _parseFlexibleTime(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final parts = trimmed.split(RegExp('\\s+'));
  if (parts.isEmpty) {
    return null;
  }

  final timePart = parts.first;
  final timePieces = timePart.split(':');
  if (timePieces.length != 2) {
    return null;
  }

  final hours = int.tryParse(timePieces[0]);
  final minutes = int.tryParse(timePieces[1]);
  if (hours == null || minutes == null) {
    return null;
  }
  if (minutes < 0 || minutes > 59) {
    return null;
  }

  var normalizedHours = hours;
  if (parts.length > 1) {
    final periodText = parts[1].toLowerCase();
    normalizedHours = hours % 12;
    if (periodText.startsWith('p')) {
      normalizedHours += 12;
    } else if (periodText.startsWith('a') && hours == 12) {
      normalizedHours = 0;
    }
  }

  if (normalizedHours < 0 || normalizedHours > 23) {
    return null;
  }

  return TimeOfDay(hour: normalizedHours, minute: minutes);
}

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

List<DropdownMenuItem<int?>> _buildBreakDropdownMenuItems({TextStyle? textStyle}) {
  final items = <DropdownMenuItem<int?>>[
    DropdownMenuItem<int?> (
      value: null,
      child: Text(
        '--',
        style: textStyle,
      ),
    ),
  ];

  for (final minutes in _breakDurationOptions) {
    items.add(
      DropdownMenuItem<int?> (
        value: minutes,
        child: Text(
          _formatBreakOptionLabel(minutes),
          style: textStyle,
        ),
      ),
    );
  }
  return items;
}

String _formatBreakOptionLabel(int minutes) {
  if (minutes == 0) {
    return AppString.zeroMinutesLabel;
  }
  if (minutes == 60) {
    return AppString.sixtyMinutesLabel;
  }
  return '$minutes ${AppString.minutesSuffix}';
}

Widget _buildTimeDropdownField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required bool enabled,
  required String? Function(String?) validator,
  VoidCallback? onChanged,
}) {
  final normalizedValue = _normalizeTimeDropdownValue(controller.text);
  return DropdownButtonFormField<String?> (
    value: normalizedValue,
    items: _buildTimeDropdownMenuItems(),
    onChanged: enabled
        ? (value) {
            final text = value ?? '';
            controller
              ..text = text
              ..selection = TextSelection.collapsed(offset: text.length);
            onChanged?.call();
          }
        : null,
    validator: validator,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    hint: const Text(AppString.timePlaceholder),
    dropdownColor: Colors.white,
  );
}

Widget _buildBreakDropdownField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required bool enabled,
  String? Function(String?)? validator,
  VoidCallback? onChanged,
}) {
  final parsed = int.tryParse(controller.text.trim());
  final selectedValue =
      parsed != null && _breakDurationOptions.contains(parsed) ? parsed : null;
  return DropdownButtonFormField<int?> (
    value: selectedValue,
    items: _buildBreakDropdownMenuItems(),
    onChanged: enabled
        ? (value) {
            final text = value?.toString() ?? '';
            controller
              ..text = text
              ..selection = TextSelection.collapsed(offset: text.length);
            onChanged?.call();
          }
        : null,
    validator: validator == null ? null : (value) => validator(value?.toString()),
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFF59E0B)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dropdownColor: Colors.white,
  );
}

class WorkDetailScreen extends StatefulWidget {
  const WorkDetailScreen({super.key, required this.work});

  final Work work;

  @override
  State<WorkDetailScreen> createState() => _WorkDetailScreenState();
}

class _WorkDetailScreenState extends State<WorkDetailScreen> {
  final DashboardRepository _dashboardRepository = DashboardRepository();
  final AttendanceEntryRepository _attendanceRepository =
      AttendanceEntryRepository();
  final ContractTypeRepository _contractTypeRepository =
      ContractTypeRepository();
  final GlobalKey<FormState> _attendanceFormKey = GlobalKey<FormState>();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _breakMinutesController =
      TextEditingController(text: '0');
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _ratePerUnitController = TextEditingController();

  List<ContractType> _contractTypes = const <ContractType>[];
  bool _isLoadingContractTypes = false;
  String? _contractTypesError;
  String? _selectedContractTypeId;
  bool _contractFieldsEnabled = false;
  bool _markAsWorkOff = false;
  String? _previousStartTime;
  String? _previousEndTime;
  String? _previousBreakMinutes;

  DashboardSummary? _dashboardSummary;
  bool _isSummaryLoading = true;
  String? _summaryError;
  bool _isSubmittingAttendance = false;
  String? _attendanceStatusMessage;
  bool _attendanceStatusIsError = false;
  DateTime _selectedDate = DateTime.now();
  String? _dateLabelOverride;
  List<DateTime> _pendingMissedDates = const <DateTime>[];
  bool _missedDialogShown = false;
  bool _isCompletingMissedAttendance = false;

  @override
  void initState() {
    super.initState();
    _initializeAttendanceControllers();
    if (widget.work.isContract) {
      final initialContractTypeId = _extractContractTypeIdFromAdditionalData();
      if (initialContractTypeId != null) {
        _selectedContractTypeId = initialContractTypeId.toString();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.work.isContract) {
        _loadContractTypes();
      }
      _loadSummary();
    });
  }

  String _normalizeTimeString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final match = RegExp(r'(\d{1,2}):(\d{1,2})').firstMatch(trimmed);
    if (match != null) {
      final hour = match.group(1)!;
      final minute = match.group(2)!;
      return '${hour.padLeft(2, '0')}:${minute.padLeft(2, '0')}';
    }

    return trimmed;
  }

  String? _extractTimeFromMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return _normalizeTimeString(value);
      }
    }
    return null;
  }

  int? _extractBreakMinutes(Map<String, dynamic> data, String? fallbackText) {
    const keys = ['break_minutes', 'breakMinutes', 'break_time', 'breakTime'];
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final parsed = _parseMinutesFromText(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    if (fallbackText != null) {
      return _parseMinutesFromText(fallbackText);
    }
    return null;
  }

  int? _parseMinutesFromText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        final hours = int.tryParse(parts[0]);
        final minutes = int.tryParse(parts[1]);
        if (hours != null && minutes != null) {
          return (hours * 60) + minutes;
        }
      }
    }

    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(trimmed);
    final minuteMatch = RegExp(r'(\d+)\s*m').firstMatch(trimmed);
    var totalMinutes = 0;
    var matched = false;
    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
      matched = true;
    }
    if (minuteMatch != null) {
      totalMinutes += int.parse(minuteMatch.group(1)!);
      matched = true;
    }
    if (matched) {
      return totalMinutes;
    }

    final digitsOnly = RegExp(r'^-?\d+$');
    if (digitsOnly.hasMatch(trimmed)) {
      return int.tryParse(trimmed);
    }

    final firstNumber = RegExp(r'(\d+)').firstMatch(trimmed);
    if (firstNumber != null) {
      return int.tryParse(firstNumber.group(1)!);
    }

    return null;
  }

  bool _shouldMarkWorkOffFromValues({
    required String startTime,
    required String endTime,
    required String breakMinutes,
  }) {
    final startMinutes = _parseMinutesFromText(startTime) ?? -1;
    final endMinutes = _parseMinutesFromText(endTime) ?? -1;
    final normalizedBreak = breakMinutes.trim();
    final breakValue = normalizedBreak.isEmpty
        ? 0
        : int.tryParse(normalizedBreak) ?? -1;

    final isStartZero = startMinutes == 0;
    final isEndZero = endMinutes == 0;
    final isBreakZero = breakValue <= 0;

    return isStartZero && isEndZero && isBreakZero;
  }

  void _setControllerValue(TextEditingController controller, String value) {
    controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
  }

  DateTime? _extractDateFromMap(Map<String, dynamic> data, List<String> keys) {
    final value = _findPreviewValue(data, keys);
    return _parseDateInput(value);
  }

  DateTime? _parseDateInput(dynamic value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is String) {
      final parsed = _parseDateText(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  void _initializeAttendanceControllers() {
    _selectedDate = DateTime.now();
    _dateLabelOverride = null;

    final additionalData = widget.work.additionalData;
    final initialDate = _extractDateFromMap(additionalData, const [
      'date',
      'entry_date',
      'attendance_date',
      'attendanceDate',
      'filter_date',
      'filterDate',
      'selected_date',
      'selectedDate',
    ]);
    if (initialDate != null) {
      _selectedDate = initialDate;
      _dateLabelOverride = _formatDate(initialDate);
    }

    final startTime =
        _extractTimeFromMap(additionalData, const ['start_time', 'startTime', 'in_time']);
    if (startTime != null) {
      _startTimeController.text = startTime;
    }

    final endTime =
        _extractTimeFromMap(additionalData, const ['end_time', 'endTime', 'out_time']);
    if (endTime != null) {
      _endTimeController.text = endTime;
    }

    final breakMinutes =
        _extractBreakMinutes(additionalData, additionalData['breakTime']?.toString());
    if (breakMinutes != null) {
      _breakMinutesController.text = breakMinutes.toString();
    } else if (_breakMinutesController.text.trim().isEmpty) {
      _breakMinutesController.text = '0';
    }

    final unitsText = _extractNumericText(additionalData, const [
      'units',
      'unit_count',
      'unitCount',
      'unitsCompleted',
    ]);
    if (unitsText != null) {
      _unitsController.text = unitsText;
    }

    final rateText = _extractNumericText(additionalData, const [
      'rate_per_unit',
      'ratePerUnit',
      'unit_rate',
      'unitRate',
      'rate',
    ]);
    if (rateText != null) {
      _ratePerUnitController.text = rateText;
    }

    _syncContractFieldsVisibility();
    _markAsWorkOff = _shouldMarkWorkOffFromValues(
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
      breakMinutes: _breakMinutesController.text,
    );
    if (_markAsWorkOff) {
      _contractFieldsEnabled = false;
    }
  }

  void _syncContractFieldsVisibility({bool notify = false}) {
    if (!widget.work.isContract) {
      if (_contractFieldsEnabled) {
        if (notify) {
          setState(() {
            _contractFieldsEnabled = false;
          });
        } else {
          _contractFieldsEnabled = false;
        }
      }
      return;
    }

    final hasData = _unitsController.text.trim().isNotEmpty;
    if (!hasData || _contractFieldsEnabled) {
      return;
    }
    if (notify) {
      setState(() {
        _contractFieldsEnabled = true;
      });
    } else {
      _contractFieldsEnabled = true;
    }
  }

  void _applyAttendanceDetailsFromSummary(DashboardAttendanceEntry? entry) {
    if (entry == null) {
      return;
    }

    final startTime = _extractTimeFromMap(
          entry.raw,
          const ['start_time', 'startTime', 'in_time'],
        ) ??
        entry.startTimeText;
    if (startTime != null && startTime.trim().isNotEmpty) {
      _startTimeController.text = _normalizeTimeString(startTime);
    }

    final endTime = _extractTimeFromMap(
          entry.raw,
          const ['end_time', 'endTime', 'out_time'],
        ) ??
        entry.endTimeText;
    if (endTime != null && endTime.trim().isNotEmpty) {
      _endTimeController.text = _normalizeTimeString(endTime);
    }

    final breakMinutes =
        _extractBreakMinutes(entry.raw, entry.breakDurationText ?? entry.raw['breakTime']?.toString());
    if (breakMinutes != null) {
      _breakMinutesController.text = breakMinutes.toString();
    }

    final unitsText = _extractNumericText(entry.raw, const [
      'units',
      'unit_count',
      'unitCount',
      'unitsCompleted',
    ]);
    if (unitsText != null && unitsText.trim().isNotEmpty) {
      _unitsController.text = unitsText.trim();
    }

    final rateText = _extractNumericText(entry.raw, const [
      'rate_per_unit',
      'ratePerUnit',
      'unit_rate',
      'unitRate',
      'rate',
    ]);
    if (rateText != null && rateText.trim().isNotEmpty) {
      _ratePerUnitController.text = rateText.trim();
    }

    final dateText = entry.dateText?.trim();
    if (dateText != null && dateText.isNotEmpty) {
      final parsedDate = _parseDateText(dateText);
      if (parsedDate != null) {
        final normalized = _normalizeDateOnly(parsedDate);
        if (mounted) {
          setState(() {
            _selectedDate = normalized;
            _dateLabelOverride = _formatDate(normalized);
          });
        } else {
          _selectedDate = normalized;
          _dateLabelOverride = _formatDate(normalized);
        }
      } else if (mounted) {
        setState(() {
          _dateLabelOverride = _normalizeDateLabel(dateText);
        });
      } else {
        _dateLabelOverride = _normalizeDateLabel(dateText);
      }
    }

    _syncContractFieldsVisibility(notify: true);

    final shouldWorkOff = _shouldMarkWorkOffFromValues(
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
      breakMinutes: _breakMinutesController.text,
    );
    if (shouldWorkOff != _markAsWorkOff) {
      if (mounted) {
        setState(() {
          _markAsWorkOff = shouldWorkOff;
        });
      } else {
        _markAsWorkOff = shouldWorkOff;
      }
    }
  }

  Future<void> _refreshMissedAttendance({bool showDialog = false}) async {
    if (!mounted) {
      return;
    }
    final l = AppLocalizations.of(context);
    try {
      final dates = await _attendanceRepository
          .fetchMissedAttendanceDates(workId: widget.work.id);
      if (!mounted) {
        return;
      }
      final normalized = dates
          .map(_normalizeDateOnly)
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));
      setState(() {
        _pendingMissedDates = normalized;
        if (_pendingMissedDates.isEmpty) {
          _missedDialogShown = false;
        }
      });
      if (showDialog && _pendingMissedDates.isNotEmpty && !_missedDialogShown) {
        _missedDialogShown = true;
        await _showMissedAttendanceDialog(
          dates: _pendingMissedDates,
          focusDate: _pendingMissedDates.first,
        );
      }
    } on AttendanceAuthException {
      if (!mounted) {
        return;
      }
      final message = l.authenticationRequiredMessage;
      setState(() {
        _pendingMissedDates = const <DateTime>[];
        _missedDialogShown = false;
      });
      if (showDialog) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on AttendanceRepositoryException catch (e) {
      if (!mounted) {
        return;
      }
      final message = e.message.trim().isNotEmpty
          ? e.message.trim()
          : l.attendanceMissedEntriesLoadFailed;
      if (showDialog) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (showDialog) {
        final message = l.attendanceMissedEntriesLoadFailed;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<bool> _ensureNoBlockingMissedEntries() async {
    final l = AppLocalizations.of(context);
    try {
      final dates = await _attendanceRepository
          .fetchMissedAttendanceDates(workId: widget.work.id);
      if (!mounted) {
        return false;
      }
      final normalized = dates
          .map(_normalizeDateOnly)
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));
      setState(() {
        _pendingMissedDates = normalized;
        if (_pendingMissedDates.isEmpty) {
          _missedDialogShown = false;
        }
      });
      if (_pendingMissedDates.isEmpty) {
        return true;
      }
      final selectedDate = _normalizeDateOnly(_selectedDate);
      final earliestPending = _pendingMissedDates.first;
      if (selectedDate.isAfter(earliestPending)) {
        _missedDialogShown = true;
        await _showMissedAttendanceDialog(
          dates: _pendingMissedDates,
          focusDate: earliestPending,
        );
        return false;
      }
      return true;
    } on AttendanceAuthException {
      if (!mounted) {
        return false;
      }
      final message = l.authenticationRequiredMessage;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return false;
    } on AttendanceRepositoryException catch (e) {
      if (!mounted) {
        return false;
      }
      final message = e.message.trim().isNotEmpty
          ? e.message.trim()
          : l.attendanceMissedEntriesLoadFailed;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      final message = l.attendanceMissedEntriesLoadFailed;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return false;
    }
  }

  Future<void> _showMissedAttendanceDialog({
    required List<DateTime> dates,
    required DateTime focusDate,
  }) async {
    if (!mounted || dates.isEmpty) {
      return;
    }
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final focusLabel = _formatDate(focusDate);
    final labels = dates.map(_formatDate).toList(growable: false);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.attendanceMissedEntriesTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.attendanceMissedEntriesDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.attendanceMissedEntriesListLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: labels.map((label) {
                    final isHighlighted = label == focusLabel;
                    return Chip(
                      label: Text(label),
                      backgroundColor: isHighlighted
                          ? const Color(0xFFFFEDD5)
                          : const Color(0xFFF1F5F9),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isHighlighted ? FontWeight.w700 : FontWeight.w500,
                        color: isHighlighted
                            ? const Color(0xFF9A3412)
                            : const Color(0xFF475569),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  _openMissedAttendanceCompletion();
                }
              },
              child: Text(l.attendanceMissedEntriesResolveButton),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _jumpToDate(focusDate);
              },
              child: Text(l.attendanceMissedEntriesReviewButton(focusLabel)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }

  void _handlePendingAttendanceReview() {
    if (_pendingMissedDates.isEmpty) {
      return;
    }
    _openMissedAttendanceCompletion();
  }

  Future<void> _openMissedAttendanceCompletion() async {
    if (_pendingMissedDates.isEmpty || _isCompletingMissedAttendance) {
      return;
    }
    if (!mounted) {
      return;
    }

    final l = AppLocalizations.of(context);
    final contractTypeId = _resolveContractTypeId();
    _isCompletingMissedAttendance = true;

    final response = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _MissedAttendanceCompletionSheet(
          dates: _pendingMissedDates.toList(growable: false),
          workId: widget.work.id,
          workName: widget.work.name,
          localization: l,
          dateFormatter: _formatDate,
          contractTypeId: contractTypeId,
          onSubmit: (entries) => _attendanceRepository.completeMissedAttendance(
            entries: entries,
          ),
        );
      },
    );

    if (!mounted) {
      _isCompletingMissedAttendance = false;
      return;
    }

    _isCompletingMissedAttendance = false;

    if (response != null) {
      final message =
          _extractResponseMessage(response) ?? l.attendanceMissedEntriesCompleteSuccess;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _loadSummary();
    }
  }

  void _jumpToDate(DateTime date) {
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
    final normalized = _normalizeDateOnly(date);
    setState(() {
      _selectedDate = normalized;
      _dateLabelOverride = _formatDate(normalized);
    });
    _handleAttendanceFieldChanged();
  }

  Future<void> _handleDateTap() async {
    FocusScope.of(context).unfocus();
    final normalizedPendingDates = _pendingMissedDates
        .map(_normalizeDateOnly)
        .toSet()
        .toList(growable: false)
      ..sort((a, b) => a.compareTo(b));
    if (normalizedPendingDates.isEmpty) {
      return;
    }

    final allowedDates = normalizedPendingDates.toSet();
    final normalizedSelected = _normalizeDateOnly(_selectedDate);
    final initialDate =
        allowedDates.contains(normalizedSelected)
            ? normalizedSelected
            : normalizedPendingDates.first;
    final firstDate = normalizedPendingDates.first;
    final lastDate = normalizedPendingDates.last;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) {
        return allowedDates.contains(_normalizeDateOnly(date));
      },
    );
    if (pickedDate == null) {
      return;
    }

    final normalizedDate =
        DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
    setState(() {
      _selectedDate = normalizedDate;
      _dateLabelOverride = _formatDate(normalizedDate);
    });
    _handleAttendanceFieldChanged();
  }

  void _handleAttendanceFieldChanged() {
    if (_attendanceStatusMessage != null) {
      setState(() {
        _attendanceStatusMessage = null;
        _attendanceStatusIsError = false;
      });
    }
  }

  void _handleContractFieldsToggle(bool value) {
    if (!widget.work.isContract || (_markAsWorkOff && value)) {
      return;
    }
    if (value && _contractTypes.isEmpty && !_isLoadingContractTypes) {
      _loadContractTypes();
    }
    setState(() {
      _contractFieldsEnabled = value;
      if (value) {
        if (_contractTypes.isNotEmpty) {
          _resolveSelectedContractTypeIdAfterLoad();
        }
      } else {
        _unitsController.clear();
      }
    });
    _handleAttendanceFieldChanged();
  }

  void _handleContractTypeChanged(String? value) {
    if (!widget.work.isContract) {
      return;
    }
    if (_selectedContractTypeId == value) {
      return;
    }
    setState(() {
      _selectedContractTypeId = value;
    });
    _handleAttendanceFieldChanged();
  }

  void _handleWorkOffToggle(bool value) {
    if (_markAsWorkOff == value) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      if (value) {
        _previousStartTime = _startTimeController.text;
        _previousEndTime = _endTimeController.text;
        _previousBreakMinutes = _breakMinutesController.text;
        _markAsWorkOff = true;
        _contractFieldsEnabled = false;
        _setControllerValue(_startTimeController, '00:00');
        _setControllerValue(_endTimeController, '00:00');
        _setControllerValue(_breakMinutesController, '0');
      } else {
        _markAsWorkOff = false;
        final restoredStart =
            _previousStartTime?.trim().isNotEmpty == true ? _previousStartTime! : '';
        final restoredEnd =
            _previousEndTime?.trim().isNotEmpty == true ? _previousEndTime! : '';
        final restoredBreak = _previousBreakMinutes?.trim().isNotEmpty == true
            ? _previousBreakMinutes!
            : '0';
        _setControllerValue(_startTimeController, restoredStart);
        _setControllerValue(_endTimeController, restoredEnd);
        _setControllerValue(_breakMinutesController, restoredBreak);
        _previousStartTime = null;
        _previousEndTime = null;
        _previousBreakMinutes = null;
      }
    });
    _handleAttendanceFieldChanged();
  }

  Future<void> _openContractWorkManager() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ContractWorkScreen(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (widget.work.isContract) {
      await _loadContractTypes();
    }
  }

  String? _validateStartTime(String? value) {
    if (_markAsWorkOff) {
      return null;
    }
    final l = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l.attendanceStartTimeRequired;
    }
    if (!_isValidTimeFormat(value.trim())) {
      return l.attendanceInvalidTimeFormat;
    }
    return null;
  }

  String? _validateEndTime(String? value) {
    if (_markAsWorkOff) {
      return null;
    }
    final l = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l.attendanceEndTimeRequired;
    }
    if (!_isValidTimeFormat(value.trim())) {
      return l.attendanceInvalidTimeFormat;
    }
    return null;
  }

  String? _validateBreakMinutes(String? value) {
    if (_markAsWorkOff) {
      return null;
    }
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      return AppLocalizations.of(context).attendanceBreakInvalid;
    }
    return null;
  }

  String? _validateUnits(String? value) {
    if (!widget.work.isContract || !_contractFieldsEnabled) {
      return null;
    }
    final trimmed = value?.trim() ?? '';
    final l = AppLocalizations.of(context);
    if (trimmed.isEmpty) {
      return l.attendanceUnitsRequired;
    }
    final parsed = _parseNumberInput(trimmed);
    if (parsed == null || parsed <= 0) {
      return l.attendanceUnitsInvalid;
    }
    return null;
  }

  String? _validateRatePerUnit(String? value) {
    if (!widget.work.isContract || !_contractFieldsEnabled) {
      return null;
    }
    final trimmed = value?.trim() ?? '';
    final l = AppLocalizations.of(context);
    if (trimmed.isEmpty) {
      return l.attendanceRateRequired;
    }
    final parsed = _parseNumberInput(trimmed);
    if (parsed == null || parsed <= 0) {
      return l.attendanceRateInvalid;
    }
    return null;
  }

  bool _isValidTimeFormat(String value) {
    final normalized = value.trim();
    final parts = normalized.split(':');
    if (parts.length != 2) {
      return false;
    }
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) {
      return false;
    }
    return hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59;
  }

  int _resolveBreakMinutes(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    return int.tryParse(trimmed) ?? 0;
  }

  String? _extractNumericText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }
      if (value is num) {
        return value.toString();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _extractResponseMessage(Map<String, dynamic>? response) {
    if (response == null) {
      return null;
    }
    const keys = ['message', 'detail', 'status'];
    for (final key in keys) {
      final value = response[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  num? _parseNumberInput(String value) {
    final sanitized = value.replaceAll(',', '.').trim();
    if (sanitized.isEmpty) {
      return null;
    }
    final intValue = int.tryParse(sanitized);
    if (intValue != null) {
      return intValue;
    }
    return double.tryParse(sanitized);
  }

  int? _resolveContractTypeId() {
    if (_selectedContractTypeId != null) {
      final parsed = int.tryParse(_selectedContractTypeId!);
      if (parsed != null) {
        return parsed;
      }
    }
    return _extractContractTypeIdFromAdditionalData();
  }

  int? _extractContractTypeIdFromAdditionalData() {
    final data = widget.work.additionalData;
    const keys = ['contract_type_id', 'contractTypeId', 'contract_type', 'contractType'];
    for (final key in keys) {
      final value = data[key];
      final resolved = _tryParseContractTypeId(value);
      if (resolved != null) {
        return resolved;
      }
    }
    return null;
  }

  int? _tryParseContractTypeId(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final parsed = int.tryParse(trimmed);
      return parsed;
    }
    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();
      const candidateKeys = <String>[
        'id',
        'contract_type_id',
        'contractTypeId',
        'contract_type',
        'contractType',
        'value',
      ];
      for (final key in candidateKeys) {
        if (!map.containsKey(key)) {
          continue;
        }
        final resolved = _tryParseContractTypeId(map[key]);
        if (resolved != null) {
          return resolved;
        }
      }
      for (final entry in map.entries) {
        final resolved = _tryParseContractTypeId(entry.value);
        if (resolved != null) {
          return resolved;
        }
      }
    }
    return null;
  }

  Future<void> _submitWorkOffAttendance() async {
    final wasWorkOff = _markAsWorkOff;
    if (!wasWorkOff) {
      _handleWorkOffToggle(true);
    }
    try {
      await _submitAttendance();
    } finally {
      if (!wasWorkOff && mounted) {
        _handleWorkOffToggle(false);
      }
    }
  }

  Future<void> _submitAttendance() async {
    FocusScope.of(context).unfocus();
    final formState = _attendanceFormKey.currentState;
    if (formState == null) {
      return;
    }
    if (!formState.validate()) {
      return;
    }

    final l = AppLocalizations.of(context);
    final isWorkOff = _markAsWorkOff;

    final canSubmit = await _ensureNoBlockingMissedEntries();
    if (!mounted || !canSubmit) {
      return;
    }

    if (isWorkOff) {
      setState(() {
        _isSubmittingAttendance = true;
        _attendanceStatusMessage = null;
        _attendanceStatusIsError = false;
      });

      try {
        final response = await _attendanceRepository.submitAttendance(
          workId: widget.work.id,
          date: _selectedDate,
          isLeave: true,
        );
        if (!mounted) {
          return;
        }
        final message =
            _extractResponseMessage(response) ?? l.attendanceSubmitSuccess;
        setState(() {
          _attendanceStatusMessage = message;
          _attendanceStatusIsError = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        await _loadSummary();
        await _refreshMissedAttendance(showDialog: false);
      } on AttendanceAuthException {
        if (!mounted) {
          return;
        }
        final message = l.authenticationRequiredMessage;
        setState(() {
          _attendanceStatusMessage = message;
          _attendanceStatusIsError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } on AttendanceRepositoryException catch (e) {
        if (!mounted) {
          return;
        }
        final message = e.message.trim().isNotEmpty
            ? e.message.trim()
            : l.attendanceSubmitFailed;
        setState(() {
          _attendanceStatusMessage = message;
          _attendanceStatusIsError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        final message = l.attendanceSubmitFailed;
        setState(() {
          _attendanceStatusMessage = message;
          _attendanceStatusIsError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmittingAttendance = false;
          });
        }
      }
      return;
    }

    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();
    final breakMinutes = _resolveBreakMinutes(_breakMinutesController.text);
    final bool isContractEntryEnabled =
        widget.work.isContract && _contractFieldsEnabled;
    final bool? contractEntryPayloadValue = isContractEntryEnabled;
    if (isContractEntryEnabled && _contractTypes.isEmpty) {
      final message = l.contractWorkLoadError;
      setState(() {
        _attendanceStatusMessage = message;
        _attendanceStatusIsError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    num? units;
    int? contractTypeId;
    double? ratePerUnit;
    if (isContractEntryEnabled) {
      units = _parseNumberInput(_unitsController.text);
      contractTypeId = _resolveContractTypeId();
      if (contractTypeId == null) {
        final message = l.contractWorkLoadError;
        setState(() {
          _attendanceStatusMessage = message;
          _attendanceStatusIsError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      final selectedContractTypeId =
          _selectedContractTypeId ?? contractTypeId.toString();
      ContractType? selectedContractType;
      if (selectedContractTypeId.isNotEmpty) {
        try {
          selectedContractType = _contractTypes.firstWhere(
            (type) => type.id == selectedContractTypeId,
          );
        } catch (_) {
          selectedContractType = null;
        }
      }
      selectedContractType ??=
          _contractTypes.isNotEmpty ? _contractTypes.first : null;
      ratePerUnit = selectedContractType?.rate;
    }

    setState(() {
      _isSubmittingAttendance = true;
      _attendanceStatusMessage = null;
      _attendanceStatusIsError = false;
    });

    var previewFetched = false;

    try {
      final previewResponse = await _attendanceRepository.previewAttendance(
        workId: widget.work.id,
        date: _selectedDate,
        isLeave: false,
        startTime: startTime,
        endTime: endTime,
        breakMinutes: breakMinutes,
        isContractEntry: contractEntryPayloadValue,
        contractTypeId: contractTypeId,
        units: units,
        ratePerUnit: ratePerUnit,
      );

      previewFetched = true;

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmittingAttendance = false;
      });

      final confirmed = await _showAttendancePreviewDialog(
        previewResponse: previewResponse,
        date: _selectedDate,
        startTime: startTime,
        endTime: endTime,
        breakMinutes: breakMinutes,
        isContractEntry: isContractEntryEnabled,
        units: units,
        ratePerUnit: ratePerUnit,
      );

      if (!mounted) {
        return;
      }

      if (!confirmed) {
        return;
      }

      setState(() {
        _isSubmittingAttendance = true;
        _attendanceStatusMessage = null;
        _attendanceStatusIsError = false;
      });

      final response = await _attendanceRepository.submitAttendance(
        workId: widget.work.id,
        date: _selectedDate,
        isLeave: false,
        startTime: startTime,
        endTime: endTime,
        breakMinutes: breakMinutes,
        isContractEntry: contractEntryPayloadValue,
        contractTypeId: contractTypeId,
        units: units,
        ratePerUnit: ratePerUnit,
      );
      if (!mounted) {
        return;
      }
      final message =
          _extractResponseMessage(response) ?? l.attendanceSubmitSuccess;
      setState(() {
        _attendanceStatusMessage = message;
        _attendanceStatusIsError = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _loadSummary();
      await _refreshMissedAttendance(showDialog: false);
    } on AttendanceAuthException {
      if (!mounted) {
        return;
      }
      final message = l.authenticationRequiredMessage;
      setState(() {
        _attendanceStatusMessage = message;
        _attendanceStatusIsError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on AttendanceRepositoryException catch (e) {
      if (!mounted) {
        return;
      }
      final fallback = previewFetched
          ? l.attendanceSubmitFailed
          : l.attendancePreviewFetchFailed;
      final message = e.message.trim().isNotEmpty
          ? e.message.trim()
          : fallback;
      setState(() {
        _attendanceStatusMessage = message;
        _attendanceStatusIsError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      final message = previewFetched
          ? l.attendanceSubmitFailed
          : l.attendancePreviewFetchFailed;
      setState(() {
        _attendanceStatusMessage = message;
        _attendanceStatusIsError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAttendance = false;
        });
      }
    }
  }

  Future<bool> _showAttendancePreviewDialog({
    required Map<String, dynamic>? previewResponse,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int breakMinutes,
    required bool isContractEntry,
    num? units,
    num? ratePerUnit,
  }) async {
    final l = AppLocalizations.of(context);
    final previewData = _extractPreviewData(previewResponse);
    final responseMessage = _extractResponseMessage(previewResponse);
    final description = (responseMessage != null && responseMessage.trim().isNotEmpty)
        ? responseMessage.trim()
        : l.attendancePreviewDescription;

    final infoEntries = <_PreviewInfoEntry>[];
    _addPreviewEntry(infoEntries, l.attendanceDateLabel, _formatDate(date));
    _addPreviewEntry(
      infoEntries,
      l.attendanceEntryTypeLabel,
      isContractEntry ? l.contractWorkLabel : l.hourlyWorkLabel,
    );
    _addPreviewEntry(infoEntries, l.startTimeLabel, startTime);
    _addPreviewEntry(infoEntries, l.endTimeLabel, endTime);
    _addPreviewEntry(
      infoEntries,
      l.breakLabel,
      _formatBreakMinutesDisplay(breakMinutes),
    );

    if (isContractEntry) {
      final unitsDisplay = units != null
          ? _formatNumericValue(units)
          : _resolvePreviewDisplayValue(previewData, const [
              'units',
              'unit_count',
              'unitsCompleted',
              'units_count',
            ]);
      _addPreviewEntry(infoEntries, l.contractWorkUnitsLabel, unitsDisplay);

      final rateDisplay = ratePerUnit != null
          ? _formatNumericValue(ratePerUnit)
          : _resolvePreviewDisplayValue(previewData, const [
              'rate_per_unit',
              'ratePerUnit',
              'unit_rate',
              'unitRate',
            ]);
      _addPreviewEntry(infoEntries, l.contractWorkRateLabel, rateDisplay);
    }

    final hoursDisplay = _resolvePreviewDisplayValue(previewData, const [
      'total_hours',
      'totalHours',
      'hours',
      'calculated_hours',
      'calculatedHours',
      'total_duration',
      'totalDuration',
    ]);
    final salaryDisplay = _resolvePreviewDisplayValue(previewData, const [
      'total_salary',
      'totalSalary',
      'salary',
      'amount',
      'payable_amount',
      'payableAmount',
      'total_amount',
      'totalAmount',
    ]);

    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return _AttendancePreviewSheet(
              title: l.attendancePreviewTitle,
              description: description,
              validationMessage: l.attendancePreviewValidationPrompt,
              cancelLabel: l.attendancePreviewCancelButton,
              confirmLabel: l.attendancePreviewConfirmButton,
              hoursLabel: l.attendancePreviewHoursLabel,
              hoursValue: hoursDisplay ?? '--',
              salaryLabel: l.attendancePreviewSalaryLabel,
              salaryValue: salaryDisplay,
              entries: infoEntries,
              onEdit: () => Navigator.of(sheetContext).pop(false),
              onConfirm: () => Navigator.of(sheetContext).pop(true),
            );
          },
        ) ??
        false;
  }

  void _addPreviewEntry(
    List<_PreviewInfoEntry> entries,
    String label,
    String? value,
  ) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }
    entries.add(_PreviewInfoEntry(label: label, value: trimmed));
  }

  Map<String, dynamic>? _extractPreviewData(Map<String, dynamic>? response) {
    if (response == null) {
      return null;
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return response;
  }

  String? _resolvePreviewDisplayValue(
    Map<String, dynamic>? data,
    List<String> keys,
  ) {
    final value = _findPreviewValue(data, keys);
    return _stringifyPreviewValue(value);
  }

  dynamic _findPreviewValue(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) {
      return null;
    }

    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value != null) {
          return value;
        }
      }
    }

    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        final nested = _findPreviewValue(value, keys);
        if (nested != null) {
          return nested;
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final nested = _findPreviewValue(item, keys);
            if (nested != null) {
              return nested;
            }
          }
        }
      }
    }

    return null;
  }

  String? _stringifyPreviewValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return _formatNumericValue(value);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }
    return null;
  }

  String _formatNumericValue(num value) {
    final doubleValue = value.toDouble();
    if (doubleValue == doubleValue.roundToDouble()) {
      return doubleValue.toStringAsFixed(0);
    }
    return doubleValue.toStringAsFixed(2);
  }

  String _formatBreakMinutesDisplay(int minutes) {
    if (minutes <= 0) {
      return AppString.zeroMinutesLabel;
    }
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    final parts = <String>[];
    if (hours > 0) {
      parts.add('${hours}${AppString.hourAbbreviation}');
    }
    if (remaining > 0) {
      parts.add(hours > 0
          ? '${remaining}${AppString.minuteAbbreviation}'
          : '$remaining ${AppString.minutesSuffix}');
    }
    if (parts.isEmpty) {
      parts.add('$minutes ${AppString.minutesSuffix}');
    }
    return parts.join(' ');
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _breakMinutesController.dispose();
    _unitsController.dispose();
    _ratePerUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _isSummaryLoading = true;
      _summaryError = null;
    });

    try {
      final summary = await _dashboardRepository.fetchSummary(workId: widget.work.id);
      if (!mounted) return;
      setState(() {
        _dashboardSummary = summary;
        _isSummaryLoading = false;
      });
      _applyAttendanceDetailsFromSummary(summary.todayEntry);
      await _refreshMissedAttendance(showDialog: true);
    } on DashboardAuthException {
      if (!mounted) return;
      final message = l.authenticationRequiredMessage;
      setState(() {
        _summaryError = message;
        _isSummaryLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on DashboardRepositoryException catch (e) {
      if (!mounted) return;
      final message = e.message.trim().isNotEmpty
          ? e.message.trim()
          : l.dashboardSummaryLoadFailedMessage;
      setState(() {
        _summaryError = message;
        _isSummaryLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      final message = l.dashboardSummaryLoadFailedMessage;
      setState(() {
        _summaryError = message;
        _isSummaryLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _loadContractTypes() async {
    if (!widget.work.isContract || _isLoadingContractTypes) {
      return;
    }

    setState(() {
      _isLoadingContractTypes = true;
      _contractTypesError = null;
    });

    try {
      final collection = await _contractTypeRepository.fetchContractTypes();
      if (!mounted) {
        return;
      }
      final merged = _mergeContractTypes(collection);
      setState(() {
        _contractTypes = merged;
        _isLoadingContractTypes = false;
        _contractTypesError = null;
        _resolveSelectedContractTypeIdAfterLoad();
      });
    } on ContractTypeRepositoryException catch (e) {
      if (!mounted) {
        return;
      }
      final l = AppLocalizations.of(context);
      final message =
          e.message.trim().isNotEmpty ? e.message.trim() : l.contractWorkLoadError;
      setState(() {
        _isLoadingContractTypes = false;
        _contractTypesError = message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l = AppLocalizations.of(context);
      setState(() {
        _isLoadingContractTypes = false;
        _contractTypesError = l.contractWorkLoadError;
      });
    }
  }

  List<ContractType> _mergeContractTypes(ContractTypeCollection collection) {
    final merged = <ContractType>[];
    final seen = <String>{};

    void addTypes(List<ContractType> types) {
      for (final type in types) {
        if (seen.add(type.id)) {
          merged.add(type);
        }
      }
    }

    addTypes(collection.userTypes);
    addTypes(collection.globalTypes);
    return merged;
  }

  void _resolveSelectedContractTypeIdAfterLoad() {
    if (_contractTypes.isEmpty) {
      _selectedContractTypeId = null;
      return;
    }

    final currentId = _selectedContractTypeId;
    if (currentId != null &&
        _contractTypes.any((type) => type.id == currentId)) {
      return;
    }

    final initialFromData = _extractContractTypeIdFromAdditionalData();
    if (initialFromData != null) {
      final initialId = initialFromData.toString();
      final hasMatch =
          _contractTypes.any((type) => type.id == initialId);
      if (hasMatch) {
        _selectedContractTypeId = initialId;
        return;
      }
    }

    _selectedContractTypeId = _contractTypes.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hourlyRateText = _buildHourlyRateText(l);
    final workTypeLabel = _resolveWorkTypeLabel(l);
    final normalizedRate = hourlyRateText.trim();
    final normalizedWorkType = workTypeLabel.trim();
    final normalizedNotAvailable = l.notAvailableLabel.trim();
    final hideRateDescription = normalizedRate.isEmpty ||
        normalizedRate.toLowerCase() == normalizedNotAvailable.toLowerCase() ||
        normalizedRate.toLowerCase() == normalizedWorkType.toLowerCase();
    final rateDescription = hideRateDescription ? null : normalizedRate;
    final contractItems = _resolveContractItems();
    final summaryStats = _buildSummaryStats(l);
    final todayEntry = _dashboardSummary?.todayEntry;
    final dateLabel = (_dateLabelOverride?.isNotEmpty ?? false)
        ? _normalizeDateLabel(_dateLabelOverride!)
        : (todayEntry?.dateText?.trim().isNotEmpty == true
            ? _normalizeDateLabel(todayEntry!.dateText!.trim())
            : _formatDate(_selectedDate));
    final summarySection = _buildSummarySection(l, summaryStats);
    final hasSummaryContent =
        _isSummaryLoading || _summaryError != null || summaryStats.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Text(
          l.appTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A0A0A),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_alt_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(l.changeWorkButton),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WorkHeaderCard(
                work: widget.work,
                workTypeLabel: workTypeLabel,
                rateDescription: rateDescription,
              ),
              const SizedBox(height: 24),
              if (_pendingMissedDates.isNotEmpty) ...[
                _PendingAttendanceCard(
                  title: l.attendanceMissedEntriesTitle,
                  description: l.attendanceMissedEntriesDescription,
                  dateLabels: _pendingMissedDates
                      .map(_formatDate)
                      .toList(growable: false),
                  highlightedLabel: _formatDate(_pendingMissedDates.first),
                  buttonLabel: l.attendanceMissedEntriesReviewButton(
                    _formatDate(_pendingMissedDates.first),
                  ),
                  onReview: _handlePendingAttendanceReview,
                ),
                const SizedBox(height: 24),
              ],
              _AttendanceSection(
                dateLabel: dateLabel,
                onDateTap: _handleDateTap,
                dateSelectionEnabled: _pendingMissedDates.isNotEmpty,
                formKey: _attendanceFormKey,
                startTimeController: _startTimeController,
                endTimeController: _endTimeController,
                breakMinutesController: _breakMinutesController,
                onSubmit: _submitAttendance,
                onWorkOffSubmit: _submitWorkOffAttendance,
                onFieldChanged: _handleAttendanceFieldChanged,
                isSubmitting: _isSubmittingAttendance,
                isWorkOff: _markAsWorkOff,
                showContractWorkButton: widget.work.isContract,
                onContractWorkTap:
                    widget.work.isContract ? _openContractWorkManager : null,
                showContractFields: widget.work.isContract,
                contractFieldsEnabled: _contractFieldsEnabled,
                isContractFieldsLoading: _isLoadingContractTypes,
                contractFieldsError: _contractTypesError,
                contractTypes: _contractTypes,
                selectedContractTypeId: _selectedContractTypeId,
                onContractFieldsToggle: _handleContractFieldsToggle,
                onContractTypeChanged: _handleContractTypeChanged,
                onContractTypeRetry:
                    widget.work.isContract ? () => _loadContractTypes() : null,
                unitsController: _unitsController,
                unitsValidator: _validateUnits,
                onUnitsChanged: _handleAttendanceFieldChanged,
                startTimeValidator: _validateStartTime,
                endTimeValidator: _validateEndTime,
                breakValidator: _validateBreakMinutes,
                statusMessage: _attendanceStatusMessage,
                isStatusError: _attendanceStatusIsError,
              ),
         /*     _ContractSummarySection(
                items: contractItems,
              ),*/
              if (hasSummaryContent) ...[
                const SizedBox(height: 24),
                summarySection,
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _buildHourlyRateText(AppLocalizations l) {
    if (widget.work.isContract) {
      return l.contractWorkLabel;
    }
    final rate = widget.work.hourlyRate;
    if (rate == null) {
      return l.notAvailableLabel;
    }
    return '${String.fromCharCode(36)}${rate.toStringAsFixed(2)}/hour';
  }

  String _resolveWorkTypeLabel(AppLocalizations l) {
    const possibleKeys = [
      'job_type',
      'jobType',
      'work_type',
      'workType',
      'type',
      'category',
      'role',
    ];

    for (final key in possibleKeys) {
      final value = widget.work.additionalData[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return widget.work.isContract ? l.contractWorkLabel : l.hourlyWorkLabel;
  }

  List<_ContractItem> _resolveContractItems() {
    final rawItems = widget.work.additionalData['contractItems'];
    if (rawItems is List) {
      return rawItems
          .whereType<Map>()
          .map((item) => _ContractItem(
                title: item['title']?.toString() ?? '',
                price: item['price']?.toString() ?? '',
              ))
          .where((item) => item.title.isNotEmpty && item.price.isNotEmpty)
          .toList();
    }
    return const <_ContractItem>[];
  }

  List<_SummaryStat> _buildSummaryStats(AppLocalizations l) {
    final summary = _dashboardSummary;
    if (summary != null) {
      final totalHours = summary.totalHours;
      final totalSalary = summary.totalSalary;
      final currencyPrefix = _resolveCurrencyPrefix(summary.raw);
      return <_SummaryStat>[
        _SummaryStat(
          title: l.totalHoursLabel,
          value: '${totalHours.toStringAsFixed(2)} h',
          color: const Color(0xFF2563EB),
          icon: Icons.access_time_filled,
        ),
        _SummaryStat(
          title: l.totalSalaryLabel,
          value: _formatCurrencyValue(totalSalary.toStringAsFixed(2), currencyPrefix),
          color: const Color(0xFF22C55E),
          icon: Icons.payments_rounded,
        ),
      ];
    }
    return _resolveSummaryStats(l);
  }

  Widget _buildSummarySection(AppLocalizations l, List<_SummaryStat> stats) {
    if (_isSummaryLoading) {
      return _SummaryStatusCard(
        message: l.reportsLoadingMessage,
        isLoading: true,
      );
    }
    if (_summaryError != null) {
      return _SummaryStatusCard(
        message: _summaryError!,
        onRetry: _loadSummary,
      );
    }
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }
    return _MonthlySummarySection(stats: stats);
  }

  List<_SummaryStat> _resolveSummaryStats(AppLocalizations l) {
    final summary = widget.work.additionalData['summary'];
    if (summary is Map) {
      final summaryMap = Map<String, dynamic>.from(summary);
      final currencyPrefix = _resolveCurrencyPrefix(summaryMap);
      final stats = <_SummaryStat>[];

      final totalHours = _formatSummaryMetric(
        summaryMap,
        const ['total_hours', 'totalHours', 'hours'],
        numericSuffix: ' h',
      );
      if (totalHours != null) {
        stats.add(
          _SummaryStat(
            title: l.totalHoursLabel,
            value: totalHours,
            color: const Color(0xFF2563EB),
            icon: Icons.access_time_filled,
          ),
        );
      }

      final totalSalary = _formatSummaryMetric(
        summaryMap,
        const ['total_salary', 'totalSalary', 'salary'],
        isCurrency: true,
        currencyPrefix: currencyPrefix,
      );
      if (totalSalary != null) {
        stats.add(
          _SummaryStat(
            title: l.totalSalaryLabel,
            value: totalSalary,
            color: const Color(0xFF22C55E),
            icon: Icons.payments_rounded,
          ),
        );
      }

      final hourlyWork = _formatSummaryMetric(
        summaryMap,
        const ['hourlyWork', 'hourly_work'],
        isCurrency: true,
        currencyPrefix: currencyPrefix,
      );
      if (hourlyWork != null) {
        stats.add(
          _SummaryStat(
            title: l.hourlyWorkLabel,
            value: hourlyWork,
            color: const Color(0xFF2563EB),
            icon: Icons.timelapse_rounded,
          ),
        );
      }

      final contractWork = _formatSummaryMetric(
        summaryMap,
        const ['contractWork', 'contract_work'],
        isCurrency: true,
        currencyPrefix: currencyPrefix,
      );
      if (contractWork != null) {
        stats.add(
          _SummaryStat(
            title: l.contractWorkLabel,
            value: contractWork,
            color: const Color(0xFF22C55E),
            icon: Icons.assignment_turned_in_rounded,
          ),
        );
      }

      return stats;
    }
    return const <_SummaryStat>[];
  }

  String _resolveCurrencyPrefix([Map<String, dynamic>? override]) {
    const fallback = '₹';
    final summarySymbol = _extractCurrencySymbol(override ?? _dashboardSummary?.raw);
    if (summarySymbol != null) {
      return summarySymbol;
    }
    final workSymbol = _extractCurrencySymbol(widget.work.additionalData);
    return workSymbol ?? fallback;
  }

  String? _extractCurrencySymbol(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return null;
    }
    const keys = ['currency_symbol', 'currencySymbol', 'currency', 'currencyCode', 'currencyPrefix'];
    final value = _findPreviewValue(data, keys);
    final text = _stringifyPreviewValue(value);
    if (text == null) {
      return null;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final isAlphabetic = trimmed.length == 3 &&
        trimmed.codeUnits.every(
          (unit) => (unit >= 65 && unit <= 90) || (unit >= 97 && unit <= 122),
        );
    if (isAlphabetic) {
      return '$trimmed ';
    }
    return trimmed;
  }

  String? _formatSummaryMetric(
    Map<String, dynamic> summary,
    List<String> keys, {
    String? numericSuffix,
    bool isCurrency = false,
    String? currencyPrefix,
  }) {
    final value = _findPreviewValue(summary, keys);
    if (value == null) {
      return null;
    }
    if (value is num) {
      final formatted = value.toDouble().toStringAsFixed(2);
      if (isCurrency && currencyPrefix != null) {
        return _formatCurrencyValue(formatted, currencyPrefix);
      }
      if (numericSuffix != null && numericSuffix.isNotEmpty) {
        return '$formatted$numericSuffix';
      }
      return formatted;
    }
    final textValue = _stringifyPreviewValue(value);
    if (textValue == null) {
      return null;
    }
    final trimmed = textValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (isCurrency && currencyPrefix != null) {
      final normalizedPrefix = currencyPrefix.trim();
      if (normalizedPrefix.isNotEmpty) {
        final normalizedValue = trimmed.replaceAll(RegExp(r'\s+'), '');
        final normalizedPrefixValue = normalizedPrefix.replaceAll(RegExp(r'\s+'), '');
        if (normalizedValue.startsWith(normalizedPrefixValue)) {
          return trimmed;
        }
      }
      return _formatCurrencyValue(trimmed, currencyPrefix);
    }
    if (numericSuffix != null && numericSuffix.isNotEmpty) {
      final normalizedSuffix = numericSuffix.trim().toLowerCase();
      if (!trimmed.toLowerCase().contains(normalizedSuffix)) {
        return '$trimmed$numericSuffix';
      }
    }
    return trimmed;
  }

  String _formatCurrencyValue(String value, String prefix) {
    final trimmedValue = value.trim();
    final trimmedPrefix = prefix.trim();
    if (trimmedValue.isEmpty) {
      return trimmedPrefix.isEmpty ? value : trimmedPrefix;
    }
    if (trimmedPrefix.isEmpty) {
      return trimmedValue;
    }
    final addSpace = prefix.trimRight() != prefix || trimmedPrefix.length > 1;
    return addSpace ? '$trimmedPrefix $trimmedValue' : '$trimmedPrefix$trimmedValue';
  }

  DateTime _normalizeDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    const monthNames = AppString.shortMonthAbbreviations;

    final month = monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }

  DateTime? _parseDateText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final direct = _tryParseDate(trimmed);
    if (direct != null) {
      return direct;
    }

    final embedded = _extractEmbeddedIsoDate(trimmed);
    if (embedded != null) {
      return embedded;
    }

    final numericMatch =
        RegExp(r'(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})').firstMatch(trimmed);
    if (numericMatch != null) {
      final part1 = int.tryParse(numericMatch.group(1)!);
      final part2 = int.tryParse(numericMatch.group(2)!);
      final year = int.tryParse(numericMatch.group(3)!);
      if (part1 != null && part2 != null && year != null) {
        final monthDay = _resolveMonthDayFromNumbers(part1, part2);
        if (monthDay != null &&
            _isValidDate(year, monthDay[0], monthDay[1])) {
          return DateTime(year, monthDay[0], monthDay[1]);
        }
      }
    }

    final monthNameMatch =
        RegExp(r'([A-Za-z]+)\s+(\d{1,2})(?:,)?\s+(\d{4})').firstMatch(trimmed);
    if (monthNameMatch != null) {
      final monthName = monthNameMatch.group(1)!;
      final day = int.tryParse(monthNameMatch.group(2)!);
      final year = int.tryParse(monthNameMatch.group(3)!);
      final month = _resolveMonthIndex(monthName);
      if (month != null && day != null && year != null &&
          _isValidDate(year, month, day)) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  List<int>? _resolveMonthDayFromNumbers(int first, int second) {
    if (first < 1 || second < 1) {
      return null;
    }
    if (first > 12 && second <= 12) {
      return <int>[second, first];
    }
    if (second > 12 && first <= 12) {
      return <int>[first, second];
    }
    if (first <= 12 && second <= 31) {
      return <int>[first, second];
    }
    if (second <= 12 && first <= 31) {
      return <int>[second, first];
    }
    return null;
  }

  int? _resolveMonthIndex(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    final fullIndex = AppString.fullMonthNames
        .indexWhere((month) => month.toLowerCase() == normalized);
    if (fullIndex != -1) {
      return fullIndex + 1;
    }
    final shortIndex = AppString.shortMonthAbbreviations
        .indexWhere((month) => month.toLowerCase() == normalized);
    if (shortIndex != -1) {
      return shortIndex + 1;
    }
    return null;
  }

  bool _isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return false;
    }
    final candidate = DateTime(year, month, day);
    return candidate.year == year &&
        candidate.month == month &&
        candidate.day == day;
  }

  String _normalizeDateLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    DateTime? parsed = _tryParseDate(trimmed);
    parsed ??= _extractEmbeddedIsoDate(trimmed);

    if (parsed != null) {
      final normalized = DateTime(parsed.year, parsed.month, parsed.day);
      return _formatDate(normalized);
    }

    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  DateTime? _tryParseDate(String value) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? _extractEmbeddedIsoDate(String value) {
    final match = RegExp(r'\d{4}-\d{2}-\d{2}(?:[T\s]\d{2}:\d{2}:[^\s]*)?')
        .firstMatch(value);
    if (match == null) {
      return null;
    }

    return _tryParseDate(value.substring(match.start, match.end));
  }
}

class _MissedAttendanceCompletionSheet extends StatefulWidget {
  const _MissedAttendanceCompletionSheet({
    required this.dates,
    required this.workId,
    required this.workName,
    required this.localization,
    required this.dateFormatter,
    this.contractTypeId,
    required this.onSubmit,
  });

  final List<DateTime> dates;
  final String workId;
  final String workName;
  final AppLocalizations localization;
  final String Function(DateTime) dateFormatter;
  final Object? contractTypeId;
  final Future<Map<String, dynamic>?> Function(
    List<MissedAttendanceCompletion> entries,
  ) onSubmit;

  @override
  State<_MissedAttendanceCompletionSheet> createState() =>
      _MissedAttendanceCompletionSheetState();
}

class _MissedAttendanceCompletionSheetState
    extends State<_MissedAttendanceCompletionSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final List<_MissedAttendanceFormData> _entries;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final sortedDates = widget.dates.toList(growable: false)
      ..sort((a, b) => a.compareTo(b));
    _entries = sortedDates
        .map((date) => _MissedAttendanceFormData(date: date))
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.localization;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FractionallySizedBox(
      heightFactor: 0.95,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.attendanceMissedEntriesTitle,
                                style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ) ??
                                    const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.attendanceMissedEntriesDescription,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF475569),
                              ) ??
                              const TextStyle(
                                color: Color(0xFF475569),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.workName,
                                style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1D4ED8),
                                        ) ??
                                    const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D4ED8),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.attendanceMissedEntriesListLabel,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF2563EB),
                                    ) ??
                                    const TextStyle(
                                      color: Color(0xFF2563EB),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFB91C1C),
                                  ) ??
                                  const TextStyle(
                                    color: Color(0xFFB91C1C),
                                  ),
                            ),
                          ),
                        ],
                        ..._entries.map(_buildEntryCard).toList(growable: false),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(l.attendanceMissedEntriesResolveButton),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(_MissedAttendanceFormData data) {
    final l = widget.localization;
    final formattedDate = widget.dateFormatter(data.date);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeDropdownField(
                  controller: data.startTimeController,
                  label: l.startTimeLabel,
                  icon: Icons.play_arrow_rounded,
                  enabled: !data.isLeave && !_isSubmitting,
                  validator: (value) => _validateTime(
                    value,
                    isRequired: !data.isLeave,
                    errorMessage: l.attendanceStartTimeRequired,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeDropdownField(
                  controller: data.endTimeController,
                  label: l.endTimeLabel,
                  icon: Icons.stop_rounded,
                  enabled: !data.isLeave && !_isSubmitting,
                  validator: (value) => _validateTime(
                    value,
                    isRequired: !data.isLeave,
                    errorMessage: l.attendanceEndTimeRequired,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBreakDropdownField(
            controller: data.breakMinutesController,
            label: l.breakLabel,
            icon: Icons.local_cafe_rounded,
            enabled: !data.isLeave && !_isSubmitting,
            validator: (value) {
              if (!(!data.isLeave && !_isSubmitting)) {
                return null;
              }
              if (value == null || value.trim().isEmpty) {
                return null;
              }
              final parsed = int.tryParse(value.trim());
              if (parsed == null || parsed < 0) {
                return l.attendanceBreakInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.markAsWorkOffButton,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            value: data.isLeave,
            onChanged: _isSubmitting
                ? null
                : (value) {
                    setState(() {
                      data.isLeave = value;
                      if (value) {
                        data.startTimeController.clear();
                        data.endTimeController.clear();
                        data.breakMinutesController.text = '0';
                      }
                    });
                  },
          ),
        ],
      ),
    );
  }

  String? _validateTime(
    String? value, {
      required bool isRequired,
      required String errorMessage,
  }) {
    if (!isRequired) {
      return null;
    }
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return errorMessage;
    }
    final parts = trimmed.split(':');
    if (parts.length != 2) {
      return widget.localization.attendanceInvalidTimeFormat;
    }
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) {
      return widget.localization.attendanceInvalidTimeFormat;
    }
    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
      return widget.localization.attendanceInvalidTimeFormat;
    }
    return null;
  }

  int _parseBreakMinutes(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      return 0;
    }
    return parsed;
  }

  Future<void> _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (!formState.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final entries = _entries
        .map(
          (data) => MissedAttendanceCompletion(
            workId: widget.workId,
            date: data.date,
            startTime: data.isLeave
                ? '00:00'
                : data.startTimeController.text.trim(),
            endTime: data.isLeave
                ? '00:00'
                : data.endTimeController.text.trim(),
            breakMinutes: data.isLeave
                ? 0
                : _parseBreakMinutes(data.breakMinutesController.text),
            contractTypeId: widget.contractTypeId,
            isLeave: data.isLeave,
          ),
        )
        .toList(growable: false);

    try {
      final response = await widget.onSubmit(entries);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(response ?? const <String, dynamic>{});
    } on AttendanceAuthException {
      final message = widget.localization.authenticationRequiredMessage;
      setState(() {
        _errorMessage = message;
      });
    } on AttendanceRepositoryException catch (e) {
      final message = e.message.trim().isNotEmpty
          ? e.message.trim()
          : widget.localization.attendanceMissedEntriesCompleteFailed;
      setState(() {
        _errorMessage = message;
      });
    } catch (_) {
      final message = widget.localization.attendanceMissedEntriesCompleteFailed;
      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _MissedAttendanceFormData {
  _MissedAttendanceFormData({required this.date})
      : startTimeController = TextEditingController(),
        endTimeController = TextEditingController(),
        breakMinutesController = TextEditingController(text: '0');

  final DateTime date;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final TextEditingController breakMinutesController;
  bool isLeave = false;

  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
    breakMinutesController.dispose();
  }
}

class _TimeDropdownOption {
  const _TimeDropdownOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _PendingAttendanceCard extends StatelessWidget {
  const _PendingAttendanceCard({
    required this.title,
    required this.description,
    required this.dateLabels,
    required this.highlightedLabel,
    required this.buttonLabel,
    required this.onReview,
  });

  final String title;
  final String description;
  final List<String> dateLabels;
  final String highlightedLabel;
  final String buttonLabel;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE4C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dateLabels.map((label) {
              final isHighlighted = label == highlightedLabel;
              return Chip(
                label: Text(label),
                backgroundColor:
                    isHighlighted ? const Color(0xFFFFEDD5) : Colors.white,
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isHighlighted ? const Color(0xFF9A3412) : const Color(0xFF6B7280),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: isHighlighted
                      ? const Color(0xFFF97316)
                      : const Color(0xFFE2E8F0),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkHeaderCard extends StatelessWidget {
  const _WorkHeaderCard({
    required this.work,
    required this.workTypeLabel,
    this.rateDescription,
  });

  final Work work;
  final String workTypeLabel;
  final String? rateDescription;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 16),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF0EA5E9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  AppAssets.bgBanner,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 24,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          workTypeLabel,
                          style: textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ) ??
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        work.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rateDescription ?? workTypeLabel,
                              style: textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ) ??
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset(
                        AppAssets.homeBanner2,
                        fit: BoxFit.cover,
                      ),
                    ),
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

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.dateLabel,
    required this.onDateTap,
    this.dateSelectionEnabled = true,
    required this.formKey,
    required this.startTimeController,
    required this.endTimeController,
    required this.breakMinutesController,
    required this.onSubmit,
    this.onWorkOffSubmit,
    required this.onFieldChanged,
    required this.isSubmitting,
    required this.isWorkOff,
    required this.startTimeValidator,
    required this.endTimeValidator,
    required this.breakValidator,
    this.onContractWorkTap,
    this.showContractWorkButton = false,
    this.showContractFields = false,
    this.contractFieldsEnabled = false,
    this.isContractFieldsLoading = false,
    this.contractFieldsError,
    this.contractTypes = const <ContractType>[],
    this.selectedContractTypeId,
    this.onContractFieldsToggle,
    this.onContractTypeChanged,
    this.onContractTypeRetry,
    this.unitsController,
    this.unitsValidator,
    this.onUnitsChanged,
    this.statusMessage,
    this.isStatusError = false,
  }) : assert(
          !showContractFields ||
              (unitsController != null &&
                  unitsValidator != null &&
                  onContractFieldsToggle != null),
        );

  final String dateLabel;
  final VoidCallback onDateTap;
  final bool dateSelectionEnabled;
  final GlobalKey<FormState> formKey;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final TextEditingController breakMinutesController;
  final VoidCallback onSubmit;
  final VoidCallback? onWorkOffSubmit;
  final VoidCallback onFieldChanged;
  final bool isSubmitting;
  final bool isWorkOff;
  final String? Function(String?) startTimeValidator;
  final String? Function(String?) endTimeValidator;
  final String? Function(String?) breakValidator;
  final VoidCallback? onContractWorkTap;
  final bool showContractWorkButton;
  final bool showContractFields;
  final bool contractFieldsEnabled;
  final bool isContractFieldsLoading;
  final String? contractFieldsError;
  final List<ContractType> contractTypes;
  final String? selectedContractTypeId;
  final ValueChanged<bool>? onContractFieldsToggle;
  final ValueChanged<String?>? onContractTypeChanged;
  final VoidCallback? onContractTypeRetry;
  final TextEditingController? unitsController;
  final String? Function(String?)? unitsValidator;
  final VoidCallback? onUnitsChanged;
  final String? statusMessage;
  final bool isStatusError;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 360;
                final titleWidget = Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.today_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.todaysAttendanceTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ) ??
                                const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                      ),
                    ),
                  ],
                );

                final dateSelector = AbsorbPointer(
                  absorbing: !dateSelectionEnabled,
                  child: Opacity(
                    opacity: dateSelectionEnabled ? 1 : 0.6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onDateTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  dateLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w600,
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

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 12),
                      dateSelector,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 12),
                    Flexible(child: dateSelector),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final maxWidth = constraints.maxWidth;
                final crossAxisCount = maxWidth < 420
                    ? 1
                    : maxWidth < 720
                        ? 2
                        : 3;
                final itemWidth = crossAxisCount == 1
                    ? maxWidth
                    : (maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

                final inputCards = <Widget>[
                  _AttendanceTimeCard(
                    label: l.startTimeLabel,
                    controller: startTimeController,
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFF22C55E),
                    hintText: AppString.timeInputHint,
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                    validator: startTimeValidator,
                    onChanged: (_) => onFieldChanged(),
                    enabled: !isSubmitting && !isWorkOff,
                    customField: _buildSegmentedTimeField(
                      controller: startTimeController,
                      validator: startTimeValidator,
                      enabled: !isSubmitting && !isWorkOff,
                      onValueChanged: () {
                        onFieldChanged();
                      },
                    ),
                  ),
                  _AttendanceTimeCard(
                    label: l.endTimeLabel,
                    controller: endTimeController,
                    icon: Icons.stop_rounded,
                    color: const Color(0xFFEF4444),
                    hintText: AppString.timeInputHint,
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                    validator: endTimeValidator,
                    onChanged: (_) => onFieldChanged(),
                    enabled: !isSubmitting && !isWorkOff,
                    customField: _buildSegmentedTimeField(
                      controller: endTimeController,
                      validator: endTimeValidator,
                      enabled: !isSubmitting && !isWorkOff,
                      onValueChanged: () {
                        onFieldChanged();
                      },
                    ),
                  ),
                  _AttendanceTimeCard(
                    label: l.breakLabel,
                    controller: breakMinutesController,
                    icon: Icons.local_cafe_rounded,
                    color: const Color(0xFFF59E0B),
                    hintText: AppString.zeroInputHint,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: breakValidator,
                    onChanged: (_) => onFieldChanged(),
                    enabled: !isSubmitting && !isWorkOff,
                    customField: _buildBreakDurationField(
                      controller: breakMinutesController,
                      validator: breakValidator,
                      enabled: !isSubmitting && !isWorkOff,
                      onValueChanged: () {
                        onFieldChanged();
                      },
                    ),
                  ),
                ];

                final cards = inputCards
                    .map((card) => SizedBox(
                          width: itemWidth.clamp(0.0, maxWidth),
                          child: card,
                        ))
                    .toList();

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: cards,
                );
              },
            ),
            if (showContractFields) ...[
              const SizedBox(height: 20),
              _ContractEntryForm(
                isActive: contractFieldsEnabled,
                isLoading: isContractFieldsLoading,
                errorMessage: contractFieldsError,
                contractTypes: contractTypes,
                selectedContractTypeId: selectedContractTypeId,
                onToggle: onContractFieldsToggle!,
                onTypeChanged: onContractTypeChanged,
                onRetry: onContractTypeRetry,
                unitsController: unitsController!,
                unitsValidator: unitsValidator!,
                onUnitsChanged: onUnitsChanged,
                isSubmitting: isSubmitting,
                isWorkOff: isWorkOff,
              ),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(context, l),
            if (statusMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isStatusError
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  statusMessage!,
                  style: TextStyle(
                    color: isStatusError
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF047857),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l) {
    final hasContractButton = showContractWorkButton && onContractWorkTap != null;
    final hasWorkOffButton = onWorkOffSubmit != null;

    if (!hasContractButton) {
      if (!hasWorkOffButton) {
        return _buildSubmitButton(context, l);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWorkOffButton(context, l),
          const SizedBox(height: 12),
          _buildSubmitButton(context, l),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 420;
        if (isStacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContractWorkButton(context, l),
              if (hasWorkOffButton) ...[
                const SizedBox(height: 12),
                _buildWorkOffButton(context, l),
              ],
              const SizedBox(height: 12),
              _buildSubmitButton(context, l),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildContractWorkButton(context, l)),
            if (hasWorkOffButton) ...[
              const SizedBox(width: 12),
              Expanded(child: _buildWorkOffButton(context, l)),
            ],
            const SizedBox(width: 12),
            Expanded(child: _buildSubmitButton(context, l)),
          ],
        );
      },
    );
  }

  Widget _buildContractWorkButton(BuildContext context, AppLocalizations l) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isSubmitting ? null : onContractWorkTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFEFF6FF),
          foregroundColor: const Color(0xFF1D4ED8),
          side: const BorderSide(color: Color(0xFF2563EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Icon(Icons.work_outline_rounded, size: 20),
            const SizedBox(width: 8),
            Text(l.contractWorkLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkOffButton(BuildContext context, AppLocalizations l) {
    final baseColor = const Color(0xFF2563EB);
    final isEnabled = !isSubmitting && onWorkOffSubmit != null;
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isEnabled ? baseColor : baseColor.withOpacity(0.4),
        ) ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isEnabled ? baseColor : baseColor.withOpacity(0.4),
        );

    return SizedBox(
      height: 52,
      child: _DashedBorderCard(
        borderColor: baseColor.withOpacity(isEnabled ? 0.6 : 0.25),
        backgroundColor:
            isEnabled ? const Color(0xFFF5F9FF) : const Color(0xFFF8FAFC),
        radius: 24,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isEnabled ? onWorkOffSubmit : null,
            child: Center(
              child: Text(
                l.markAsWorkOffButton,
                style: textStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, AppLocalizations l) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(l.attendanceSubmitButton),
      ),
    );
  }


  Widget _buildSegmentedTimeField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    required bool enabled,
    required VoidCallback onValueChanged,
  }) {
    const placeholderStyle = TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    const valueStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Color(0xFF0F172A),
    );
    const errorStyle = TextStyle(
      color: Color(0xFFDC2626),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return FormField<String>(
      validator: (_) => validator(controller.text),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final parsedTime = _parseFlexibleTime(value.text);
            final selectedHour = parsedTime != null
                ? _toDisplayHour(parsedTime.hour)
                : null;
            final minuteOptions = parsedTime != null
                ? _buildMinuteOptions(parsedTime.minute)
                : List<int>.from(_timeMinuteOptions);
            final selectedMinute = parsedTime != null
                ? (minuteOptions.contains(parsedTime.minute)
                    ? parsedTime.minute
                    : minuteOptions.first)
                : null;
            final selectedPeriod = parsedTime?.period;

            void updateValue({int? hour, int? minute, DayPeriod? period}) {
              if (!enabled) return;
              final resolvedHour = hour ?? selectedHour ?? _timeHourOptions.first;
              final resolvedMinute = minute ?? selectedMinute ?? minuteOptions.first;
              final resolvedPeriod = period ?? selectedPeriod ?? DayPeriod.am;
              final textValue =
                  _formatTimeDropdownValue(resolvedHour, resolvedMinute, resolvedPeriod);
              if (controller.text != textValue) {
                controller
                  ..text = textValue
                  ..selection = TextSelection.collapsed(offset: textValue.length);
              }
              onValueChanged();
              field.didChange(textValue);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSelectorSegment<int>(
                          width: 72,
                          value: selectedHour,
                          placeholder: 'HH',
                          items: _timeHourOptions
                            .map(
                              (hour) => DropdownMenuItem<int>(
                                value: hour,
                                child: Text(
                                  hour.toString().padLeft(2, '0'),
                                  style: valueStyle,
                                ),
                              ),
                            )
                            .toList(),
                          onChanged: enabled
                              ? (value) {
                                if (value == null) {
                                  controller.clear();
                                  field.didChange('');
                                  onValueChanged();
                                } else {
                                  updateValue(hour: value);
                                }
                              }
                            : null,
                          placeholderStyle: placeholderStyle,
                        ),
                        const SizedBox(width: 8),
                        _buildSegmentDivider(),
                        const SizedBox(width: 8),
                        _buildSelectorSegment<int>(
                          width: 72,
                          value: selectedMinute,
                          placeholder: 'MM',
                          items: minuteOptions
                            .map(
                              (minute) => DropdownMenuItem<int>(
                                value: minute,
                                child: Text(
                                  minute.toString().padLeft(2, '0'),
                                  style: valueStyle,
                                ),
                              ),
                            )
                            .toList(),
                          onChanged: enabled
                              ? (value) {
                                if (value == null) {
                                  controller.clear();
                                  field.didChange('');
                                  onValueChanged();
                                } else {
                                  updateValue(minute: value);
                                }
                              }
                            : null,
                          placeholderStyle: placeholderStyle,
                        ),
                        const SizedBox(width: 8),
                        _buildSegmentDivider(),
                        const SizedBox(width: 8),
                        _buildSelectorSegment<DayPeriod>(
                          width: 84,
                          value: selectedPeriod,
                          placeholder: AppString.amLabel,
                          items: DayPeriod.values
                            .map(
                              (period) => DropdownMenuItem<DayPeriod>(
                                value: period,
                                child: Text(
                                  period == DayPeriod.am
                                      ? AppString.amLabel
                                      : AppString.pmLabel,
                                  style: valueStyle,
                                ),
                              ),
                            )
                            .toList(),
                          onChanged: enabled
                              ? (value) {
                                  if (value == null) {
                                    controller.clear();
                                    field.didChange('');
                                    onValueChanged();
                                  } else {
                                    updateValue(period: value);
                                  }
                                }
                              : null,
                          placeholderStyle: placeholderStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      field.errorText ?? '',
                      style: errorStyle,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBreakDurationField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    required bool enabled,
    required VoidCallback onValueChanged,
  }) {
    const placeholderStyle = TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    const valueStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Color(0xFF0F172A),
    );
    const labelStyle = TextStyle(
      color: Color(0xFF64748B),
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    const errorStyle = TextStyle(
      color: Color(0xFFDC2626),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return FormField<String>(
      validator: (_) => validator(controller.text),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final trimmed = value.text.trim();
            final parsed = int.tryParse(trimmed);
            final selectedHour = parsed != null ? parsed ~/ 60 : null;
            final selectedMinute = parsed != null ? parsed % 60 : null;

            final hourItems = _breakHourOptions
                .map(
                  (hour) => DropdownMenuItem<int>(
                    value: hour,
                    child: Text(
                      hour.toString().padLeft(2, '0'),
                      style: valueStyle,
                    ),
                  ),
                )
                .toList();

            final resolvedHour = (selectedHour != null &&
                    _breakHourOptions.contains(selectedHour))
                ? selectedHour
                : null;
            final minutesForHour = _breakMinutesForHour(
                resolvedHour ?? _breakHourOptions.first);
            final resolvedMinute = (selectedMinute != null &&
                    minutesForHour.contains(selectedMinute))
                ? selectedMinute
                : null;

            void updateBreakValue(int hour, int minute) {
              final total = (hour * 60) + minute;
              final textValue = total.toString();
              if (controller.text != textValue) {
                controller
                  ..text = textValue
                  ..selection = TextSelection.collapsed(offset: textValue.length);
              }
              onValueChanged();
              field.didChange(textValue);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSelectorSegment<int>(
                          width: 72,
                          value: resolvedHour,
                          placeholder: '00',
                          items: hourItems,
                          onChanged: enabled
                              ? (value) {
                                  if (value == null) {
                                    controller.clear();
                                    field.didChange('');
                                    onValueChanged();
                                    return;
                                  }
                                  final minutes = _breakMinutesForHour(value).first;
                                  updateBreakValue(value, minutes);
                                }
                              : null,
                          placeholderStyle: placeholderStyle,
                        ),
                        const SizedBox(width: 6),
                        const Text('hr', style: labelStyle),
                        const SizedBox(width: 12),
                        _buildSegmentDivider(),
                        const SizedBox(width: 12),
                        _buildSelectorSegment<int>(
                          width: 72,
                          value: resolvedMinute,
                          placeholder: '00',
                          items: minutesForHour
                              .map(
                                (minute) => DropdownMenuItem<int>(
                                  value: minute,
                                  child: Text(
                                    minute.toString().padLeft(2, '0'),
                                    style: valueStyle,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: enabled
                              ? (value) {
                                  if (value == null) {
                                    controller.clear();
                                    field.didChange('');
                                    onValueChanged();
                                    return;
                                  }
                                  final hour =
                                      resolvedHour ?? _breakHourOptions.first;
                                  updateBreakValue(hour, value);
                                }
                              : null,
                          placeholderStyle: placeholderStyle,
                        ),
                        const SizedBox(width: 6),
                        const Text('min', style: labelStyle),
                      ],
                    ),
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      field.errorText ?? '',
                      style: errorStyle,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSelectorSegment<T>({
    required double width,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String placeholder,
    required ValueChanged<T?>? onChanged,
    required TextStyle placeholderStyle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF2563EB),
          ),
          hint: Text(placeholder, style: placeholderStyle),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentDivider() {
    return Container(
      width: 1,
      height: 38,
      color: const Color(0xFFE2E8F0),
    );
  }
}

class _DashedBorderCard extends StatelessWidget {
  const _DashedBorderCard({
    required this.child,
    required this.borderColor,
    required this.backgroundColor,
    this.radius = 20,
    this.strokeWidth = 1.4,
    this.dashLength = 6,
    this.gapLength = 4,
  });

  final Widget child;
  final Color borderColor;
  final Color backgroundColor;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: borderColor,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rect = Offset.zero & size;
    final double effectiveRadius =
        radius.clamp(0.0, size.shortestSide / 2) as double;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(effectiveRadius),
    );
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final double dashValue = dashLength <= 0 ? 4 : dashLength;
    final double gapValue = gapLength <= 0 ? 4 : gapLength;
    final pattern = <double>[dashValue, gapValue];

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      int index = 0;
      while (distance < metric.length) {
        final double segmentLength = pattern[index % pattern.length];
        final double next = distance + segmentLength;
        final double clampedNext =
            next < metric.length ? next : metric.length;
        if (index.isEven) {
          final segment = metric.extractPath(distance, clampedNext);
          canvas.drawPath(segment, paint);
        }
        distance = clampedNext;
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        gapLength != oldDelegate.gapLength;
  }
}

class _ContractSummarySection extends StatefulWidget {
  const _ContractSummarySection({
    required this.items,
  });

  final List<_ContractItem> items;

  @override
  State<_ContractSummarySection> createState() => _ContractSummarySectionState();
}

class _ContractSummarySectionState extends State<_ContractSummarySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = widget.items;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.contractWorkSummaryTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ) ??
                          const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                    ),
                  ),
                  Text(
                    l.summaryLabel,
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Color(0xFF1F2937)),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, i == 0 ? 0 : 12, 24,
                        i == items.length - 1 ? 24 : 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[i].title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        Text(
                          items[i].price,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

}

class _SummaryStatusCard extends StatelessWidget {
  const _SummaryStatusCard({
    required this.message,
    this.isLoading = false,
    this.onRetry,
  });

  final String message;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final header = '${_formatMonthYearLabel(DateTime.now())} ${l.summaryLabel}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            header,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: onRetry,
                              child: Text(
                                l.retryButtonLabel,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractEntryForm extends StatelessWidget {
  const _ContractEntryForm({
    required this.isActive,
    required this.isLoading,
    required this.contractTypes,
    required this.selectedContractTypeId,
    required this.onToggle,
    required this.unitsController,
    required this.unitsValidator,
    required this.isSubmitting,
    required this.isWorkOff,
    this.errorMessage,
    this.onTypeChanged,
    this.onRetry,
    this.onUnitsChanged,
  });

  final bool isActive;
  final bool isLoading;
  final List<ContractType> contractTypes;
  final String? selectedContractTypeId;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String?>? onTypeChanged;
  final VoidCallback? onRetry;
  final TextEditingController unitsController;
  final String? Function(String?) unitsValidator;
  final VoidCallback? onUnitsChanged;
  final bool isSubmitting;
  final bool isWorkOff;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bool disableInteractions = isSubmitting || isWorkOff;
    final bool hasSelectedType = contractTypes.any(
      (type) => type.id == selectedContractTypeId,
    );
    final ContractType? selectedType = hasSelectedType
        ? contractTypes.firstWhere(
            (type) => type.id == selectedContractTypeId,
            orElse: () => contractTypes.first,
          )
        : null;
    final String? dropdownValue = hasSelectedType ? selectedContractTypeId : null;
    final String unitLabel = (selectedType?.unitLabel.trim().isNotEmpty ?? false)
        ? selectedType!.unitLabel.trim()
        : l.contractWorkUnitFallback;
    final String? rateHelperText = selectedType != null
        ? '${l.contractWorkRateLabel}: '
            '${selectedType.rate.toStringAsFixed(2)} / '
            '${selectedType.unitLabel.trim().isNotEmpty ? selectedType.unitLabel : l.contractWorkUnitFallback}'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.contractWorkLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
              ),
              Switch.adaptive(
                value: isActive,
                activeColor: const Color(0xFF2563EB),
                onChanged: disableInteractions ? null : onToggle,
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 16),
            if (isLoading) ...[
              const SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFE0E7FF),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ] else if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
              _ContractFormMessage(
                message: errorMessage!,
                isError: true,
                onRetry: onRetry,
              ),
            ] else if (contractTypes.isEmpty) ...[
              _ContractFormMessage(
                message: l.contractWorkNoCustomTypesLabel,
                onRetry: onRetry,
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: dropdownValue,
                onChanged: disableInteractions ? null : onTypeChanged,
                isExpanded: true,
                itemHeight: null,
                decoration: InputDecoration(
                  labelText: l.contractWorkContractTypeLabel,
                  prefixIcon: const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xFF1D4ED8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                items: contractTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              type.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${type.rate.toStringAsFixed(2)} / '
                              '${type.unitLabel.trim().isNotEmpty ? type.unitLabel : l.contractWorkUnitFallback}',
                              style: TextStyle(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: unitsController,
                enabled: !disableInteractions,
                validator: unitsValidator,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.contractWorkUnitsLabel,
                  prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF2563EB),
                  ),
                  suffixText: unitLabel,
                  helperText: rateHelperText,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onChanged: (_) => onUnitsChanged?.call(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ContractFormMessage extends StatelessWidget {
  const _ContractFormMessage({
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        isError ? const Color(0xFFFFF1F2) : const Color(0xFFEFF6FF);
    final Color foregroundColor =
        isError ? const Color(0xFFB91C1C) : const Color(0xFF1D4ED8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foregroundColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context).retryButtonLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlySummarySection extends StatelessWidget {
  const _MonthlySummarySection({
    required this.stats,
  });

  final List<_SummaryStat> stats;

  @override
  Widget build(BuildContext context) {
    final monthName = _formatMonthYearLabel(DateTime.now());
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$monthName ${l.summaryLabel}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isCompact = maxWidth < 420;
              final crossAxisCount = isCompact ? 1 : 2;
              const crossAxisSpacing = 12.0;
              final availableWidth =
                  maxWidth - crossAxisSpacing * (crossAxisCount - 1);
              final itemWidth = availableWidth / crossAxisCount;
              final desiredHeight = isCompact ? 164.0 : 156.0;
              final childAspectRatio = itemWidth / desiredHeight;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: crossAxisSpacing,
                childAspectRatio: childAspectRatio,
                children:
                    stats.map((stat) => _SummaryStatCard(stat: stat)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

}

class _AttendanceTimeCard extends StatelessWidget {
  const _AttendanceTimeCard({
    required this.label,
    required this.controller,
    required this.icon,
    required this.color,
    required this.hintText,
    required this.keyboardType,
    required this.textInputAction,
    required this.validator,
    required this.onChanged,
    this.enabled = true,
    this.inputFormatters = const <TextInputFormatter>[],
    this.customField,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color color;
  final String hintText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final List<TextInputFormatter> inputFormatters;
  final Widget? customField;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          customField ??
              TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                validator: validator,
                onChanged: onChanged,
                enabled: enabled,
                inputFormatters: inputFormatters,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({required this.stat});

  final _SummaryStat stat;

  @override
  Widget build(BuildContext context) {
    final baseColor = stat.color;
    final secondaryColor = Color.lerp(baseColor, Colors.white, 0.2)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14222C3A),
            offset: Offset(0, 16),
            blurRadius: 32,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [baseColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const SizedBox.expand(),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 72,
                  child: CustomPaint(
                    painter: _SummaryStatWavePainter(
                      color: Colors.white.withOpacity(0.38),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.22),
                    ),
                    child: Icon(
                      stat.icon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          stat.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatWavePainter extends CustomPainter {
  const _SummaryStatWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startX = size.width * 0.7;

    path.moveTo(startX, -size.height * 0.15);
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.25,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.05,
      size.height * 0.75,
      size.width * 0.8,
      size.height * 1.15,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SummaryStatWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _AttendancePreviewSheet extends StatelessWidget {
  const _AttendancePreviewSheet({
    required this.title,
    required this.description,
    required this.validationMessage,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.hoursLabel,
    required this.hoursValue,
    required this.salaryLabel,
    required this.salaryValue,
    required this.entries,
    required this.onEdit,
    required this.onConfirm,
  });

  final String title;
  final String description;
  final String validationMessage;
  final String cancelLabel;
  final String confirmLabel;
  final String hoursLabel;
  final String hoursValue;
  final String salaryLabel;
  final String? salaryValue;
  final List<_PreviewInfoEntry> entries;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 32,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.fact_check_rounded,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ) ??
                                      const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  style: textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF475569),
                                        height: 1.4,
                                      ) ??
                                      const TextStyle(
                                        color: Color(0xFF475569),
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _AttendancePreviewSummaryCard(
                        hoursLabel: hoursLabel,
                        hoursValue: hoursValue,
                        salaryLabel: salaryLabel,
                        salaryValue: salaryValue,
                        entries: entries,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFEAB308),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                validationMessage,
                                style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF854D0E),
                                      fontWeight: FontWeight.w600,
                                    ) ??
                                    const TextStyle(
                                      color: Color(0xFF854D0E),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(cancelLabel),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendancePreviewSummaryCard extends StatelessWidget {
  const _AttendancePreviewSummaryCard({
    required this.hoursLabel,
    required this.hoursValue,
    required this.salaryLabel,
    required this.salaryValue,
    required this.entries,
  });

  final String hoursLabel;
  final String hoursValue;
  final String salaryLabel;
  final String? salaryValue;
  final List<_PreviewInfoEntry> entries;

  @override
  Widget build(BuildContext context) {
    final hasSalary = salaryValue != null && salaryValue!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14343C4D),
            offset: Offset(0, 16),
            blurRadius: 32,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _PreviewHighlightCard(
                  label: hoursLabel,
                  value: hoursValue,
                  color: const Color(0xFF2563EB),
                ),
              ),
              if (hasSalary) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _PreviewHighlightCard(
                    label: salaryLabel,
                    value: salaryValue!.trim(),
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(
              height: 1,
              color: Color(0xFFE5E7EB),
            ),
            const SizedBox(height: 12),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _PreviewInfoTile(entry: entry),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewHighlightCard extends StatelessWidget {
  const _PreviewHighlightCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewInfoTile extends StatelessWidget {
  const _PreviewInfoTile({required this.entry});

  final _PreviewInfoEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            entry.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            entry.value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewInfoEntry {
  const _PreviewInfoEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _ContractItem {
  const _ContractItem({required this.title, required this.price});

  final String title;
  final String price;
}

class _SummaryStat {
  const _SummaryStat({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;
}

String _formatMonthYearLabel(DateTime date) {
  const monthNames = AppString.fullMonthNames;
  return '${monthNames[date.month - 1]} ${date.year}';
}

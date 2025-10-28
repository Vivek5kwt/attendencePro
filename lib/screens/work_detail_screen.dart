import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_strings.dart';
import '../core/localization/app_localizations.dart';
import '../models/dashboard_summary.dart';
import '../models/missed_attendance_completion.dart';
import '../models/work.dart';
import '../repositories/attendance_entry_repository.dart';
import '../repositories/dashboard_repository.dart';

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
  final GlobalKey<FormState> _attendanceFormKey = GlobalKey<FormState>();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _breakMinutesController =
      TextEditingController(text: '0');
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _ratePerUnitController = TextEditingController();

  bool _contractFieldsEnabled = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  void _initializeAttendanceControllers() {
    _selectedDate = DateTime.now();
    _dateLabelOverride = null;

    final additionalData = widget.work.additionalData;
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

    final hasData =
        _unitsController.text.trim().isNotEmpty ||
            _ratePerUnitController.text.trim().isNotEmpty;
    if (_contractFieldsEnabled == hasData) {
      return;
    }
    if (notify) {
      setState(() {
        _contractFieldsEnabled = hasData;
      });
    } else {
      _contractFieldsEnabled = hasData;
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
    if (dateText != null && dateText.isNotEmpty && mounted) {
      setState(() {
        _dateLabelOverride = _normalizeDateLabel(dateText);
      });
    }

    _syncContractFieldsVisibility(notify: true);
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
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
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
    if (!widget.work.isContract) {
      return;
    }
    setState(() {
      _contractFieldsEnabled = value;
    });
    _handleAttendanceFieldChanged();
  }

  String? _validateStartTime(String? value) {
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
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();
    final breakMinutes = _resolveBreakMinutes(_breakMinutesController.text);
    final bool isContractEntry =
        widget.work.isContract && _contractFieldsEnabled;
    num? units;
    num? ratePerUnit;
    int? contractTypeId;
    if (isContractEntry) {
      units = _parseNumberInput(_unitsController.text);
      ratePerUnit = _parseNumberInput(_ratePerUnitController.text);
      contractTypeId = _resolveContractTypeId();
    }

    final canSubmit = await _ensureNoBlockingMissedEntries();
    if (!mounted || !canSubmit) {
      return;
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
        startTime: startTime,
        endTime: endTime,
        breakMinutes: breakMinutes,
        isContractEntry: isContractEntry,
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
        isContractEntry: isContractEntry,
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
        startTime: startTime,
        endTime: endTime,
        breakMinutes: breakMinutes,
        isContractEntry: isContractEntry,
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
                formKey: _attendanceFormKey,
                startTimeController: _startTimeController,
                endTimeController: _endTimeController,
                breakMinutesController: _breakMinutesController,
                unitsController: _unitsController,
                ratePerUnitController: _ratePerUnitController,
                onSubmit: _submitAttendance,
                onFieldChanged: _handleAttendanceFieldChanged,
                isSubmitting: _isSubmittingAttendance,
                startTimeValidator: _validateStartTime,
                endTimeValidator: _validateEndTime,
                breakValidator: _validateBreakMinutes,
                unitsValidator: _validateUnits,
                ratePerUnitValidator: _validateRatePerUnit,
                showContractFields: widget.work.isContract,
                contractFieldsEnabled: _contractFieldsEnabled,
                onContractFieldsToggle: widget.work.isContract
                    ? _handleContractFieldsToggle
                    : null,
                statusMessage: _attendanceStatusMessage,
                isStatusError: _attendanceStatusIsError,
              ),
              const SizedBox(height: 24),
              _ContractSummarySection(
                items: contractItems,
              ),
              const SizedBox(height: 24),
              summarySection,
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
    return const <_ContractItem>[
      _ContractItem(
        title: AppString.fallbackContractItemTitle,
        price: AppString.fallbackContractItemPriceLow,
      ),
      _ContractItem(
        title: AppString.fallbackContractItemTitle,
        price: AppString.fallbackContractItemPriceHigh,
      ),
      _ContractItem(
        title: AppString.fallbackContractItemCarrotTitle,
        price: AppString.fallbackContractItemCarrotPrice,
      ),
    ];
  }

  List<_SummaryStat> _buildSummaryStats(AppLocalizations l) {
    final summary = _dashboardSummary;
    if (summary != null) {
      final totalHours = summary.totalHours;
      final totalSalary = summary.totalSalary;
      return <_SummaryStat>[
        _SummaryStat(
          title: l.totalHoursLabel,
          value: '${totalHours.toStringAsFixed(2)} h',
          color: const Color(0xFF2563EB),
          icon: Icons.access_time_filled,
        ),
        _SummaryStat(
          title: l.totalSalaryLabel,
          value: '€${totalSalary.toStringAsFixed(2)}',
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
    return _MonthlySummarySection(stats: stats);
  }

  List<_SummaryStat> _resolveSummaryStats(AppLocalizations l) {
    final summary = widget.work.additionalData['summary'];
    if (summary is Map) {
      final totalHours = summary['totalHours']?.toString();
      final totalSalary = summary['totalSalary']?.toString();
      final hourlyWork = summary['hourlyWork']?.toString();
      final contractWork = summary['contractWork']?.toString();
      return <_SummaryStat>[
        _SummaryStat(
          title: l.totalHoursLabel,
          value: totalHours ?? '0h',
          color: const Color(0xFF2563EB),
          icon: Icons.access_time_filled,
        ),
        _SummaryStat(
          title: l.totalSalaryLabel,
          value: totalSalary ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF22C55E),
          icon: Icons.payments_rounded,
        ),
        _SummaryStat(
          title: l.hourlyWorkLabel,
          value: hourlyWork ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF2563EB),
          icon: Icons.timelapse_rounded,
        ),
        _SummaryStat(
          title: l.contractWorkLabel,
          value: contractWork ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF22C55E),
          icon: Icons.assignment_turned_in_rounded,
        ),
      ];
    }

    return <_SummaryStat>[
      _SummaryStat(
        title: l.totalHoursLabel,
        value: AppString.fallbackSummaryHours,
        color: const Color(0xFF2563EB),
        icon: Icons.access_time_filled,
      ),
      _SummaryStat(
        title: l.totalSalaryLabel,
        value: AppString.fallbackSummarySalary,
        color: const Color(0xFF22C55E),
        icon: Icons.payments_rounded,
      ),
      _SummaryStat(
        title: l.hourlyWorkLabel,
        value: AppString.fallbackSummaryHourly,
        color: const Color(0xFF2563EB),
        icon: Icons.timelapse_rounded,
      ),
      _SummaryStat(
        title: l.contractWorkLabel,
        value: AppString.fallbackSummaryContract,
        color: const Color(0xFF22C55E),
        icon: Icons.assignment_turned_in_rounded,
      ),
    ];
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
    required this.formKey,
    required this.startTimeController,
    required this.endTimeController,
    required this.breakMinutesController,
    required this.unitsController,
    required this.ratePerUnitController,
    required this.onSubmit,
    required this.onFieldChanged,
    required this.isSubmitting,
    required this.startTimeValidator,
    required this.endTimeValidator,
    required this.breakValidator,
    required this.unitsValidator,
    required this.ratePerUnitValidator,
    required this.showContractFields,
    required this.contractFieldsEnabled,
    this.onContractFieldsToggle,
    this.statusMessage,
    this.isStatusError = false,
  }) : assert(!showContractFields ||
            (unitsController != null &&
                ratePerUnitController != null &&
                unitsValidator != null &&
                ratePerUnitValidator != null));

  final String dateLabel;
  final VoidCallback onDateTap;
  final GlobalKey<FormState> formKey;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final TextEditingController breakMinutesController;
  final TextEditingController? unitsController;
  final TextEditingController? ratePerUnitController;
  final VoidCallback onSubmit;
  final VoidCallback onFieldChanged;
  final bool isSubmitting;
  final String? Function(String?) startTimeValidator;
  final String? Function(String?) endTimeValidator;
  final String? Function(String?) breakValidator;
  final String? Function(String?)? unitsValidator;
  final String? Function(String?)? ratePerUnitValidator;
  final bool showContractFields;
  final bool contractFieldsEnabled;
  final ValueChanged<bool>? onContractFieldsToggle;
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

                final dateSelector = Material(
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

                final parsedBreakValue =
                    int.tryParse(breakMinutesController.text.trim());
                final initialBreakValue = parsedBreakValue != null &&
                        _breakDurationOptions.contains(parsedBreakValue)
                    ? parsedBreakValue
                    : null;

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
                    enabled: !isSubmitting,
                    customField: DropdownButtonFormField<String?> (
                      value:
                          _normalizeTimeDropdownValue(startTimeController.text),
                      items: _buildTimeDropdownMenuItems(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      onChanged: !isSubmitting
                          ? (value) {
                              final text = value ?? '';
                              startTimeController
                                ..text = text
                                ..selection = TextSelection.collapsed(
                                    offset: text.length);
                              onFieldChanged();
                            }
                          : null,
                      validator: startTimeValidator,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      hint: const Text(
                        AppString.timePlaceholder,
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
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
                    enabled: !isSubmitting,
                    customField: DropdownButtonFormField<String?> (
                      value:
                          _normalizeTimeDropdownValue(endTimeController.text),
                      items: _buildTimeDropdownMenuItems(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      onChanged: !isSubmitting
                          ? (value) {
                              final text = value ?? '';
                              endTimeController
                                ..text = text
                                ..selection = TextSelection.collapsed(
                                    offset: text.length);
                              onFieldChanged();
                            }
                          : null,
                      validator: endTimeValidator,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      hint: const Text(
                        AppString.timePlaceholder,
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  _AttendanceTimeCard(
                    label: l.breakLabel,
                    controller: breakMinutesController,
                    icon: Icons.local_cafe_rounded,
                    color: const Color(0xFFF59E0B),
                    hintText: AppString.zeroInputHint,
                    keyboardType: TextInputType.number,
                    textInputAction:
                        contractFieldsEnabled
                            ? TextInputAction.next
                            : TextInputAction.done,
                    validator: breakValidator,
                    onChanged: (_) => onFieldChanged(),
                    enabled: !isSubmitting,
                    customField: DropdownButtonFormField<int?> (
                      value: initialBreakValue,
                      items: _buildBreakDropdownMenuItems(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      onChanged: !isSubmitting
                          ? (value) {
                              final text = value?.toString() ?? '';
                              breakMinutesController
                                ..text = text
                                ..selection = TextSelection.collapsed(
                                    offset: text.length);
                              onFieldChanged();
                            }
                          : null,
                      validator: (value) =>
                          breakValidator(value?.toString()),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                        hint: const Text(
                          AppString.doubleDashPlaceholder,
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ];

                if (showContractFields &&
                    contractFieldsEnabled &&
                    unitsController != null &&
                    ratePerUnitController != null) {
                  final decimalFormatter =
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
                  inputCards.addAll([
                    _AttendanceTimeCard(
                      label: l.contractWorkUnitsLabel,
                      controller: unitsController!,
                      icon: Icons.stacked_bar_chart_rounded,
                      color: const Color(0xFF6366F1),
                      hintText: AppString.zeroInputHint,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: unitsValidator,
                      onChanged: (_) => onFieldChanged(),
                      enabled: !isSubmitting,
                      inputFormatters: [decimalFormatter],
                    ),
                    _AttendanceTimeCard(
                      label: l.contractWorkRateLabel,
                      controller: ratePerUnitController!,
                      icon: Icons.attach_money,
                      color: const Color(0xFF2563EB),
                      hintText: AppString.zeroDecimalInputHint,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      validator: ratePerUnitValidator,
                      onChanged: (_) => onFieldChanged(),
                      enabled: !isSubmitting,
                      inputFormatters: [decimalFormatter],
                    ),
                  ]);
                }

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
            const SizedBox(height: 24),
            if (showContractFields && onContractFieldsToggle != null) ...[
              Row(
                children: [
                  Expanded(child: _buildContractToggleButton(l)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSubmitButton(context, l)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${l.contractWorkUnitsLabel} • ${l.contractWorkRateLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ) ??
                    const TextStyle(
                      color: Color(0xFF6B7280),
                    ),
              ),
            ] else ...[
              _buildSubmitButton(context, l),
            ],
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

  Widget _buildSubmitButton(BuildContext context, AppLocalizations l) {
    return SizedBox(
      width: double.infinity,
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

  Widget _buildContractToggleButton(AppLocalizations l) {
    final isEnabled = contractFieldsEnabled;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: (onContractFieldsToggle == null || isSubmitting)
            ? null
            : () {
                final nextValue = !isEnabled;
                onContractFieldsToggle?.call(nextValue);
                onFieldChanged();
              },
        icon: const Icon(Icons.stacked_bar_chart_rounded),
        label: Text(l.contractWorkLabel),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xFF1D4ED8) : const Color(0xFFEFF6FF),
          foregroundColor:
              isEnabled ? Colors.white : const Color(0xFF1D4ED8),
          side: BorderSide(
            color: isEnabled ? Colors.transparent : const Color(0xFFBFDBFE),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/dashboard_summary.dart';
import '../models/work.dart';
import '../repositories/attendance_entry_repository.dart';
import '../repositories/dashboard_repository.dart';

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

  DashboardSummary? _dashboardSummary;
  bool _isSummaryLoading = true;
  String? _summaryError;
  bool _isSubmittingAttendance = false;
  String? _attendanceStatusMessage;
  bool _attendanceStatusIsError = false;
  DateTime _selectedDate = DateTime.now();
  String? _dateLabelOverride;

  @override
  void initState() {
    super.initState();
    _initializeAttendanceControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
    });
  }

  String? _extractTimeFromMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
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
      _startTimeController.text = startTime.trim();
    }

    final endTime = _extractTimeFromMap(
          entry.raw,
          const ['end_time', 'endTime', 'out_time'],
        ) ??
        entry.endTimeText;
    if (endTime != null && endTime.trim().isNotEmpty) {
      _endTimeController.text = endTime.trim();
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
        _dateLabelOverride = dateText;
      });
    }
  }

  void _handleAttendanceFieldChanged() {
    if (_attendanceStatusMessage != null) {
      setState(() {
        _attendanceStatusMessage = null;
        _attendanceStatusIsError = false;
      });
    }
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
    if (!widget.work.isContract) {
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
    if (!widget.work.isContract) {
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
      if (value == null) {
        continue;
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
          continue;
        }
        final parsed = int.tryParse(trimmed);
        if (parsed != null) {
          return parsed;
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
    final bool isContractEntry = widget.work.isContract;
    num? units;
    num? ratePerUnit;
    int? contractTypeId;
    if (isContractEntry) {
      units = _parseNumberInput(_unitsController.text);
      ratePerUnit = _parseNumberInput(_ratePerUnitController.text);
      contractTypeId = _resolveContractTypeId();
    }

    setState(() {
      _isSubmittingAttendance = true;
      _attendanceStatusMessage = null;
      _attendanceStatusIsError = false;
    });

    try {
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
    final contractItems = _resolveContractItems();
    final summaryStats = _buildSummaryStats(l);
    final todayEntry = _dashboardSummary?.todayEntry;
    final dateLabel = (_dateLabelOverride?.isNotEmpty ?? false)
        ? _dateLabelOverride!
        : (todayEntry?.dateText?.trim().isNotEmpty == true
            ? todayEntry!.dateText!.trim()
            : _formatDate(_selectedDate));
    final summarySection = _buildSummarySection(l, summaryStats);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.changeWorkButton),
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
                hourlyRateText: hourlyRateText,
              ),
              const SizedBox(height: 24),
              _AttendanceSection(
                dateLabel: dateLabel,
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
      _ContractItem(title: 'Ravanello (10 qty)', price: '\$3 / 100 units'),
      _ContractItem(title: 'Ravanello (10 qty)', price: '\$4 / 100 units'),
      _ContractItem(title: 'Carrot', price: '\$5 / crate'),
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
        ),
        _SummaryStat(
          title: l.totalSalaryLabel,
          value: '€${totalSalary.toStringAsFixed(2)}',
          color: const Color(0xFF22C55E),
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
        ),
        _SummaryStat(
          title: l.totalSalaryLabel,
          value: totalSalary ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF22C55E),
        ),
        _SummaryStat(
          title: l.hourlyWorkLabel,
          value: hourlyWork ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF2563EB),
        ),
        _SummaryStat(
          title: l.contractWorkLabel,
          value: contractWork ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF22C55E),
        ),
      ];
    }

    return <_SummaryStat>[
      _SummaryStat(
        title: l.totalHoursLabel,
        value: '156.5h',
        color: const Color(0xFF2563EB),
      ),
      _SummaryStat(
        title: l.totalSalaryLabel,
        value: '\$1950',
        color: const Color(0xFF22C55E),
      ),
      _SummaryStat(
        title: l.hourlyWorkLabel,
        value: '\$956',
        color: const Color(0xFF2563EB),
      ),
      _SummaryStat(
        title: l.contractWorkLabel,
        value: '\$994',
        color: const Color(0xFF22C55E),
      ),
    ];
  }

  String _formatDate(DateTime date) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }
}

class _WorkHeaderCard extends StatelessWidget {
  const _WorkHeaderCard({
    required this.work,
    required this.hourlyRateText,
  });

  final Work work;
  final String hourlyRateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    hourlyRateText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  work.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Restaurant Job',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            height: 110,
            width: 110,
            child: Image.asset(AppAssets.homeBanner, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.dateLabel,
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
    this.statusMessage,
    this.isStatusError = false,
  }) : assert(!showContractFields ||
            (unitsController != null &&
                ratePerUnitController != null &&
                unitsValidator != null &&
                ratePerUnitValidator != null));

  final String dateLabel;
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.todaysAttendanceTitle,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    hintText: 'HH:MM',
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                    validator: startTimeValidator,
                    onChanged: (_) => onFieldChanged(),
                    enabled: !isSubmitting,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9:]')),
                    ],
                    enableTimePicker: true,
                  ),
                  _AttendanceTimeCard(
                    label: l.endTimeLabel,
                    controller: endTimeController,
                    icon: Icons.stop_rounded,
                    color: const Color(0xFFEF4444),
                    hintText: 'HH:MM',
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                    validator: endTimeValidator,
                    onChanged: (_) => onFieldChanged(),
                    enabled: !isSubmitting,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9:]')),
                    ],
                    enableTimePicker: true,
                  ),
                  _AttendanceTimeCard(
                    label: l.breakLabel,
                    controller: breakMinutesController,
                    icon: Icons.local_cafe_rounded,
                    color: const Color(0xFFF59E0B),
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    textInputAction:
                        showContractFields ? TextInputAction.next : TextInputAction.done,
                    validator: breakValidator,
                    onChanged: (_) => onFieldChanged(),
                    enabled: !isSubmitting,
                    inputFormatters: const [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ];

                if (showContractFields &&
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
                      hintText: '0',
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
                      hintText: '0.00',
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
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l.attendanceSubmitButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
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
              final childAspectRatio = isCompact ? 3.2 : 2.4;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
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
    this.enableTimePicker = false,
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
  final bool enableTimePicker;

  @override
  Widget build(BuildContext context) {
    Future<void> handleTimePicker() async {
      if (!enableTimePicker || !enabled) {
        return;
      }
      FocusScope.of(context).unfocus();
      final initialTime = _tryParseTimeOfDay(controller.text) ?? TimeOfDay.now();
      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        initialEntryMode: TimePickerEntryMode.dial,
        builder: (context, child) {
          if (child == null) {
            return const SizedBox.shrink();
          }
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child,
          );
        },
      );
      if (picked == null) {
        return;
      }
      final formatted = _formatTimeOfDay(picked);
      controller
        ..text = formatted
        ..selection = TextSelection.collapsed(offset: formatted.length);
      onChanged(formatted);
    }

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
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onChanged: onChanged,
            enabled: enabled,
            inputFormatters: inputFormatters,
            readOnly: enableTimePicker,
            onTap: enableTimePicker ? handleTimePicker : null,
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
              suffixIcon: enableTimePicker
                  ? const Icon(
                      Icons.access_time,
                      color: Color(0xFF9CA3AF),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  static TimeOfDay? _tryParseTimeOfDay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final match = RegExp(r'^(\d{1,2})[:](\d{1,2})\s*([aApP][mM])?$').firstMatch(trimmed);
    if (match == null) {
      return null;
    }
    final hours = int.tryParse(match.group(1)!);
    final minutes = int.tryParse(match.group(2)!);
    if (hours == null || minutes == null) {
      return null;
    }
    var normalizedHours = hours;
    final period = match.group(3)?.toLowerCase();
    if (period == 'pm' && normalizedHours < 12) {
      normalizedHours += 12;
    } else if (period == 'am' && normalizedHours == 12) {
      normalizedHours = 0;
    }
    final clampedHours = normalizedHours.clamp(0, 23).toInt();
    final clampedMinutes = minutes.clamp(0, 59).toInt();
    return TimeOfDay(
      hour: clampedHours,
      minute: clampedMinutes,
    );
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({required this.stat});

  final _SummaryStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.title,
            style: TextStyle(
              color: stat.color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: TextStyle(
              color: stat.color,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
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
  });

  final String title;
  final String value;
  final Color color;
}

String _formatMonthYearLabel(DateTime date) {
  const monthNames = <String>[
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
  return '${monthNames[date.month - 1]} ${date.year}';
}

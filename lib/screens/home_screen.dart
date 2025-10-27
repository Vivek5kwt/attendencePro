import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apis/auth_api.dart';
import '../apis/work_api.dart';
import '../bloc/app_cubit.dart';
import '../bloc/work_event.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../bloc/locale_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../models/work.dart';
import '../bloc/work_bloc.dart';
import '../utils/session_manager.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/work_selection_dialog.dart';
import 'help_support_screen.dart';
import 'profile_screen.dart';
import 'reports_summary_screen.dart';
import 'work_detail_screen.dart';
import 'attendance_history_screen.dart';
import 'contract_work_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.openDashboardOnLogin = false}) : super(key: key);

  final bool openDashboardOnLogin;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _workNameController = TextEditingController();
  final TextEditingController _hourlySalaryController = TextEditingController();
  final TextEditingController _editWorkNameController = TextEditingController();
  final TextEditingController _editHourlySalaryController = TextEditingController();
  static const String _shareLink = 'https://attendancepro.app';
  final WorkApi _workApi = WorkApi();
  final SessionManager _sessionManager = const SessionManager();
  List<Work> _works = const <Work>[];
  bool _isLoadingWorks = false;
  String? _worksError;
  bool _shouldOpenDashboard = false;
  bool _hasOpenedDashboard = false;

  @override
  void initState() {
    super.initState();
    _shouldOpenDashboard = widget.openDashboardOnLogin;
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openDashboardOnLogin && !oldWidget.openDashboardOnLogin) {
      _shouldOpenDashboard = true;
      _hasOpenedDashboard = false;
    }
  }

  Future<void> _fetchWorks({bool showSnackBarOnError = false}) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoadingWorks = true;
      _worksError = null;
    });

    final token = await _sessionManager.getToken();
    if (!mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      final message = l.authenticationRequiredMessage;
      setState(() {
        _isLoadingWorks = false;
        _worksError = message;
        _works = const <Work>[];
      });
      if (showSnackBarOnError) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    try {
      final works = await _workApi.fetchWorks(token: token);
      if (!mounted) {
        return;
      }
      setState(() {
        _works = works;
        _worksError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      final message = e.message.isNotEmpty ? e.message : l.worksLoadFailedMessage;
      setState(() {
        _worksError = message;
      });
      if (showSnackBarOnError) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      final message = l.worksLoadFailedMessage;
      setState(() {
        _worksError = message;
      });
      if (showSnackBarOnError) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorks = false;
        });
      }
    }
  }

  Future<void> _handleDashboardTap() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleAddWorkFromDrawer() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _showAddWorkDialog();
  }

  Future<void> _openAttendanceHistory() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AttendanceHistoryScreen(),
      ),
    );
  }

  Future<void> _openContractWork() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ContractWorkScreen(),
      ),
    );
  }

  Future<void> _openContractWorkManagerFromAddDialog(
      BuildContext dialogContext) async {
    FocusScope.of(dialogContext).unfocus();
    await Navigator.of(dialogContext, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => const ContractWorkScreen(),
      ),
    );
  }

  Future<void> _openReportsSummary() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final workState = context.read<WorkBloc>().state;
    final works = workState.works;
    if (works.isEmpty) {
      _showAddWorkDialog();
      return;
    }

    final l = AppLocalizations.of(context);
    Work? activeWork;
    for (final work in works) {
      if (_isWorkActive(work)) {
        activeWork = work;
        break;
      }
    }
    activeWork ??= works.first;

    final selectedWork = await showWorkSelectionDialog(
      context: context,
      works: works,
      localization: l,
      initialSelectedWorkId: activeWork.id,
      onAddNewWork: () {
        if (!mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showAddWorkDialog();
          }
        });
      },
    );
    if (!mounted || selectedWork == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReportsSummaryScreen(
          initialWorkId: selectedWork.id,
        ),
      ),
    );
  }

  Future<void> _openHelpSupport() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const HelpSupportScreen(),
      ),
    );
  }

  Future<void> _refreshWorks() {
    final completer = Completer<void>();
    context.read<WorkBloc>().add(WorkRefreshed(completer: completer));
    return completer.future;
  }

  Future<void> _handleRefresh(WorkState state) {
    if (state.works.isEmpty) {
      return _fetchWorks(showSnackBarOnError: true);
    }
    return _refreshWorks();
  }

  void _openWorkDetail(Work work) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WorkDetailScreen(work: work),
      ),
    );
  }

  void _maybeNavigateToDashboard(WorkState state) {
    if (!_shouldOpenDashboard || _hasOpenedDashboard) {
      return;
    }

    if (state.loadStatus != WorkLoadStatus.success) {
      return;
    }

    final works = state.works;
    if (works.isEmpty) {
      _shouldOpenDashboard = false;
      return;
    }

    final Work targetWork = works.firstWhere(
      (work) => _isWorkActive(work),
      orElse: () => works.first,
    );

    _shouldOpenDashboard = false;
    _hasOpenedDashboard = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppCubit>().showHome();
      _openWorkDetail(targetWork);
    });
  }

  Future<void> _showEditWorkDialog(Work work) async {
    final l = AppLocalizations.of(context);
    final nameController = _editWorkNameController;
    final hourlyController = _editHourlySalaryController;

    nameController
      ..text = work.name
      ..selection = TextSelection.collapsed(offset: work.name.length);
    final hourlyRateText =
    work.hourlyRate != null ? work.hourlyRate!.toString() : '';
    hourlyController
      ..text = hourlyRateText
      ..selection = TextSelection.collapsed(offset: hourlyRateText.length);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        return BlocConsumer<WorkBloc, WorkState>(
          listenWhen: (previous, current) =>
          previous.updateStatus != current.updateStatus,
          listener: (context, state) {
            if (state.updateStatus == WorkActionStatus.success) {
              Navigator.of(dialogContext).pop();
              context
                  .read<WorkBloc>()
                  .add(const WorkUpdateStatusCleared());
            }
          },
          builder: (context, state) {
            final isSaving =
                state.updateStatus == WorkActionStatus.inProgress;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: Text(
                              l.editWorkTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ) ??
                                  const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: isSaving
                                ? null
                                : () {
                              context
                                  .read<WorkBloc>()
                                  .add(const WorkUpdateStatusCleared());
                              Navigator.of(dialogContext).pop();
                            },
                            icon: const Icon(Icons.close),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFE5F1FF),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF007BFF),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l.editWorkSubtitle,
                                    style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ) ??
                                        const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l.workNameLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ) ??
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: l.workNameHint,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF007BFF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l.hourlySalaryLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ) ??
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: hourlyController,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                hintText: l.hourlySalaryHint,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF007BFF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSaving
                                        ? null
                                        : () {
                                      context.read<WorkBloc>().add(
                                          const WorkUpdateStatusCleared());
                                      Navigator.of(dialogContext).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF007BFF),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: Text(
                                      l.cancelButton,
                                      style: const TextStyle(
                                        color: Color(0xFF007BFF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSaving
                                        ? null
                                        : () => _handleUpdateWork(
                                      dialogContext,
                                      l,
                                      work,
                                      nameController,
                                      hourlyController,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF007BFF),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                        : Text(
                                      l.updateWorkButton,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.clear();
    hourlyController.clear();
  }


  void _showChangeWorkMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(l.workA),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.switchedToWorkA)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.work),
                title: Text(l.workB),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.switchedToWorkB)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShareOptions() {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.shareAppTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildShareButton(
                  backgroundColor: const Color(0xFF25D366),
                  icon: Icons.ac_unit_outlined,
                  label: l.shareViaWhatsApp,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _shareViaWhatsApp();
                  },
                ),
                const SizedBox(height: 12),
                _buildShareButton(
                  backgroundColor: const Color(0xFF007AFF),
                  icon: Icons.copy,
                  label: l.copyLink,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _copyShareLink();
                  },
                ),
                const SizedBox(height: 12),
                _buildShareButton(
                  backgroundColor: Colors.black,
                  label: l.shareCancelButton,
                  onTap: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton({
    required Color backgroundColor,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    final l = AppLocalizations.of(context);
    final Uri whatsappUri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(l.shareMessage(_shareLink))}',
    );

    if (!await canLaunchUrl(whatsappUri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.shareWhatsappUnavailable)),
      );
      return;
    }

    final launched = await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.shareWhatsappFailed)),
      );
    }
  }

  Future<void> _copyShareLink() async {
    await Clipboard.setData(const ClipboardData(text: _shareLink));
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.shareLinkCopied)),
    );
  }

  void _showAddWorkDialog() {
    final l = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        return BlocConsumer<WorkBloc, WorkState>(
          listenWhen: (previous, current) =>
          previous.addStatus != current.addStatus,
          listener: (context, state) {
            if (state.addStatus == WorkActionStatus.success) {
              _clearAddWorkForm();
              Navigator.of(dialogContext).pop();
              context.read<WorkBloc>().add(const WorkAddStatusCleared());
            }
          },
          builder: (context, state) {
            final isSaving = state.addStatus == WorkActionStatus.inProgress;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: Text(
                              l.addNewWorkLabel,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _clearAddWorkForm();
                              context
                                  .read<WorkBloc>()
                                  .add(const WorkAddStatusCleared());
                              Navigator.of(dialogContext).pop();
                            },
                            icon: const Icon(Icons.close),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 35,
                                  width: 35,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFE5F1FF),
                                  ),
                                  child:  Image.asset(AppAssets.clock)
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l.hourlyWorkLabel,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l.workNameLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _workNameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: l.workNameHint,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(color: Color(0xFF007BFF)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l.hourlySalaryLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _hourlySalaryController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: l.hourlySalaryHint,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(color: Color(0xFF007BFF)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5EC),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 35,
                                  width: 35,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFE8D6),
                                  ),
                                  child: Image.asset(AppAssets.contract)
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l.contractWorkHeader,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () =>
                                  _openContractWorkManagerFromAddDialog(
                                      dialogContext),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      l.addContractWorkButton,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.contractWorkDescription,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF784600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _clearAddWorkForm();
                                context
                                    .read<WorkBloc>()
                                    .add(const WorkAddStatusCleared());
                                Navigator.of(dialogContext).pop();
                              },

                              style: OutlinedButton.styleFrom(
                                backgroundColor:  Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                l.cancelButton,
                                style: const TextStyle(fontWeight: FontWeight.w600,color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => _handleSaveWork(dialogContext, l),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007BFF),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : Text(
                                l.saveWorkButton,
                                style:
                                const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSaveWork(
      BuildContext dialogContext, AppLocalizations l) async {
    final messenger = ScaffoldMessenger.of(context);
    final workName = _workNameController.text.trim();
    final hourlyRateText = _hourlySalaryController.text.trim();

    if (workName.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.workNameRequiredMessage)),
      );
      return;
    }

    num hourlyRate = 0;
    if (hourlyRateText.isNotEmpty) {
      final parsedRate = double.tryParse(hourlyRateText.replaceAll(',', ''));
      if (parsedRate == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.invalidHourlyRateMessage)),
        );
        return;
      }
      hourlyRate = parsedRate;
    }

    FocusScope.of(dialogContext).unfocus();
    context.read<WorkBloc>().add(
      WorkAdded(name: workName, hourlyRate: hourlyRate, isContract: true),
    );
  }

  Future<void> _handleUpdateWork(
      BuildContext dialogContext,
      AppLocalizations l,
      Work work,
      TextEditingController nameController,
      TextEditingController hourlyController,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final workName = nameController.text.trim();
    final hourlyRateText = hourlyController.text.trim();

    if (workName.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.workNameRequiredMessage)),
      );
      return;
    }

    num hourlyRate = work.hourlyRate ?? 0;
    if (hourlyRateText.isNotEmpty) {
      final parsedRate = double.tryParse(hourlyRateText.replaceAll(',', ''));
      if (parsedRate == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.invalidHourlyRateMessage)),
        );
        return;
      }
      hourlyRate = parsedRate;
    }

    FocusScope.of(dialogContext).unfocus();
    context.read<WorkBloc>().add(
      WorkUpdated(
        work: work,
        name: workName,
        hourlyRate: hourlyRate,
      ),
    );
  }

  void _handleSetActiveWork(Work work) {
    context.read<WorkBloc>().add(WorkActivated(work: work));
  }

  void _clearAddWorkForm() {
    _workNameController.clear();
    _hourlySalaryController.clear();
  }

  Future<bool?> _handleWorkDismiss(Work work, AppLocalizations l) async {
    final bloc = context.read<WorkBloc>();
    if (bloc.state.deletingWorkId != null) {
      return false;
    }

    final shouldDelete = await _showWorkDeleteConfirmationDialog(l);
    if (!shouldDelete) {
      return false;
    }

    final completer = Completer<bool>();
    bloc.add(WorkDeleted(work: work, completer: completer));

    return completer.future;
  }

  Future<bool> _showWorkDeleteConfirmationDialog(AppLocalizations l) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.workDeleteConfirmationTitle),
          content: Text(l.workDeleteConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.workDeleteCancelButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.workDeleteConfirmButton),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _onDrawerOptionSelected(String option) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(option)));
  }

  Future<void> _handleLogoutTap(AppLocalizations l) async {
    Navigator.of(context).pop();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final shouldLogout = await _showLogoutConfirmationDialog(l);
    if (!shouldLogout || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<AppCubit>().logout();
    if (!mounted) return;
    final message = success ? l.logoutSuccessMessage : l.logoutFailedMessage;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showLogoutConfirmationDialog(AppLocalizations l) {
    return showCreativeLogoutDialog(context, l);
  }

  Future<void> _handleDeleteAccountTap(AppLocalizations l) async {
    Navigator.of(context).pop();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final shouldDelete = await _showDeleteAccountConfirmationDialog(l);
    if (!shouldDelete || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<AppCubit>().deleteAccount();
    if (!mounted) return;
    final message = success
        ? l.deleteAccountSuccessMessage
        : l.deleteAccountFailedMessage;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showDeleteAccountConfirmationDialog(AppLocalizations l) {
    return showCreativeDeleteAccountDialog(context, l);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkBloc, WorkState>(
      listenWhen: (previous, current) =>
      previous.lastErrorMessage != current.lastErrorMessage ||
          previous.lastSuccessMessage != current.lastSuccessMessage ||
          previous.requiresAuthentication != current.requiresAuthentication ||
          previous.feedbackKind != current.feedbackKind,
      listener: (context, state) {
        final l = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        String? message;

        if (state.requiresAuthentication) {
          message = l.authenticationRequiredMessage;
        } else if (state.lastErrorMessage != null &&
            state.lastErrorMessage!.isNotEmpty) {
          message = state.lastErrorMessage;
        } else if (state.lastSuccessMessage != null) {
          if (state.lastSuccessMessage!.isNotEmpty) {
            message = state.lastSuccessMessage;
          } else {
            message = _successFallback(state.feedbackKind, l);
          }
        }

        if (message != null && message.isNotEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: BlocBuilder<WorkBloc, WorkState>(
        builder: (context, state) {
          final l = AppLocalizations.of(context);
          const languageOptions = <String, String>{
            'en': 'English',
            'hi': 'Hindi',
            'pa': 'Punjabi',
            'it': 'Italian',
          };
          final userName = state.userName ?? l.drawerUserName;
          final userContact = state.userEmail ??
              state.userPhone ??
              state.userUsername ??
              l.drawerUserPhone;
          final menuItems = <_DrawerMenuItem>[
            _DrawerMenuItem(
              assetPath: AppAssets.home,
              label: l.dashboardLabel,
              backgroundColor: const Color(0xFFE6F3FF),
              iconColor: const Color(0xFF1C87FF),
              onTap: _handleDashboardTap,
            ),
            _DrawerMenuItem(
              assetPath: AppAssets.addNewWork,
              label: l.addNewWorkLabel,
              backgroundColor: const Color(0xFFE8F8F0),
              iconColor: const Color(0xFF2EBD5F),
              onTap: _handleAddWorkFromDrawer,
            ),
            _DrawerMenuItem(
              assetPath: AppAssets.history,
              label: l.attendanceHistoryLabel,
              backgroundColor: const Color(0xFFFFF2F2),
              iconColor: const Color(0xFFFF3B30),
              onTap: _openAttendanceHistory,
            ),
            _DrawerMenuItem(
              assetPath: AppAssets.contractWork,
              label: l.contractWorkLabel,
              backgroundColor: const Color(0xFFEDEBFF),
              iconColor: const Color(0xFF5856D6),
              onTap: _openContractWork,
            ),
            _DrawerMenuItem(
              icon: Icons.person_outline,
              label: l.profileLabel,
              backgroundColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              onTap: () async {
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 200));
                if (!mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _DrawerMenuItem(
              assetPath: AppAssets.reports,
              label: l.reportsSummaryLabel,
              backgroundColor: const Color(0xFFE6F0FF),
              iconColor: const Color(0xFF2563EB),
              onTap: _openReportsSummary,
            ),
            _DrawerMenuItem(
              assetPath: AppAssets.changeLanguage,
              label: l.changeLanguageLabel,
              backgroundColor: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFFAF52DE),
              onTap: () async {
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 200));
                if (!mounted) return;
                await _showLanguageDialog(context, languageOptions, l);
              },
            ),
            _DrawerMenuItem(
              assetPath: AppAssets.helpSupport,
              label: l.helpSupportLabel,
              backgroundColor: const Color(0xFFE6F3FF),
              iconColor: const Color(0xFF007AFF),
              onTap: _openHelpSupport,
            ),
            _DrawerMenuItem(
              icon: Icons.delete_outline,
              label: l.deleteAccountLabel,
              backgroundColor: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFFF3B30),
              onTap: () => _handleDeleteAccountTap(l),
            ),
            _DrawerMenuItem(
              assetPath: AppAssets.logout,
              label: l.logoutLabel,
              backgroundColor: const Color(0xFFE6F3FF),
              iconColor: const Color(0xFF007AFF),
              onTap: () => _handleLogoutTap(l),
            ),
          ];
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, color: Colors.grey),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              title: Text(
                l.appTitle,
                style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w500),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.language, color: Colors.grey),
                  onPressed: () {
                    _showLanguageDialog(context, languageOptions, l);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.grey),
                  onPressed: _showShareOptions,
                ),
              ],
            ),
            drawer: Drawer(
              width: MediaQuery.of(context).size.width * 0.78,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DrawerHeader(
                      userName: userName,
                      userEmail: userContact,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: menuItems.length,
                          itemBuilder: (context, index) =>
                              _drawerItem(menuItems[index]),
                          separatorBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: _DashedDivider(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            body: _buildHomeBody(l, state),
          );
        },
      ),
    );
  }

  Widget _buildHomeBanner(AppLocalizations l) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 190,

        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  AppAssets.bgBanner,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 28,
              right: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.homeBannerTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.homeBannerSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      height: 1.4,
                    ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  AppAssets.homeBanner,
                  fit: BoxFit.contain,
                  height: 220,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHomeBody(AppLocalizations l, WorkState state) {
    _maybeNavigateToDashboard(state);
    final works = state.works;
    final isActivationInProgress =
        state.activateStatus == WorkActionStatus.inProgress;
    final activatingWorkId = state.activatingWorkId;
    if (state.isLoading && works.isEmpty) {
      return _buildRefreshableList(
        l,
        state,
        children: const [
          SizedBox(height: 16),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 24),
        ],
      );
    }

    if (state.loadStatus == WorkLoadStatus.failure && works.isEmpty) {
      final message = state.requiresAuthentication
          ? l.authenticationRequiredMessage
          : (state.lastErrorMessage != null &&
                  state.lastErrorMessage!.isNotEmpty
              ? state.lastErrorMessage!
              : l.worksLoadFailedMessage);
      return _buildRefreshableList(
        l,
        state,
        children: [
          const SizedBox(height: 24),
          _buildWorksErrorContent(l, message),
          const SizedBox(height: 24),
        ],
        onRefresh: _refreshWorks,
      );
    }

    if (works.isEmpty) {
      return _buildRefreshableList(
        l,
        state,
        onRefresh: () => _fetchWorks(showSnackBarOnError: true),
        children: [
          const SizedBox(height: 12),
          _buildWorksEmptyContent(l),
          const SizedBox(height: 24),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(state),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: works.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHomeBanner(l);
          }
          final work = works[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildWorkCard(
              work,
              l,
              isDeleting: state.deletingWorkId == work.id,
              isActivating:
                  activatingWorkId == work.id && isActivationInProgress,
              activationInProgress: isActivationInProgress,
            ),
          );
        },
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? 24 : 12),
      ),
    );
  }

  Widget _buildRefreshableList(
    AppLocalizations l,
    WorkState state, {
    required List<Widget> children,
    Future<void> Function()? onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () => _handleRefresh(state),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildHomeBanner(l),
          ...children,
        ],
      ),
    );
  }

  Widget _buildWorksEmptyContent(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.workPlaceholder, width: 100),
            const SizedBox(height: 12),
            Text(
              l.noWorkAddedYet,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                l.startTrackingAttendance,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                onPressed: _showAddWorkDialog,
                child: Text(
                  l.addYourFirstWork,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildWorksErrorContent(AppLocalizations l, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 64),
            const SizedBox(height: 16),
            Text(
              l.worksLoadFailedTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: OutlinedButton(
                onPressed: () {
                  _refreshWorks();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  l.retryButtonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkCard(
      Work work,
      AppLocalizations l, {
        required bool isDeleting,
        required bool isActivating,
        required bool activationInProgress,
      }) {
    final isActive = _isWorkActive(work);
    final disableActivateButton =
        isDeleting || (activationInProgress && !isActivating) || isActive;

    final card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap:
        (isDeleting || isActivating) ? null : () => _openWorkDetail(work),
        onLongPress:
        (isDeleting || isActivating) ? null : () => _showEditWorkDialog(work),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
              isActive ? const Color(0xFF34D399) : Colors.transparent,
              width: isActive ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFECFDF3)
                      : const Color(0xFFE5F1FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isActive ? Icons.workspace_premium_outlined : Icons.work_outline,
                  color:
                  isActive ? const Color(0xFF16A34A) : const Color(0xFF007BFF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ) ??
                          const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatHourlyRate(work, l),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4F5B67),
                      ) ??
                          const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4F5B67),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: work.isContract
                          ? const Color(0xFFFFF5EC)
                          : const Color(0xFFE5F6FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      work.isContract
                          ? l.contractWorkLabel
                          : l.hourlyWorkLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    ),
                    child: isActive
                        ? Container(
                      key: const ValueKey('active-label'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF22C55E),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.activeWorkLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    )
                        : SizedBox(
                      key: const ValueKey('activate-button'),
                      height: 36,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                          backgroundColor: const Color(0xFFEFF5FF),
                          foregroundColor: const Color(0xFF0052CC),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: disableActivateButton
                            ? null
                            : () => _handleSetActiveWork(work),
                        child: isActivating
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0052CC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(l.settingActiveWorkLabel),
                          ],
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(l.setActiveWorkButton),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: (isDeleting || isActivating)
                        ? null
                        : () => _showEditWorkDialog(work),
                    icon: const Icon(Icons.edit, color: Color(0xFF007BFF)),
                    splashRadius: 20,
                    tooltip: l.editWorkTooltip,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey(work.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) {
        if (isActivating) {
          return Future<bool>.value(false);
        }
        return _handleWorkDismiss(work, l);
      },
      background: const SizedBox.shrink(),
      secondaryBackground: _buildDeleteBackground(l),
      child: Stack(
        children: [
          card,
          if (isDeleting)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground(AppLocalizations l) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: const Color(0xFFFF3B30),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              l.workDeleteConfirmButton,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

    bool? _resolve(dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized.isEmpty) return null;
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
      if (value == null) continue;
      final resolved = _resolve(value);
      if (resolved != null) {
        return resolved;
      }
    }

    return false;
  }

  String _formatHourlyRate(Work work, AppLocalizations l) {
    final rate = work.hourlyRate;
    if (rate == null) {
      return '${l.hourlySalaryLabel}: ${l.notAvailableLabel}';
    }

    final double doubleValue = rate.toDouble();
    final bool isWhole = doubleValue.roundToDouble() == doubleValue;
    final formatted = isWhole
        ? doubleValue.toStringAsFixed(0)
        : doubleValue.toStringAsFixed(2);

    return '${l.hourlySalaryLabel}: $formatted';
  }

  String? _successFallback(WorkFeedbackKind? kind, AppLocalizations l) {
    switch (kind) {
      case WorkFeedbackKind.add:
        return l.workAddedMessage;
      case WorkFeedbackKind.update:
        return l.workUpdatedMessage;
      case WorkFeedbackKind.delete:
        return l.workDeleteSuccessMessage;
      case WorkFeedbackKind.activate:
        return l.workActivatedMessage;
      default:
        return null;
    }
  }

  Widget _drawerItem(_DrawerMenuItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: item.assetPath != null
                    ? Image.asset(
                        item.assetPath!,
                        width: 24,
                        height: 24,
                      )
                    : Icon(
                        item.icon!,
                        color: item.iconColor,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2933),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFB0BEC5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context,
      Map<String, String> options, AppLocalizations l) async {
    final currentCode = context.read<LocaleCubit>().state.languageCode;
    final selectedCode = await showCreativeLanguageDialog(
      context,
      options: options,
      currentSelection: currentCode,
      localizations: l,
    );

    if (selectedCode != null && options.containsKey(selectedCode)) {
      context.read<LocaleCubit>().setLocale(Locale(selectedCode));
      final updatedLocalization = AppLocalizations(Locale(selectedCode));
      final label = options[selectedCode] ?? selectedCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updatedLocalization.languageSelection(label))),
      );
    }
  }

  @override
  void dispose() {
    _workNameController.dispose();
    _hourlySalaryController.dispose();
    _editWorkNameController.dispose();
    _editHourlySalaryController.dispose();
    super.dispose();
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.userName, required this.userEmail});

  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    final fallbackInitial = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : '?';

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _DrawerHeaderClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0084FF), Color(0xFF0057FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.85),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.asset(
                        AppAssets.profilePlaceholder,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF0084FF),
                          alignment: Alignment.center,
                          child: Text(
                            fallbackInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ) ??
                            TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
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
    );
  }
}

class _DrawerHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 10,
      size.width * 0.55,
      size.height - 36,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height - 58,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          var dashCount =
          (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          if (dashCount <= 0) {
            dashCount = 1;
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
                  (_) => Container(
                width: dashWidth,
                height: 1,
                color: const Color(0xFFE0E6ED),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DrawerMenuItem {
  const _DrawerMenuItem({
    this.icon,
    this.assetPath,
    required this.label,
    required this.backgroundColor,
    this.iconColor,
    required this.onTap,
  }) : assert(icon != null || assetPath != null,
            'Either icon or assetPath must be provided.'),
        assert(icon == null || assetPath == null,
            'Provide only one of icon or assetPath.');

  final IconData? icon;
  final String? assetPath;
  final String label;
  final Color backgroundColor;
  final Color? iconColor;
  final VoidCallback onTap;
}


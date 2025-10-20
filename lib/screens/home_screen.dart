import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apis/auth_api.dart' show ApiException;
import '../apis/work_api.dart';
import '../bloc/app_cubit.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../core/constants/app_assets.dart';
import '../bloc/locale_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../models/student.dart';
import '../widgets/student_tile.dart';
import '../utils/session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _workNameController = TextEditingController();
  final TextEditingController _hourlySalaryController = TextEditingController();
  final WorkApi _workApi = WorkApi();
  static const String _shareLink = 'https://attendancepro.app';
  final SessionManager _sessionManager = const SessionManager();

  String? _userName;
  String? _userEmail;
  bool _isSavingWork = false;

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(LoadStudents());
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final details = await _sessionManager.getUserDetails();

    if (!mounted) return;

    String? _normalize(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    setState(() {
      _userName = _normalize(details['name']);
      final email = _normalize(details['email']);
      final username = _normalize(details['username']);
      _userEmail = email ?? username;
    });
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
                              height: 50,
                              width: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE5F1FF),
                              ),
                              child: const Icon(
                                Icons.access_time,
                                color: Color(0xFF007BFF),
                                size: 28,
                              ),
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
                              height: 50,
                              width: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFE8D6),
                              ),
                              child: const Icon(
                                Icons.work_outline,
                                color: Color(0xFFB15B00),
                                size: 28,
                              ),
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
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.contractWorkTappedMessage)),
                            );
                          },
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
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            l.cancelButton,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSavingWork
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
                          child: _isSavingWork
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

    setState(() {
      _isSavingWork = true;
    });

    try {
      final response = await _workApi.createWork(
        name: workName,
        hourlyRate: hourlyRate,
        isContract: true,
      );
      if (!mounted) return;
      final message = _extractWorkMessage(response) ?? l.workAddedMessage;
      context.read<AttendanceBloc>().add(AddStudent(workName));
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
      _clearAddWorkForm();
      Navigator.of(dialogContext).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l.workSaveFailedMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingWork = false;
        });
      }
    }
  }

  void _clearAddWorkForm() {
    _workNameController.clear();
    _hourlySalaryController.clear();
  }

  String? _extractWorkMessage(Map<String, dynamic> response) {
    const possibleKeys = ['message', 'status', 'detail'];
    for (final key in possibleKeys) {
      final value = response[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  void _onDrawerOptionSelected(String option) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(option)));
  }

  Future<void> _handleLogoutTap(AppLocalizations l) async {
    Navigator.of(context).pop();

    // Give the drawer a moment to close before showing the dialog.
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final shouldLogout = await _showLogoutConfirmationDialog(l);
    if (!shouldLogout || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<AppCubit>().logout();
    if (!mounted) return;
    setState(() {
      _userName = null;
      _userEmail = null;
    });
    final message = success ? l.logoutSuccessMessage : l.logoutFailedMessage;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showLogoutConfirmationDialog(AppLocalizations l) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.logoutConfirmationTitle),
          content: Text(l.logoutConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.logoutCancelButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.logoutConfirmButton),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final languageOptions = {
      'en': l.languageEnglish,
      'hi': l.languageHindi,
      'pa': l.languagePunjabi,
      'it': l.languageItalian,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor:  Colors.transparent,
        elevation: 0,
        // Use a Builder here so the IconButton has a context that is a descendant of the Scaffold.
        // Calling Scaffold.of(context).openDrawer() with the AppBar's own context won't find the Scaffold.
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
          style: const TextStyle(color: Colors.black),
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
        child: SafeArea(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A84FF),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 20,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundImage: AssetImage(AppAssets.profilePlaceholder),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName ?? l.drawerUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail ?? l.drawerUserPhone,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _drawerItem(
                      icon: Icons.home_outlined,
                      label: l.dashboardLabel,
                      bgColor: const Color(0xFFE5F6FE),
                      iconColor: const Color(0xFF48A9FF),
                      onTap: () =>
                          _onDrawerOptionSelected(l.dashboardTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.work_outline,
                      label: l.addNewWorkLabel,
                      bgColor: const Color(0xFFE8F8F0),
                      iconColor: const Color(0xFF34C759),
                      onTap: () =>
                          _onDrawerOptionSelected(l.addNewWorkTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.access_time,
                      label: l.attendanceHistoryLabel,
                      bgColor: const Color(0xFFFFF2F2),
                      iconColor: const Color(0xFFFF3B30),
                      onTap: () =>
                          _onDrawerOptionSelected(l.attendanceHistoryTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.assignment_outlined,
                      label: l.contractWorkLabel,
                      bgColor: const Color(0xFFEDEBFF),
                      iconColor: const Color(0xFF5856D6),
                      onTap: () =>
                          _onDrawerOptionSelected(l.contractWorkTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.language,
                      label: l.changeLanguageLabel,
                      bgColor: const Color(0xFFF8E8FA),
                      iconColor: const Color(0xFFAF52DE),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _showLanguageDialog(context, languageOptions, l);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.support_agent_outlined,
                      label: l.helpSupportLabel,
                      bgColor: const Color(0xFFE5F6FE),
                      iconColor: const Color(0xFF007AFF),
                      onTap: () =>
                          _onDrawerOptionSelected(l.helpSupportTappedMessage),
                    ),
                    _drawerItem(
                      icon: Icons.logout,
                      label: l.logoutLabel,
                      bgColor: const Color(0xFFE5F6FE),
                      iconColor: const Color(0xFF007AFF),
                      onTap: () => _handleLogoutTap(l),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Image.asset(AppAssets.homeBanner, width: 330),

          Expanded(
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                if (state is AttendanceLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AttendanceLoaded) {
                  // Fix: show placeholder when the list is empty; show the list when not empty.
                  if (state.students.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(AppAssets.workPlaceholder, width: 100),
                            const SizedBox(height: 12),
                            Text(
                              l.noWorkAddedYet,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
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
                                  onPressed: () {
                                    _showAddWorkDialog();
                                  },
                                  child: Text(
                                    l.addYourFirstWork,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: state.students.length,
                      itemBuilder: (context, index) {
                        final Student s = state.students[index];
                        return StudentTile(
                          student: s,
                          onToggle: () =>
                              context.read<AttendanceBloc>().add(ToggleAttendance(s.id)),
                        );
                      },
                    );
                  }
                } else if (state is AttendanceError) {
                  return Center(child: Text(state.message));
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(label, style: const TextStyle(fontSize: 16)),
          onTap: onTap,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            color: Color(0xFFE0E0E0),
            thickness: 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }

  Future<void> _showLanguageDialog(BuildContext context,
      Map<String, String> options, AppLocalizations l) async {
    final selectedCode = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text(l.selectLanguageTitle),
          children: options.entries
              .map(
                (entry) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, entry.key),
                  child: Text(entry.value),
                ),
              )
              .toList(),
        );
      },
    );

    if (selectedCode != null && options.containsKey(selectedCode)) {
      context.read<LocaleCubit>().setLocale(Locale(selectedCode));
      final updatedLocalization = AppLocalizations(Locale(selectedCode));
      final updatedNames = {
        'en': updatedLocalization.languageEnglish,
        'hi': updatedLocalization.languageHindi,
        'pa': updatedLocalization.languagePunjabi,
        'it': updatedLocalization.languageItalian,
      };
      final label = updatedNames[selectedCode] ?? options[selectedCode] ?? selectedCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updatedLocalization.languageSelection(label))),
      );
    }
  }

  @override
  void dispose() {
    _workNameController.dispose();
    _hourlySalaryController.dispose();
    super.dispose();
  }
}

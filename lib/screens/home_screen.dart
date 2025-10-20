import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/app_cubit.dart';
import '../core/constants/app_assets.dart';
import '../bloc/locale_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../models/work.dart';
import '../bloc/work_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _workNameController = TextEditingController();
  final TextEditingController _hourlySalaryController = TextEditingController();
  static const String _shareLink = 'https://attendancepro.app';

  Future<void> _handleAddWorkFromDrawer() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _showAddWorkDialog();
  }

  Future<void> _refreshWorks() {
    final completer = Completer<void>();
    context.read<WorkBloc>().add(WorkRefreshed(completer: completer));
    return completer.future;
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
                            context
                                .read<WorkBloc>()
                                .add(const WorkAddStatusCleared());
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

    // Give the drawer a moment to close before showing the dialog.
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
          final languageOptions = {
            'en': l.languageEnglish,
            'hi': l.languageHindi,
            'pa': l.languagePunjabi,
            'it': l.languageItalian,
          };
          final userName = state.userName ?? l.drawerUserName;
          final userEmail = state.userEmail ?? l.drawerUserPhone;

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
                                backgroundImage:
                                    AssetImage(AppAssets.profilePlaceholder),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userEmail,
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
                            onTap: _handleAddWorkFromDrawer,
                          ),
                          _drawerItem(
                            icon: Icons.access_time,
                            label: l.attendanceHistoryLabel,
                            bgColor: const Color(0xFFFFF2F2),
                            iconColor: const Color(0xFFFF3B30),
                            onTap: () => _onDrawerOptionSelected(
                                l.attendanceHistoryTappedMessage),
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
                              await _showLanguageDialog(
                                  context, languageOptions, l);
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
                Expanded(child: _buildWorksContent(l, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorksContent(AppLocalizations l, WorkState state) {
    final works = state.works;
    if (state.isLoading && works.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadStatus == WorkLoadStatus.failure && works.isEmpty) {
      final message = state.requiresAuthentication
          ? l.authenticationRequiredMessage
          : (state.lastErrorMessage != null &&
                  state.lastErrorMessage!.isNotEmpty
              ? state.lastErrorMessage!
              : l.worksLoadFailedMessage);
      return _buildWorksErrorState(l, message);
    }

    if (works.isEmpty) {
      return _buildWorksEmptyState(l);
    }

    return RefreshIndicator(
      onRefresh: _refreshWorks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: works.length,
        itemBuilder: (context, index) => _buildWorkCard(
          works[index],
          l,
          isDeleting: state.deletingWorkId == works[index].id,
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
      ),
    );
  }

  Widget _buildWorksEmptyState(AppLocalizations l) {
    return RefreshIndicator(
      onRefresh: () => _fetchWorks(showSnackBarOnError: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      ),
    );
  }

  Widget _buildWorksErrorState(AppLocalizations l, String message) {
    return RefreshIndicator(
      onRefresh: _refreshWorks,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      ),
    );
  }

  Widget _buildWorkCard(Work work, AppLocalizations l,
      {required bool isDeleting}) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              color: const Color(0xFFE5F1FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.work_outline,
              color: Color(0xFF007BFF),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: work.isContract
                  ? const Color(0xFFFFF5EC)
                  : const Color(0xFFE5F6FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              work.isContract ? l.contractWorkLabel : l.hourlyWorkLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey(work.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _handleWorkDismiss(work, l),
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
      case WorkFeedbackKind.delete:
        return l.workDeleteSuccessMessage;
      default:
        return null;
    }
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
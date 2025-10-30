import 'dart:async';
import 'dart:math' as math;

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
import '../utils/responsive.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/work_management_dialogs.dart';
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
  static const String _shareLink = 'https://attendancepro.app';
  final WorkApi _workApi = WorkApi();
  final SessionManager _sessionManager = const SessionManager();
  List<Work> _works = const <Work>[];
  bool _isLoadingWorks = false;
  String? _worksError;
  bool _shouldOpenDashboard = false;
  bool _hasOpenedDashboard = false;
  bool _hasTriggeredAutoActivation = false;

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
      _hasTriggeredAutoActivation = false;
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
      onEditWork: (work) {
        if (!mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showEditWorkDialog(work);
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

  void _showAddWorkDialog() {
    showAddWorkDialog(context: context);
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
    if (_hasOpenedDashboard) {
      return;
    }

    final works = state.works;
    if (works.isEmpty) {
      _hasTriggeredAutoActivation = false;
      return;
    }

    final bool hasSingleWork = works.length == 1;
    Work? activeWork;
    for (final work in works) {
      if (_isWorkActive(work)) {
        activeWork = work;
        break;
      }
    }

    final bool hasActiveWork = activeWork != null;

    if (!hasActiveWork) {
      final targetWork = _findMostRecentWork(works);
      if (targetWork == null) {
        _hasTriggeredAutoActivation = false;
        return;
      }

      if (state.activateStatus == WorkActionStatus.failure &&
          _hasTriggeredAutoActivation) {
        _hasTriggeredAutoActivation = false;
      }

      if (_hasTriggeredAutoActivation ||
          state.activateStatus == WorkActionStatus.inProgress) {
        return;
      }

      _hasTriggeredAutoActivation = true;
      context.read<WorkBloc>().add(WorkActivated(work: targetWork));
      return;
    }

    _hasTriggeredAutoActivation = false;

    if (hasSingleWork) {
      _shouldOpenDashboard = true;
    }

    if (!_shouldOpenDashboard) {
      return;
    }

    _shouldOpenDashboard = false;
    _hasOpenedDashboard = true;

    final targetWork = activeWork!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppCubit>().showHome();
      _openWorkDetail(targetWork);
    });
  }

  Future<void> _showEditWorkDialog(Work work) async {
    await showEditWorkDialog(context: context, work: work);
  }

  void _handleSetActiveWork(Work work) {
    context.read<WorkBloc>().add(WorkActivated(work: work));
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

  Future<void> _handleDeleteWorkTap(Work work, AppLocalizations l) async {
    await _handleWorkDismiss(work, l);
  }

  Future<bool> _showWorkDeleteConfirmationDialog(AppLocalizations l) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1FDC2626),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Color(0xFFB91C1C),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.workDeleteConfirmationTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                                  const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.workDeleteConfirmationMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                                height: 1.5,
                              ) ??
                                  const TextStyle(
                                    color: Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFF97316),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l.workDeleteIrreversibleMessage,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9A3412),
                              height: 1.4,
                            ) ??
                                const TextStyle(
                                  color: Color(0xFF9A3412),
                                  height: 1.4,
                                ),
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
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            l.workDeleteCancelButton,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB91C1C),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            l.workDeleteConfirmButton,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ) ??
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
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
    context.read<WorkBloc>().add(const WorkCleared());
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
    if (success) {
      context.read<WorkBloc>().add(const WorkCleared());
    }
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
              titleSpacing: 5,
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: Image.asset(
                      AppAssets.icDrawer,
                      width: 24,
                      height: 24,
                    ),
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
                  icon: Image.asset(
                    AppAssets.language,
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    _showLanguageDialog(context, languageOptions, l);
                  },
                ),
                IconButton(
                  icon: Image.asset(
                    AppAssets.icShare,
                    width: 24,
                    height: 24,
                  ),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: works.length,
        itemBuilder: (context, index) {
          final work = works[index];
          return _buildWorkCard(
            work,
            l,
            isDeleting: state.deletingWorkId == work.id,
            isActivating:
                activatingWorkId == work.id && isActivationInProgress,
            activationInProgress: isActivationInProgress,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SizedBox(height: 8),
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = _resolveWorkDescription(work);
    final accentColor = work.isContract
        ? colorScheme.tertiary
        : colorScheme.primary;
    final accentContainerColor = work.isContract
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final accentOnContainerColor = work.isContract
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;
    final gradient = LinearGradient(
      colors: [
        Color.alphaBlend(accentContainerColor.withOpacity(0.8), colorScheme.surface),
        accentContainerColor.withOpacity(0.4),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      elevation: 0,
      child: InkWell(
        onTap: (isDeleting || isActivating)
            ? null
            : () => _openWorkDetail(work),
        onLongPress: (isDeleting || isActivating)
            ? null
            : () => _showEditWorkDialog(work),
        borderRadius: BorderRadius.circular(28),
        splashFactory: NoSplash.splashFactory,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(MaterialState.pressed)) {
              return accentColor.withOpacity(0.12);
            }
            return Colors.transparent;
          },
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(2.4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF34D399)
                    : accentColor.withOpacity(0.18),
                width: isActive ? 1.5 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 520;
                  final disableActions = isDeleting || isActivating;

                  Widget buildActionColumn({required bool alignStart}) {
                    final alignment =
                    alignStart ? Alignment.centerLeft : Alignment.centerRight;
                    final wrapAlignment =
                    alignStart ? WrapAlignment.start : WrapAlignment.end;

                    return Column(
                      crossAxisAlignment: alignStart
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Align(
                          alignment: alignment,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: work.isContract
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFFFFEDD5),
                                  Color(0xFFFFF7ED),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : const LinearGradient(
                                colors: [
                                  Color(0xFFDCEBFF),
                                  Color(0xFFEFF6FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: accentColor.withOpacity(0.16),
                              ),
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
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: alignment,
                          child: AnimatedSwitcher(
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
                              key: const ValueKey('active-badge'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  backgroundColor: accentColor.withOpacity(0.08),
                                  foregroundColor: accentColor,
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
                                    SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          accentColor,
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
                                    Icon(Icons.bolt_rounded,
                                        size: 18, color: accentColor),
                                    const SizedBox(width: 6),
                                    Text(l.setActiveWorkButton),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: alignment,
                          child: Wrap(
                            alignment: wrapAlignment,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                height: 36,
                                child: FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accentColor.withOpacity(0.08),
                                    foregroundColor: accentColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed: disableActions
                                      ? null
                                      : () => _showEditWorkDialog(work),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: Text(l.editWorkTooltip),
                                ),
                              ),
                              SizedBox(
                                height: 36,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    backgroundColor: const Color(0xFFFFE8E6),
                                    foregroundColor: const Color(0xFFB42318),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed: disableActions
                                      ? null
                                      : () => _handleDeleteWorkTap(work, l),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: Text(l.workDeleteConfirmButton),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final Widget actionSection = isCompact
                      ? buildActionColumn(alignStart: true)
                      : SizedBox(width: 220, child: buildActionColumn(alignStart: false));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 54,
                            width: 54,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              isActive
                                  ? Icons.workspace_premium_outlined
                                  : Icons.work_outline,
                              color: isActive
                                  ? const Color(0xFF16A34A)
                                  : accentColor,
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
                                    fontSize: 20,
                                  ) ??
                                      const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.alphaBlend(
                                      accentContainerColor.withOpacity(0.18),
                                      colorScheme.surface,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: accentColor.withOpacity(0.14),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 36,
                                        width: 36,
                                        decoration: BoxDecoration(
                                          color: accentContainerColor,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: accentColor.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.payments_outlined,
                                          color: accentOnContainerColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l.hourlySalaryLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelLarge?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ) ??
                                                  TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatHourlyRate(work, l),
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: accentColor,
                                                fontWeight: FontWeight.w700,
                                              ) ??
                                                  TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: accentColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (description != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    description,
                                    maxLines: isCompact ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: const Color(0xFF6B7280),
                                      height: 1.4,
                                    ) ??
                                        const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280),
                                          height: 1.4,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 12),
                            actionSection,
                          ],
                        ],
                      ),
                      if (isCompact) ...[
                        const SizedBox(height: 16),
                        actionSection,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ));

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

  Work? _findMostRecentWork(List<Work> works) {
    if (works.isEmpty) {
      return null;
    }

    Work? candidate;
    DateTime? candidateTimestamp;

    for (final work in works) {
      final timestamp = _extractWorkTimestamp(work);
      if (timestamp == null) {
        continue;
      }

      if (candidateTimestamp == null || timestamp.isAfter(candidateTimestamp)) {
        candidate = work;
        candidateTimestamp = timestamp;
      }
    }

    return candidate ?? works.last;
  }

  DateTime? _extractWorkTimestamp(Work work) {
    final data = work.additionalData;
    const creationKeys = [
      'created_at',
      'createdAt',
      'created_on',
      'createdOn',
      'created_date',
      'createdDate',
      'created',
    ];
    const updateKeys = [
      'updated_at',
      'updatedAt',
      'updated_on',
      'updatedOn',
      'updated',
      'last_modified',
      'lastModified',
    ];

    for (final key in creationKeys) {
      final parsed = _parseWorkTimestamp(data[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    for (final key in updateKeys) {
      final parsed = _parseWorkTimestamp(data[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  DateTime? _parseWorkTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return parsed;
      }

      final normalized = trimmed.replaceAll('/', '-');
      if (normalized != trimmed) {
        final normalizedParsed = DateTime.tryParse(normalized);
        if (normalizedParsed != null) {
          return normalizedParsed;
        }
      }

      final numeric = int.tryParse(trimmed);
      if (numeric != null) {
        return _parseNumericTimestamp(numeric);
      }
    }

    if (value is num) {
      return _parseNumericTimestamp(value.toInt());
    }

    return null;
  }

  DateTime? _parseNumericTimestamp(int value) {
    if (value <= 0) {
      return null;
    }

    if (value > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }

    if (value > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
          .toLocal();
    }

    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
  }

  String? _resolveWorkDescription(Work work) {
    final data = work.additionalData;
    const possibleKeys = ['description', 'details', 'summary', 'note', 'notes'];

    for (final key in possibleKeys) {
      final value = data[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return null;
  }

  String _formatHourlyRate(Work work, AppLocalizations l) {
    final rate = work.hourlyRate;
    if (rate == null) {
      return l.notAvailableLabel;
    }

    final double doubleValue = rate.toDouble();
    final bool isWhole = doubleValue.roundToDouble() == doubleValue;
    final formatted = isWhole
        ? doubleValue.toStringAsFixed(0)
        : doubleValue.toStringAsFixed(2);

    return formatted;
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
      splashFactory: NoSplash.splashFactory,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(MaterialState.pressed)) {
            return item.backgroundColor.withOpacity(0.16);
          }
          return Colors.transparent;
        },
      ),
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

  Future<void> _showShareOptions() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        Future<void> shareViaWhatsApp() async {
          Navigator.of(sheetContext).pop();
          final message = l.shareMessage(_shareLink);
          final uri = Uri.parse(
            'whatsapp://send?text=${Uri.encodeComponent(message)}',
          );

          try {
            final canLaunch = await canLaunchUrl(uri);
            if (!canLaunch) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text(l.shareWhatsappUnavailable)),
              );
              return;
            }

            final launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (!launched && mounted) {
              messenger.showSnackBar(
                SnackBar(content: Text(l.shareWhatsappFailed)),
              );
            }
          } catch (_) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text(l.shareWhatsappFailed)),
            );
          }
        }

        Future<void> copyLink() async {
          Navigator.of(sheetContext).pop();
          await Clipboard.setData(ClipboardData(text: _shareLink));
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text(l.shareLinkCopied)),
          );
        }

        Widget shareOption({
          required IconData icon,
          required Color iconColor,
          required Color backgroundColor,
          required String label,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.shareAppTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 20),
                shareOption(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF25D366),
                  backgroundColor: const Color(0xFFE7F8EF),
                  label: l.shareViaWhatsApp,
                  onTap: shareViaWhatsApp,
                ),
                const SizedBox(height: 8),
                shareOption(
                  icon: Icons.link_rounded,
                  iconColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFE8EEFF),
                  label: l.copyLink,
                  onTap: copyLink,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l.shareCancelButton),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
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


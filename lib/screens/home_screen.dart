import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

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
import '../core/localization/app_localizations.dart';
import '../models/work.dart';
import '../bloc/work_bloc.dart';
import '../utils/session_manager.dart';
import '../utils/responsive.dart';
import '../utils/language_dialog.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_drawer.dart';
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

  // currency symbol variable for hourly rate UI
  static const String _currencySymbol = '€';

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
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleAddWorkFromDrawer() async {
    if (!mounted) return;
    _showAddWorkDialog();
  }

  Future<void> _openAttendanceHistory() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AttendanceHistoryScreen(),
      ),
    );
  }

  Future<void> _openContractWork() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ContractWorkScreen(),
      ),
    );
  }

  Future<void> _openReportsSummary() async {
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
    if (!mounted) return;
    final shouldDelete = await _showDeleteAccountConfirmationDialog(l);
    if (!shouldDelete || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<AppCubit>().deleteAccount();
    if (!mounted) return;
    if (success) {
      context.read<WorkBloc>().add(const WorkCleared());
    }
    final message =
    success ? l.deleteAccountSuccessMessage : l.deleteAccountFailedMessage;
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
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
              actions: [
                IconButton(
                  icon: Image.asset(
                    AppAssets.language,
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    showLanguageSelectionDialog(
                      context: context,
                      options: languageOptions,
                      localization: l,
                    );
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
            drawer: AppDrawer(
              localization: l,
              userName: userName,
              userContact: userContact,
              onDashboardTap: _handleDashboardTap,
              onAddWorkTap: _handleAddWorkFromDrawer,
              onAttendanceHistoryTap: _openAttendanceHistory,
              onContractWorkTap: _openContractWork,
              onProfileTap: () async {
                if (!mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              onReportsSummaryTap: _openReportsSummary,
              onChangeLanguageTap: () async {
                if (!mounted) return;
                await showLanguageSelectionDialog(
                  context: context,
                  options: languageOptions,
                  localization: l,
                );
              },
              onHelpSupportTap: _openHelpSupport,
              onDeleteAccountTap: () => _handleDeleteAccountTap(l),
              onLogoutTap: () => _handleLogoutTap(l),
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
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F9FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0EDFF)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE0EDFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.ads_click_outlined,
                color: Color(0xFF1D4ED8),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.adPlaceholderTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                      fontSize: 18,
                    ) ??
                        const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.adPlaceholderSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4B5563),
                      height: 1.4,
                    ) ??
                        const TextStyle(
                          color: Color(0xFF4B5563),
                          height: 1.4,
                          fontSize: 14,
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

  Widget _buildHomeBody(AppLocalizations l, WorkState state) {
    _maybeNavigateToDashboard(state);
    final works = state.works;
    final isActivationInProgress =
        state.activateStatus == WorkActionStatus.inProgress;
    final activatingWorkId = state.activatingWorkId;

    // loading initial
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

    // load error + no data
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

    // first-time user (no work yet)
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

    // has at least one work
    // show banner, then "Add New Work" card, then list of works
    return RefreshIndicator(
      onRefresh: () => _handleRefresh(state),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: works.length + 2, // [0]=banner, [1]=AddWorkCard, [2..] cards
        itemBuilder: (context, index) {
          if (index == 0) {
            // top banner/ad
            return _buildHomeBanner(l);
          }

          if (index == 1) {
            // our new fancy "Add New Work" quick action card
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AddNewWorkCard(
                title: l.addNewWorkLabel,
                subtitle: l.editWorkSubtitle,
                onTap: _showAddWorkDialog,
              ),
            );
          }

          final work = works[index - 2];
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
            SizedBox(height: index <= 1 ? 14 : 12),
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
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
            const Icon(Icons.error_outline,
                color: Color(0xFFD32F2F), size: 64),
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

  /// WORK CARD WITH ACTIONS, ACTIVE BADGE, RATE, ACTIVATE BUTTON
  Widget _buildWorkCard(
      Work work,
      AppLocalizations l, {
        required bool isDeleting,
        required bool isActivating,
        required bool activationInProgress,
      }) {
    final isActive = _isWorkActive(work);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = _resolveWorkDescription(work);

    final accentColor =
    work.isContract ? colorScheme.tertiary : colorScheme.primary;

    final statusBarColor = isActive
        ? const Color(0xFF10B981) // green if active
        : accentColor.withOpacity(0.8); // themed color if not active

    final disableActivateButton =
        isDeleting || (activationInProgress && !isActivating) || isActive;
    final disableActions = isDeleting || isActivating;

    // top-right quick actions (edit / delete)
    final actionsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: disableActions ? null : () => _showEditWorkDialog(work),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accentColor.withOpacity(0.07),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.edit_outlined,
              color: accentColor,
              size: 17,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: disableActions ? null : () => _handleDeleteWorkTap(work, l),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFFFE8E6),
              border: Border.all(
                color: const Color(0xFFB42318).withOpacity(0.22),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFFB42318),
              size: 17,
            ),
          ),
        ),
      ],
    );

    // CTA button bottom-right
    final activateButton = !isActive
        ? Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB),
            Color(0xFF4F46E5),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x662563EB),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap:
        disableActivateButton ? null : () => _handleSetActiveWork(work),
        borderRadius: BorderRadius.circular(999),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActivating)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(
                Icons.bolt_rounded,
                size: 18,
                color: Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              isActivating
                  ? l.settingActiveWorkLabel
                  : l.setActiveWorkButton,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    )
        : Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFECFDF5),
        border: Border.all(
          color: const Color(0xFF10B981),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 16,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 6),
          Text(
            l.activeWorkLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    // salary row bottom-left
    final hourlySalaryRow = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.hourlySalaryLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
            height: 1.3,
          ) ??
              const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatHourlyRate(work, l),
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: accentColor,
            height: 1.2,
          ) ??
              TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: accentColor,
                height: 1.2,
              ),
        ),
      ],
    );

    // title + desc + footer stacked vertically
    final contentColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // first row: work name + "Active" chip + edit/delete row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // left side: work name + (active chip if active)
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Work Name (bigger font now)
                  Text(
                    work.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18, // increased to 20
                      color: const Color(0xFF0F172A),
                      height: 1.3,
                    ) ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            actionsRow,
          ],
        ),

        // description
        if (description != null && description.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              description.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ) ??
                  const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
            ),
          ),

        // footer row: salary left / activate button right
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: hourlySalaryRow),
              const SizedBox(width: 12),
              activateButton,
            ],
          ),
        ),
      ],
    );

    // visual frame with left color bar and smooth border/glow
    final framedCard = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isActive ? const Color(0xFF10B981) : accentColor).withOpacity(0.18),
            Colors.white.withOpacity(0),
          ],
        ),
        border: Border.all(
          color: isActive
              ? const Color(0xFF10B981).withOpacity(0.5)
              : accentColor.withOpacity(0.16),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // status color bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: statusBarColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                ),
              ),
            ),
            // inner white body
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: contentColumn,
              ),
            ),
          ],
        ),
      ),
    );

    // tap wrapper
    final interactiveCard = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: (isDeleting || isActivating) ? null : () => _openWorkDetail(work),
        onLongPress:
        (isDeleting || isActivating) ? null : () => _showEditWorkDialog(work),
        borderRadius: BorderRadius.circular(22),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: framedCard,
      ),
    );

    // swipe to delete wrapper with loading overlay
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
          interactiveCard,
          if (isDeleting)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
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
      borderRadius: BorderRadius.circular(22),
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

    // now includes currency symbol before amount, and "/hour" after
    return '$_currencySymbol$formatted/hour';
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

  Future<void> _showShareOptions() async {
    final l = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final responsive = dialogContext.responsive;
        final mediaQuery = MediaQuery.of(dialogContext);
        final textScaler = MediaQuery.textScalerOf(dialogContext);

        TextStyle scaleTextStyle(TextStyle base, {FontWeight? fontWeight}) {
          final scaledFontSize =
          textScaler.scale(responsive.scaleText(base.fontSize ?? 16));
          return base.copyWith(
            fontSize: scaledFontSize,
            fontWeight: fontWeight ?? base.fontWeight,
          );
        }

        final maxWidth = math.min(
          mediaQuery.size.width *
              (mediaQuery.orientation == Orientation.portrait ? 0.92 : 0.6),
          responsive.scaleWidth(420),
        );
        final minWidth = math.min(maxWidth, responsive.scaleWidth(280));
        final borderRadius = BorderRadius.circular(responsive.scale(26));
        final horizontalPadding = responsive.scale(24);
        final verticalPadding = responsive.scale(24);
        final spacing = responsive.scale(12);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: responsive.scale(16),
            vertical: responsive.scale(24),
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth,
                maxWidth: maxWidth,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: responsive.scale(28),
                      offset: Offset(0, responsive.scale(18)),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth >= responsive.scaleWidth(360);
                    final availableWidth =
                        constraints.maxWidth - (horizontalPadding * 2);
                    final safeAvailableWidth =
                    availableWidth > 0 ? availableWidth : 0.0;
                    final buttonWidth = isWide
                        ? math.max((safeAvailableWidth - spacing) / 2, 0.0)
                        : safeAvailableWidth;

                    final titleStyle = scaleTextStyle(
                      (theme.textTheme.titleMedium ??
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ))
                          .copyWith(fontWeight: FontWeight.w600),
                    );

                    final shareActions = <Widget>[
                      _buildShareButton(
                        backgroundColor: const Color(0xFF25D366),
                        icon: Icons.ios_share,
                        label: l.shareViaWhatsApp,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _shareViaWhatsApp();
                        },
                      ),
                      _buildShareButton(
                        backgroundColor: const Color(0xFF007AFF),
                        icon: Icons.copy,
                        label: l.copyLink,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _copyShareLink();
                        },
                      ),
                    ];

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        responsive.scale(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  l.shareAppTitle,
                                  style: titleStyle,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                icon: const Icon(Icons.close),
                                splashRadius: responsive.scale(20),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.scale(20)),
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            alignment: WrapAlignment.center,
                            children: shareActions
                                .map(
                                  (button) => SizedBox(
                                width: buttonWidth,
                                child: button,
                              ),
                            )
                                .toList(),
                          ),
                          SizedBox(height: responsive.scale(18)),
                          SizedBox(
                            width: double.infinity,
                            child: _buildShareButton(
                              backgroundColor: Colors.black,
                              label: l.shareCancelButton,
                              onTap: () => Navigator.of(dialogContext).pop(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
    EdgeInsetsGeometry? padding,
    double? iconSize,
  }) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final textScaler = MediaQuery.textScalerOf(context);
    final baseStyle = theme.textTheme.labelLarge?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w600,
    ) ??
        TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );
    final scaledFontSize =
    textScaler.scale(responsive.scaleText(baseStyle.fontSize ?? 16));
    final textStyle = baseStyle.copyWith(fontSize: scaledFontSize);

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        elevation: 0,
        padding: padding ?? EdgeInsets.symmetric(vertical: responsive.scale(14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.scale(18)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor,
              size: iconSize ?? responsive.scale(20),
            ),
            SizedBox(width: responsive.scale(8)),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
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

  Future<void> _copyShareLink() async {
    await Clipboard.setData(ClipboardData(text: _shareLink));
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.shareLinkCopied)),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// --------------------------------------------
/// "Add New Work" Quick Card
/// --------------------------------------------

class _AddNewWorkCard extends StatelessWidget {
  const _AddNewWorkCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Card with dashed border and soft gradient badge for the +
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashFactory: InkRipple.splashFactory,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: _DashedOutline(
            radius: 16,
            dashColor: const Color(0xFF94A3B8),
            strokeWidth: 1.2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  // circular gradient + icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF4F46E5),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // main title
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            fontSize: 16,
                          ) ??
                              const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                              ),
                        ),
                        const SizedBox(height: 4),
                        // subtitle
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            height: 1.4,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                          ) ??
                              const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // chevron
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a dashed rounded border around its child.
class _DashedOutline extends StatelessWidget {
  const _DashedOutline({
    required this.child,
    required this.radius,
    required this.dashColor,
    required this.strokeWidth,
  });

  final Widget child;
  final double radius;
  final Color dashColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        radius: radius,
        color: dashColor,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  final double radius;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final path = Path()..addRRect(rrect);

    final dashWidth = 6.0;
    final dashSpace = 4.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = StrokeCap.round;

    final dashedPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path dashed = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        final bool isLastSegment = next > metric.length;
        dashed.addPath(
          metric.extractPath(
            distance,
            isLastSegment ? metric.length : next,
          ),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

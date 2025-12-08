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
import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/work.dart';
import '../utils/language_dialog.dart';
import '../utils/local_notification_service.dart';
import '../utils/responsive.dart';
import '../utils/session_manager.dart';
import '../utils/snackbar.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_loader.dart';
import '../widgets/work_management_dialogs.dart';
import '../widgets/work_selection_dialog.dart';
import '../widgets/dashboard_banner_ad.dart';
import 'attendance_history_screen.dart';
import 'help_support_screen.dart';
import 'profile_screen.dart';
import 'reports_summary_screen.dart';
import 'work_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.openDashboardOnLogin = false})
    : super(key: key);

  final bool openDashboardOnLogin;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _shareLink = 'https://attendencepro.com/';

  static const String _currencySymbol = '€';

  final WorkApi _workApi = WorkApi();
  final SessionManager _sessionManager = const SessionManager();
  List<Work> _works = const <Work>[];
  bool _isLoadingWorks = false;
  String? _worksError;
  bool _shouldOpenDashboard = false;
  bool _hasOpenedDashboard = false;
  bool _hasTriggeredAutoActivation = false;
  String? _pendingActivationWorkId;

  void _showSnack(String message) {
    if (!mounted) return;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    AppSnackBar.show(context, trimmed);
  }

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
        _showSnack(message);
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
      final message = e.message.isNotEmpty
          ? e.message
          : l.worksLoadFailedMessage;
      setState(() {
        _worksError = message;
      });
      if (showSnackBarOnError) {
        _showSnack(message);
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
        _showSnack(message);
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

  Future<void> _openAttendanceHistory() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AttendanceHistoryScreen(),
      ),
    );

    if (!mounted) return;
    await _refreshWorks();
  }

  Future<void> _openReportsSummary() async {
    if (!mounted) return;
    final workState = context.read<WorkBloc>().state;
    final works = workState.works;
    if (works.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const ReportsSummaryScreen(),
        ),
      );
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
        builder: (context) =>
            ReportsSummaryScreen(initialWorkId: selectedWork.id),
      ),
    );
  }

  Future<void> _openHelpSupport() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const HelpSupportScreen()),
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

  bool _onScrollNotification(
    ScrollNotification notification,
    WorkState state,
  ) {
    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      final metrics = notification.metrics;
      final triggerPosition =
          metrics.maxScrollExtent == 0 ? 0 : metrics.maxScrollExtent - 100;
      final shouldLoadMore =
          metrics.pixels >= triggerPosition && state.nextPage != null;
      if (shouldLoadMore && !state.isLoadingMore) {
        context.read<WorkBloc>().add(const WorkLoadMore());
      }
    }

    return false;
  }

  void _openWorkDetail(Work work) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WorkDetailScreen(work: work),
      ),
    );
  }

  void _handleDrawerButtonPressed(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState == null) {
      return;
    }
    if (scaffoldState.isDrawerOpen) {
      scaffoldState.closeDrawer();
    } else {
      scaffoldState.openDrawer();
    }
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
    if (!mounted) return;
    unawaited(_refreshWorks());
  }

  void _handleSetActiveWork(Work work) {
    _pendingActivationWorkId = work.id;
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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
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
                              style:
                                  theme.textTheme.titleLarge?.copyWith(
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
                              style:
                                  theme.textTheme.bodyMedium?.copyWith(
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
                            style:
                                theme.textTheme.bodySmall?.copyWith(
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
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
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
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB91C1C),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            l.workDeleteConfirmButton,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.labelLarge?.copyWith(
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
    _showSnack(option);
  }

  Future<void> _handleLogoutTap(AppLocalizations l) async {
    if (!mounted) return;
    final shouldLogout = await _showLogoutConfirmationDialog(l);
    if (!shouldLogout || !mounted) return;

    final success = await context.read<AppCubit>().logout();
    if (!mounted) return;
    context.read<WorkBloc>().add(const WorkCleared());
    final message = success ? l.logoutSuccessMessage : l.logoutFailedMessage;
    _showSnack(message);
  }

  Future<bool> _showLogoutConfirmationDialog(AppLocalizations l) {
    return showCreativeLogoutDialog(context, l);
  }

  Future<void> _handleDeleteAccountTap(AppLocalizations l) async {
    if (!mounted) return;
    final shouldDelete = await _showDeleteAccountConfirmationDialog(l);
    if (!shouldDelete || !mounted) return;

    final success = await context.read<AppCubit>().deleteAccount();
    if (!mounted) return;
    if (success) {
      context.read<WorkBloc>().add(const WorkCleared());
    }
    final message = success
        ? l.deleteAccountSuccessMessage
        : l.deleteAccountFailedMessage;
    _showSnack(message);
  }

  Future<bool> _showDeleteAccountConfirmationDialog(AppLocalizations l) {
    return showCreativeDeleteAccountDialog(context, l);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WorkBloc, WorkState>(
          listenWhen: (previous, current) =>
              previous.lastErrorMessage != current.lastErrorMessage ||
              previous.lastSuccessMessage != current.lastSuccessMessage ||
              previous.requiresAuthentication !=
                  current.requiresAuthentication ||
              previous.feedbackKind != current.feedbackKind,
          listener: (context, state) {
            final l = AppLocalizations.of(context);
            String? message;

            if (state.requiresAuthentication) {
              message = l.authenticationRequiredMessage;
            } else if (state.lastErrorMessage != null &&
                state.lastErrorMessage!.isNotEmpty) {
              message = state.lastErrorMessage;
            } else if (state.feedbackKind == WorkFeedbackKind.activate &&
                state.activateStatus == WorkActionStatus.success) {
              final activatedWork = _resolveActivatedWorkForFeedback(state);
              if (activatedWork != null) {
                message = l.workActivatedWithName(activatedWork.name);
              } else if (state.lastSuccessMessage != null &&
                  state.lastSuccessMessage!.isNotEmpty) {
                message = state.lastSuccessMessage;
              } else {
                message = _successFallback(state.feedbackKind, l);
              }
            } else if (state.lastSuccessMessage != null) {
              if (state.lastSuccessMessage!.isNotEmpty) {
                message = state.lastSuccessMessage;
              } else {
                message = _successFallback(state.feedbackKind, l);
              }
            }

            if (message != null && message.isNotEmpty) {
              _showSnack(message);
            }
          },
        ),
        BlocListener<WorkBloc, WorkState>(
          listenWhen: (previous, current) =>
              previous.activateStatus != current.activateStatus,
          listener: (context, state) {
            if (state.activateStatus == WorkActionStatus.success) {
              final pendingId = _pendingActivationWorkId;
              _pendingActivationWorkId = null;
              if (pendingId != null) {
                Work? activatedWork;
                for (final work in state.works) {
                  if (work.id == pendingId && _isWorkActive(work)) {
                    activatedWork = work;
                    break;
                  }
                }

                activatedWork ??= _firstActiveWork(state.works);

                if (activatedWork != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    context.read<AppCubit>().showHome();
                    _openWorkDetail(activatedWork!);
                  });
                }
              }
            } else if (state.activateStatus == WorkActionStatus.failure) {
              _pendingActivationWorkId = null;
            }
          },
        ),
      ],
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
          final userContact =
              state.userEmail ??
              state.userPhone ??
              state.userUsername ??
              l.drawerUserPhone;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 5,
              systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: Image.asset(
                      AppAssets.icDrawer,
                      width: 27,
                      height: 27,
                    ),
                    onPressed: () => _handleDrawerButtonPressed(context),
                  );
                },
              ),
              title: Text(
                l.appTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: [
                IconButton(
                  icon: Image.asset(AppAssets.language, width: 26, height: 26),
                  onPressed: () {
                    showLanguageSelectionDialog(
                      context: context,
                      options: languageOptions,
                      localization: l,
                    );
                  },
                ),
                IconButton(
                  icon: Image.asset(AppAssets.icShare, width: 34, height: 34),
                  onPressed: _showShareOptions,
                ),
              ],
            ),
            drawer: AppDrawer(
              localization: l,
              userName: userName,
              userContact: userContact,
              onDashboardTap: _handleDashboardTap,
              onAttendanceHistoryTap: _openAttendanceHistory,
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
    return DashboardBannerAd(localization: l);
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
          Center(child: AppLoader()),
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
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) =>
            _onScrollNotification(notification, state),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: works.length + 2 + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHomeBanner(l);
            }

            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AddNewWorkCard(
                  title: l.addNewWorkLabel,
                  subtitle: l.editWorkSubtitle,
                  onTap: _showAddWorkDialog,
                ),
              );
            }

            if (index >= works.length + 2) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
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
        children: [_buildHomeBanner(l), ...children],
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = _resolveWorkDescription(work);

    final accentColor = work.isContract
        ? colorScheme.tertiary
        : colorScheme.primary;

    final statusBarColor = isActive
        ? const Color(0xFF10B981)
        : accentColor.withOpacity(0.8);

    final disableActivateButton =
        isDeleting || (activationInProgress && !isActivating) || isActive;
    final disableActions = isDeleting || isActivating;
    final screenWidth = MediaQuery.of(context).size.width;
    final activeChipMaxWidth = math.min(screenWidth * 0.45, 220.0);

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
              border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.edit_outlined, color: accentColor, size: 17),
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

    final activateButton = !isActive
        ? Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
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
              onTap: disableActivateButton
                  ? null
                  : () => _handleSetActiveWork(work),
              borderRadius: BorderRadius.circular(999),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActivating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: AppLoader(
                        size: 16,
                        color: Colors.white,
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
            constraints: BoxConstraints(
              minHeight: 34,
              maxWidth: activeChipMaxWidth,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFECFDF5),
              border: Border.all(color: const Color(0xFF10B981), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              l.activeWorkLabel,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                    height: 1.2,
                  ) ??
                  const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                    height: 1.2,
                  ),
            ),
          );

    final hourlySalaryRow = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.hourlySalaryLabel,
          style:
              theme.textTheme.bodySmall?.copyWith(
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
          style:
              theme.textTheme.titleMedium?.copyWith(
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

    final contentColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    work.name,
                    style:
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
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
                        horizontal: 8,
                        vertical: 4,
                      ),
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

        if (description != null && description.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              description.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodySmall?.copyWith(
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

        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: hourlySalaryRow),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: activateButton,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final framedCard = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isActive ? const Color(0xFF10B981) : accentColor).withOpacity(
              0.18,
            ),
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

    final interactiveCard = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: (isDeleting || isActivating)
            ? null
            : () => _openWorkDetail(work),
        onLongPress: (isDeleting || isActivating)
            ? null
            : () => _showEditWorkDialog(work),
        borderRadius: BorderRadius.circular(22),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: framedCard,
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
                    child: AppLoader(size: 28),
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

  Work? _firstActiveWork(List<Work> works) {
    for (final work in works) {
      if (_isWorkActive(work)) {
        return work;
      }
    }
    return null;
  }

  Work? _resolveActivatedWorkForFeedback(WorkState state) {
    final pendingId = _pendingActivationWorkId;
    if (pendingId != null) {
      for (final work in state.works) {
        if (work.id == pendingId) {
          return work;
        }
      }
    }

    return _firstActiveWork(state.works);
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
      return DateTime.fromMillisecondsSinceEpoch(
        value * 1000,
        isUtc: true,
      ).toLocal();
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

/*    await LocalNotificationService.showTestNotification(
      title: l.shareNotificationTitle,
      body: l.shareNotificationBody,
    );*/

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final responsive = dialogContext.responsive;
        final mediaQuery = MediaQuery.of(dialogContext);
        final textScaler = MediaQuery.textScalerOf(dialogContext);

        TextStyle scaleTextStyle(TextStyle base, {FontWeight? fontWeight}) {
          final scaledFontSize = textScaler.scale(
            responsive.scaleText(base.fontSize ?? 16),
          );
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
                    final safeAvailableWidth = availableWidth > 0
                        ? availableWidth
                        : 0.0;
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
                                child: Text(l.shareAppTitle, style: titleStyle),
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
    final baseStyle =
        theme.textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600);
    final scaledFontSize = textScaler.scale(
      responsive.scaleText(baseStyle.fontSize ?? 16),
    );
    final textStyle = baseStyle.copyWith(fontSize: scaledFontSize);

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        elevation: 0,
        padding:
            padding ?? EdgeInsets.symmetric(vertical: responsive.scale(14)),
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
            child: Text(label, textAlign: TextAlign.center, style: textStyle),
          ),
        ],
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    final l = AppLocalizations.of(context);
    final message = l.shareMessage(_shareLink);
    final uri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(message)}',
    );

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (!mounted) return;
        _showSnack(l.shareWhatsappUnavailable);
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showSnack(l.shareWhatsappFailed);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack(l.shareWhatsappFailed);
    }
  }

  Future<void> _copyShareLink() async {
    await Clipboard.setData(ClipboardData(text: _shareLink));
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    _showSnack(l.shareLinkCopied);
  }

  @override
  void dispose() {
    super.dispose();
  }
}

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
    final theme = Theme.of(context);
    const borderRadius = BorderRadius.all(Radius.circular(24));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashFactory: InkRipple.splashFactory,
        overlayColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.pressed)
              ? Colors.white.withOpacity(0.14)
              : null,
        ),
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F1E3A8A),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -24,
                right: -16,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -32,
                left: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_circle_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ) ??
                                const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ) ??
                                        const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 28,
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


import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';

typedef DrawerActionCallback = FutureOr<void> Function();

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.localization,
    required this.userName,
    required this.userContact,
    required this.onDashboardTap,
    required this.onAddWorkTap,
    required this.onAttendanceHistoryTap,
    required this.onContractWorkTap,
    required this.onProfileTap,
    required this.onReportsSummaryTap,
    required this.onChangeLanguageTap,
    required this.onHelpSupportTap,
    required this.onDeleteAccountTap,
    required this.onLogoutTap,
  });

  final AppLocalizations localization;
  final String userName;
  final String userContact;

  final DrawerActionCallback onDashboardTap;
  final DrawerActionCallback onAddWorkTap;
  final DrawerActionCallback onAttendanceHistoryTap;
  final DrawerActionCallback onContractWorkTap;
  final DrawerActionCallback onProfileTap;
  final DrawerActionCallback onReportsSummaryTap;
  final DrawerActionCallback onChangeLanguageTap;
  final DrawerActionCallback onHelpSupportTap;
  final DrawerActionCallback onDeleteAccountTap;
  final DrawerActionCallback onLogoutTap;

  Future<void> _handleTap(
    BuildContext context,
    DrawerActionCallback callback,
  ) async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    await Future.sync(callback);
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = <_DrawerMenuItem>[
      _DrawerMenuItem(
        assetPath: AppAssets.home,
        label: localization.dashboardLabel,
        backgroundColor: const Color(0xFFE6F3FF),
        iconColor: const Color(0xFF1C87FF),
        onTap: () => _handleTap(context, onDashboardTap),
      ),
      _DrawerMenuItem(
        assetPath: AppAssets.addNewWork,
        label: localization.addNewWorkLabel,
        backgroundColor: const Color(0xFFE8F8F0),
        iconColor: const Color(0xFF2EBD5F),
        onTap: () => _handleTap(context, onAddWorkTap),
      ),
      _DrawerMenuItem(
        assetPath: AppAssets.history,
        label: localization.attendanceHistoryLabel,
        backgroundColor: const Color(0xFFFFF2F2),
        iconColor: const Color(0xFFFF3B30),
        onTap: () => _handleTap(context, onAttendanceHistoryTap),
      ),
      _DrawerMenuItem(
        assetPath: AppAssets.contractWork,
        label: localization.contractWorkLabel,
        backgroundColor: const Color(0xFFEDEBFF),
        iconColor: const Color(0xFF5856D6),
        onTap: () => _handleTap(context, onContractWorkTap),
      ),
      _DrawerMenuItem(
        icon: Icons.person_outline,
        label: localization.profileLabel,
        backgroundColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
        onTap: () => _handleTap(context, onProfileTap),
      ),
      _DrawerMenuItem(
        assetPath: AppAssets.reports,
        label: localization.reportsSummaryLabel,
        backgroundColor: const Color(0xFFE6F0FF),
        iconColor: const Color(0xFF2563EB),
        onTap: () => _handleTap(context, onReportsSummaryTap),
      ),
      _DrawerMenuItem(
        assetPath: AppAssets.changeLanguage,
        label: localization.changeLanguageLabel,
        backgroundColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFFAF52DE),
        onTap: () => _handleTap(context, onChangeLanguageTap),
      ),
      _DrawerMenuItem(
        assetPath: AppAssets.helpSupport,
        label: localization.helpSupportLabel,
        backgroundColor: const Color(0xFFE6F3FF),
        iconColor: const Color(0xFF007AFF),
        onTap: () => _handleTap(context, onHelpSupportTap),
      ),
      _DrawerMenuItem(
        icon: Icons.delete_outline,
        label: localization.deleteAccountLabel,
        backgroundColor: const Color(0xFFFFF1F2),
        iconColor: const Color(0xFFFF3B30),
        onTap: () => _handleTap(context, onDeleteAccountTap),
      ),
      _DrawerMenuItem(
        assetPath: AppAssets.logout,
        label: localization.logoutLabel,
        backgroundColor: const Color(0xFFE6F3FF),
        iconColor: const Color(0xFF007AFF),
        onTap: () => _handleTap(context, onLogoutTap),
      ),
    ];

    return Drawer(
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
                      _DrawerItem(menuItems[index]),
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
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem(this.item);

  final _DrawerMenuItem item;

  @override
  Widget build(BuildContext context) {
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
}

class _DrawerMenuItem {
  const _DrawerMenuItem({
    this.icon,
    this.assetPath,
    required this.label,
    required this.backgroundColor,
    this.iconColor,
    required this.onTap,
  })  : assert(icon != null || assetPath != null,
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

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.userName, required this.userEmail});

  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    final fallbackInitial =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : '?';

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

import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../utils/local_notification_service.dart';

class NotificationPermissionPrompt extends StatefulWidget {
  const NotificationPermissionPrompt({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationPermissionPrompt> createState() =>
      _NotificationPermissionPromptState();
}

class _NotificationPermissionPromptState
    extends State<NotificationPermissionPrompt> {
  bool _promptHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPrompt();
    });
  }

  Future<void> _maybeShowPrompt() async {
    if (!mounted || _promptHandled) {
      return;
    }

    final shouldShow = await LocalNotificationService.shouldShowPermissionPrompt();
    if (!mounted) {
      return;
    }

    if (!shouldShow) {
      _promptHandled = true;
      return;
    }

    final localizations = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.notificationsPermissionPromptTitle),
          content: Text(localizations.notificationsPermissionPromptBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.notificationsPermissionNotNowButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(localizations.notificationsPermissionAllowButton),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      final granted = await LocalNotificationService.requestPermissions();
      await LocalNotificationService.markPermissionPromptAnswered();
      if (granted) {
        await LocalNotificationService.scheduleDailyAttendanceReminder();
      }
      _promptHandled = true;
    } else if (result == false) {
      await LocalNotificationService.markPermissionPromptAnswered();
      _promptHandled = true;
    } else {
      _promptHandled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowPrompt();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

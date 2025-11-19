import 'package:flutter/material.dart';

class AppSnackBar {
  const AppSnackBar._();

  static void show(BuildContext context, String message,
      {bool reserveBottomBarSpace = true}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _buildSnackBar(context, message, reserveBottomBarSpace),
      );
  }

  static SnackBar _buildSnackBar(
    BuildContext context,
    String message,
    bool reserveBottomBarSpace,
  ) {
    final padding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomInset = viewInsets.bottom;
    final additionalOffset = bottomInset > 0
        ? bottomInset
        : (reserveBottomBarSpace ? kBottomNavigationBarHeight : 0.0);
    final bottomMargin = 16 + padding.bottom + additionalOffset;

    return SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    );
  }
}
import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../utils/responsive.dart';

Future<bool> showCreativeLogoutDialog(
  BuildContext context,
  AppLocalizations localizations,
) async {
  final theme = Theme.of(context);
  final responsive = context.responsive;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: responsive.scale(24),
          vertical: responsive.scale(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F87FF), Color(0xFF5A60FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(responsive.scale(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: responsive.scale(24),
                offset: Offset(0, responsive.scale(16)),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: responsive.scale(28)),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
                padding: EdgeInsets.all(responsive.scale(16)),
                child: CircleAvatar(
                  radius: responsive.scale(38),
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.logout,
                    size: responsive.scale(34),
                    color: Color(0xFF0F87FF),
                  ),
                ),
              ),
              SizedBox(height: responsive.scale(24)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.scale(28),
                ),
                child: Column(
                  children: [
                    Text(
                      localizations.logoutConfirmationTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: responsive.scale(12)),
                    Text(
                      localizations.logoutConfirmationMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.scale(28)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(responsive.scale(28)),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  responsive.scale(24),
                  responsive.scale(20),
                  responsive.scale(24),
                  responsive.scale(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F87FF),
                          side: const BorderSide(color: Color(0xFFB4CDFF)),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(responsive.scale(18)),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.scale(14),
                          ),
                        ),
                        child: Text(localizations.logoutCancelButton),
                      ),
                    ),
                    SizedBox(width: responsive.scale(16)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F87FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(responsive.scale(18)),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.scale(14),
                          ),
                        ),
                        child: Text(localizations.logoutConfirmButton),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}

Future<bool> showCreativeDeleteAccountDialog(
  BuildContext context,
  AppLocalizations localizations,
) async {
  final theme = Theme.of(context);
  final responsive = context.responsive;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: responsive.scale(24),
          vertical: responsive.scale(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5F6D), Color(0xFFFF1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(responsive.scale(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: responsive.scale(24),
                offset: Offset(0, responsive.scale(16)),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: responsive.scale(28)),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
                padding: EdgeInsets.all(responsive.scale(16)),
                child: CircleAvatar(
                  radius: responsive.scale(38),
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.delete_forever,
                    size: responsive.scale(34),
                    color: Color(0xFFFF1A1A),
                  ),
                ),
              ),
              SizedBox(height: responsive.scale(24)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.scale(28),
                ),
                child: Column(
                  children: [
                    Text(
                      localizations.deleteAccountConfirmationTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: responsive.scale(12)),
                    Text(
                      localizations.deleteAccountConfirmationMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.scale(28)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(responsive.scale(28)),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  responsive.scale(24),
                  responsive.scale(20),
                  responsive.scale(24),
                  responsive.scale(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF1A1A),
                          side: const BorderSide(color: Color(0xFFFFB3B8)),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(responsive.scale(18)),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.scale(14),
                          ),
                        ),
                        child: Text(localizations.deleteAccountCancelButton),
                      ),
                    ),
                    SizedBox(width: responsive.scale(16)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1A1A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(responsive.scale(18)),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.scale(14),
                          ),
                        ),
                        child: Text(localizations.deleteAccountConfirmButton),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}

Future<String?> showCreativeLanguageDialog(
  BuildContext context, {
  required Map<String, String> options,
  required String currentSelection,
  required AppLocalizations localizations,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      String tempSelection = currentSelection;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: const CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.language,
                              size: 30,
                              color: Color(0xFF5A60FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          localizations.selectLanguageTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.languageSelection(
                            options[tempSelection] ?? tempSelection,
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...options.entries.map((entry) {
                          final isSelected = entry.key == tempSelection;
                          return GestureDetector(
                            onTap: () => setState(() => tempSelection = entry.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF5A60FF)
                                      : const Color(0xFFE4E6EB),
                                  width: 1.4,
                                ),
                                color: isSelected
                                    ? const Color(0xFFEEF1FF)
                                    : Colors.white,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF5A60FF).withOpacity(0.24),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFF5A60FF)
                                          : const Color(0xFFE0E3EB),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color:
                                          isSelected ? Colors.white : const Color(0xFF8D93A1),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: isSelected
                                                    ? const Color(0xFF2D3142)
                                                    : const Color(0xFF5C6270),
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF5A60FF),
                                  side: const BorderSide(color: Color(0xFFD8DCF3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(localizations.logoutCancelButton),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(tempSelection),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5A60FF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  localizations.confirmSelectionButton,
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
            );
          },
        ),
      );
    },
  );
}

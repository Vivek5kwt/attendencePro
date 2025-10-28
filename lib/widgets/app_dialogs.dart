import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../utils/responsive.dart';

class _CreativeDialogConfig {
  const _CreativeDialogConfig({
    required this.gradientColors,
    required this.primaryColor,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final List<Color> gradientColors;
  final Color primaryColor;
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
}

Future<bool> showCreativeLogoutDialog(
  BuildContext context,
  AppLocalizations localizations,
) async {
  return _showCreativeConfirmationDialog(
    context,
    _CreativeDialogConfig(
      gradientColors: const [Color(0xFF0F87FF), Color(0xFF5A60FF)],
      primaryColor: const Color(0xFF0F87FF),
      icon: Icons.logout,
      title: localizations.logoutConfirmationTitle,
      message: localizations.logoutConfirmationMessage,
      confirmLabel: localizations.logoutConfirmButton,
      cancelLabel: localizations.logoutCancelButton,
    ),
  );
}

Future<bool> showCreativeDeleteAccountDialog(
  BuildContext context,
  AppLocalizations localizations,
) async {
  return _showCreativeConfirmationDialog(
    context,
    _CreativeDialogConfig(
      gradientColors: const [Color(0xFFFF5F6D), Color(0xFFFF1A1A)],
      primaryColor: const Color(0xFFFF1A1A),
      icon: Icons.delete_forever,
      title: localizations.deleteAccountConfirmationTitle,
      message: localizations.deleteAccountConfirmationMessage,
      confirmLabel: localizations.deleteAccountConfirmButton,
      cancelLabel: localizations.deleteAccountCancelButton,
    ),
  );
}

Future<bool> _showCreativeConfirmationDialog(
  BuildContext context,
  _CreativeDialogConfig config,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final responsive = dialogContext.responsive;
      final mediaQuery = MediaQuery.of(dialogContext);
      final textScaler = MediaQuery.textScalerOf(dialogContext);

      TextStyle _scaledTextStyle(TextStyle? base, double fallback) {
        final baseFontSize = base?.fontSize ?? fallback;
        final scaledFontSize = textScaler.scale(
          responsive.scaleText(baseFontSize),
        );
        return (base ?? TextStyle(fontSize: fallback)).copyWith(
          fontSize: scaledFontSize,
        );
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: responsive.scale(16),
          vertical: responsive.scale(16),
        ),
        child: Align(
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = math.min(
                mediaQuery.size.width *
                    (mediaQuery.orientation == Orientation.portrait ? 0.92 : 0.65),
                responsive.scaleWidth(420),
              );
              final minWidth = math.min(maxWidth, responsive.scaleWidth(260));

              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: minWidth,
                  maxWidth: maxWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    final shouldStackActions =
                        innerConstraints.maxWidth < responsive.scaleWidth(340);

                    return Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: config.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(responsive.scale(30)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: responsive.scale(28),
                              offset: Offset(0, responsive.scale(18)),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                responsive.scale(28),
                                responsive.scale(32),
                                responsive.scale(28),
                                responsive.scale(4),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.16),
                                    ),
                                    padding:
                                        EdgeInsets.all(responsive.scale(18)),
                                    child: CircleAvatar(
                                      radius: responsive.scale(36),
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        config.icon,
                                        size: responsive.scale(32),
                                        color: config.primaryColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: responsive.scale(20)),
                                  Text(
                                    config.title,
                                    textAlign: TextAlign.center,
                                    style: _scaledTextStyle(
                                      theme.textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      24,
                                    ),
                                  ),
                                  SizedBox(height: responsive.scale(12)),
                                  Text(
                                    config.message,
                                    textAlign: TextAlign.center,
                                    style: _scaledTextStyle(
                                      theme.textTheme.bodyLarge?.copyWith(
                                        color: Colors.white.withOpacity(0.92),
                                        height: 1.4,
                                      ),
                                      16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: responsive.scale(20)),
                            Container(
                              width: double.infinity,
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.scale(22),
                                vertical: responsive.scale(22),
                              ),
                              child: shouldStackActions
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _DialogOutlinedButton(
                                          label: config.cancelLabel,
                                          color: config.primaryColor,
                                          onTap: () =>
                                              Navigator.of(dialogContext)
                                                  .pop(false),
                                          responsive: responsive,
                                          textStyle: _scaledTextStyle(
                                            theme.textTheme.labelLarge,
                                            15,
                                          ),
                                        ),
                                        SizedBox(
                                            height: responsive.scale(12)),
                                        _DialogElevatedButton(
                                          label: config.confirmLabel,
                                          color: config.primaryColor,
                                          onTap: () =>
                                              Navigator.of(dialogContext)
                                                  .pop(true),
                                          responsive: responsive,
                                          textStyle: _scaledTextStyle(
                                            theme.textTheme.labelLarge,
                                            15,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: _DialogOutlinedButton(
                                            label: config.cancelLabel,
                                            color: config.primaryColor,
                                            onTap: () =>
                                                Navigator.of(dialogContext)
                                                    .pop(false),
                                            responsive: responsive,
                                            textStyle: _scaledTextStyle(
                                              theme.textTheme.labelLarge,
                                              15,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            width: responsive.scale(16)),
                                        Expanded(
                                          child: _DialogElevatedButton(
                                            label: config.confirmLabel,
                                            color: config.primaryColor,
                                            onTap: () =>
                                                Navigator.of(dialogContext)
                                                    .pop(true),
                                            responsive: responsive,
                                            textStyle: _scaledTextStyle(
                                              theme.textTheme.labelLarge,
                                              15,
                                            ),
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
                ),
              );
            },
          ),
        ),
      );
    },
  );

  return result ?? false;
}

class _DialogOutlinedButton extends StatelessWidget {
  const _DialogOutlinedButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.responsive,
    required this.textStyle,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final Responsive responsive;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.scale(18)),
        ),
        padding: EdgeInsets.symmetric(
          vertical: responsive.scale(14),
        ),
      ),
      child: Text(
        label,
        style: textStyle,
      ),
    );
  }
}

class _DialogElevatedButton extends StatelessWidget {
  const _DialogElevatedButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.responsive,
    required this.textStyle,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final Responsive responsive;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.scale(18)),
        ),
        padding: EdgeInsets.symmetric(
          vertical: responsive.scale(14),
        ),
      ),
      child: Text(
        label,
        style: textStyle.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
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
        insetPadding: EdgeInsets.symmetric(
          horizontal: dialogContext.responsive.scale(20),
          vertical: dialogContext.responsive.scale(20),
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final theme = Theme.of(ctx);
            final textTheme = theme.textTheme;
            final responsive = ctx.responsive;
            final mediaQuery = MediaQuery.of(ctx);
            final textScaler = MediaQuery.textScalerOf(ctx);
            final maxWidth = math.min(
              mediaQuery.size.width * 0.9,
              responsive.scaleWidth(420),
            );
            final maxHeight = math.min(
              mediaQuery.size.height *
                  (mediaQuery.orientation == Orientation.portrait ? 0.9 : 0.95),
              responsive.scaleHeight(580),
            );

            double scaledFont(double? base) {
              final baseSize = base ?? textTheme.bodyMedium?.fontSize ?? 16;
              final responsiveSize = responsive.scaleText(baseSize);
              return textScaler.scale(responsiveSize);
            }

            return Align(
              alignment: Alignment.center,
              child: LayoutBuilder(
                builder: (layoutContext, constraints) {
                  final minWidth = math.min(maxWidth, responsive.scaleWidth(280));
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: minWidth,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(responsive.scale(30)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              blurRadius: responsive.scale(24),
                              offset: Offset(0, responsive.scale(12)),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF7F7FD5),
                                    Color(0xFF86A8E7),
                                    Color(0xFF91EAE4)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                responsive.scale(28),
                                responsive.scale(36),
                                responsive.scale(28),
                                responsive.scale(24),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    padding: EdgeInsets.all(responsive.scale(18)),
                                    child: CircleAvatar(
                                      radius: responsive.scale(32),
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.language,
                                        size: responsive.scale(30),
                                        color: const Color(0xFF5A60FF),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: responsive.scale(18)),
                                  Text(
                                    localizations.selectLanguageTitle,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize:
                                          scaledFont(textTheme.headlineSmall?.fontSize),
                                    ),
                                  ),
                                  SizedBox(height: responsive.scale(8)),
                                  Text(
                                    localizations.languageSelection(
                                      options[tempSelection] ?? tempSelection,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize:
                                          scaledFont(textTheme.bodyMedium?.fontSize),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Container(
                                color: Colors.white,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: SingleChildScrollView(
                                        padding: EdgeInsets.fromLTRB(
                                          responsive.scale(20),
                                          responsive.scale(20),
                                          responsive.scale(20),
                                          responsive.scale(8),
                                        ),
                                        child: LayoutBuilder(
                                          builder: (optionsContext, optionsConstraints) {
                                            final spacing = responsive.scale(12);
                                            final useTwoColumns =
                                                optionsConstraints.maxWidth >=
                                                    responsive.scaleWidth(360);
                                            final itemWidth = useTwoColumns
                                                ? (optionsConstraints.maxWidth - spacing) / 2
                                                : optionsConstraints.maxWidth;

                                            return Wrap(
                                              spacing: spacing,
                                              runSpacing: spacing,
                                              children: options.entries.map((entry) {
                                                final isSelected =
                                                    entry.key == tempSelection;
                                                return SizedBox(
                                                  width: itemWidth,
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        setState(() => tempSelection = entry.key),
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                          milliseconds: 200),
                                                      curve: Curves.easeInOut,
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: responsive.scale(18),
                                                        vertical: responsive.scale(14),
                                                      ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                responsive.scale(20)),
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? const Color(0xFF5A60FF)
                                                              : const Color(0xFFE4E6EB),
                                                          width: responsive.scale(1.4),
                                                        ),
                                                        color: isSelected
                                                            ? const Color(0xFFEEF1FF)
                                                            : Colors.white,
                                                        boxShadow: isSelected
                                                            ? [
                                                                BoxShadow(
                                                                  color: const Color(0xFF5A60FF)
                                                                      .withOpacity(0.24),
                                                                  blurRadius:
                                                                      responsive.scale(12),
                                                                  offset: Offset(
                                                                    0,
                                                                    responsive.scale(6),
                                                                  ),
                                                                ),
                                                              ]
                                                            : [],
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.center,
                                                        children: [
                                                          AnimatedContainer(
                                                            duration: const Duration(
                                                                milliseconds: 200),
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: isSelected
                                                                  ? const Color(0xFF5A60FF)
                                                                  : const Color(0xFFE0E3EB),
                                                            ),
                                                            padding: EdgeInsets.all(
                                                                responsive.scale(6)),
                                                            child: Icon(
                                                              Icons.check,
                                                              size: responsive.scale(16),
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : const Color(0xFF8D93A1),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              width: responsive.scale(14)),
                                                          Expanded(
                                                            child: Text(
                                                              entry.value,
                                                              textAlign: TextAlign.start,
                                                              style: textTheme.bodyLarge?.copyWith(
                                                                color: isSelected
                                                                    ? const Color(0xFF2D3142)
                                                                    : const Color(0xFF5C6270),
                                                                fontWeight: isSelected
                                                                    ? FontWeight.w700
                                                                    : FontWeight.w500,
                                                                fontSize: scaledFont(
                                                                  textTheme.bodyLarge?.fontSize,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        responsive.scale(20),
                                        responsive.scale(12),
                                        responsive.scale(20),
                                        responsive.scale(24),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogContext).pop(),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFF5A60FF),
                                                side: const BorderSide(
                                                    color: Color(0xFFD8DCF3)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(
                                                    responsive.scale(18),
                                                  ),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: responsive.scale(14),
                                                ),
                                              ),
                                              child: Text(
                                                localizations.logoutCancelButton,
                                                style: textTheme.labelLarge?.copyWith(
                                                  fontSize: scaledFont(
                                                    textTheme.labelLarge?.fontSize,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: responsive.scale(16)),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.of(dialogContext)
                                                  .pop(tempSelection),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF5A60FF),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(
                                                    responsive.scale(18),
                                                  ),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: responsive.scale(14),
                                                ),
                                              ),
                                              child: Text(
                                                localizations.confirmSelectionButton,
                                                style: textTheme.labelLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: scaledFont(
                                                    textTheme.labelLarge?.fontSize,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    },
  );
}

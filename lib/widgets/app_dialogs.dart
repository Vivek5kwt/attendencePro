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

class _GlowingOrb extends StatelessWidget {
  const _GlowingOrb({
    required this.diameter,
    required this.colors,
  });

  final double diameter;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.first.withOpacity(0.65),
            colors.last.withOpacity(0.0),
          ],
          radius: 0.85,
        ),
      ),
    );
  }
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
                                    Color(0xFF6E7FF3),
                                    Color(0xFF7F7FD5),
                                    Color(0xFF86A8E7),
                                    Color(0xFF91EAE4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: responsive.scale(-60),
                                    right: responsive.scale(-30),
                                    child: _GlowingOrb(
                                      diameter: responsive.scale(160),
                                      colors: const [
                                        Color(0xFFB6C4FF),
                                        Color(0xFF8EA4FF),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    bottom: responsive.scale(-40),
                                    left: responsive.scale(-40),
                                    child: _GlowingOrb(
                                      diameter: responsive.scale(140),
                                      colors: const [
                                        Color(0xFFE7F2FF),
                                        Color(0xFFB8E1FF),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      responsive.scale(28),
                                      responsive.scale(40),
                                      responsive.scale(28),
                                      responsive.scale(24),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              responsive.scale(28),
                                            ),
                                            color: Colors.white.withOpacity(0.15),
                                          ),
                                          padding: EdgeInsets.all(responsive.scale(18)),
                                          child: CircleAvatar(
                                            radius: responsive.scale(32),
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              Icons.translate,
                                              size: responsive.scale(30),
                                              color: const Color(0xFF4F5BFF),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: responsive.scale(20)),
                                        Text(
                                          localizations.selectLanguageTitle,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.headlineSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            fontSize: scaledFont(
                                              textTheme.headlineSmall?.fontSize,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: responsive.scale(12)),
                                        Text(
                                          localizations.languageDialogSubtitle,
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: scaledFont(
                                              textTheme.bodyMedium?.fontSize,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: responsive.scale(14)),
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          switchInCurve: Curves.easeOutBack,
                                          switchOutCurve: Curves.easeIn,
                                          child: Text(
                                            localizations.languageSelection(
                                              options[tempSelection] ?? tempSelection,
                                            ),
                                            key: ValueKey<String>(tempSelection),
                                            textAlign: TextAlign.center,
                                            style: textTheme.bodyLarge?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: scaledFont(
                                                textTheme.bodyLarge?.fontSize,
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
                                                final languageLabel = entry.value;
                                                final trimmedLabel =
                                                    languageLabel.trim();
                                                final languageInitial =
                                                    trimmedLabel.isNotEmpty
                                                        ? trimmedLabel
                                                            .substring(0, 1)
                                                            .toUpperCase()
                                                        : '?';
                                                return SizedBox(
                                                  width: itemWidth,
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        setState(() => tempSelection = entry.key),
                                                    child: AnimatedScale(
                                                      duration: const Duration(
                                                          milliseconds: 220),
                                                      scale: isSelected ? 1.02 : 1,
                                                      curve: Curves.easeInOut,
                                                      child: AnimatedContainer(
                                                        duration: const Duration(
                                                            milliseconds: 220),
                                                        curve: Curves.easeInOut,
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal:
                                                              responsive.scale(18),
                                                          vertical:
                                                              responsive.scale(16),
                                                        ),
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  responsive.scale(22)),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? const Color(0xFF4F5BFF)
                                                                : const Color(0xFFE4E6EB),
                                                            width: responsive.scale(1.4),
                                                          ),
                                                          gradient: isSelected
                                                              ? const LinearGradient(
                                                                  colors: [
                                                                    Color(0xFFEAF0FF),
                                                                    Color(0xFFF7F9FF),
                                                                  ],
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                )
                                                              : null,
                                                          color: isSelected
                                                              ? null
                                                              : Colors.white,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: (isSelected
                                                                      ? const Color(
                                                                          0xFF4F5BFF)
                                                                      : const Color(
                                                                          0xFF8892A7))
                                                                  .withOpacity(
                                                                      isSelected ? 0.18 : 0.06),
                                                              blurRadius: responsive.scale(
                                                                  isSelected ? 18 : 10),
                                                              offset: Offset(
                                                                0,
                                                                responsive.scale(
                                                                    isSelected ? 10 : 4),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.center,
                                                          children: [
                                                            AnimatedContainer(
                                                              duration: const Duration(
                                                                  milliseconds: 220),
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                gradient: isSelected
                                                                    ? const LinearGradient(
                                                                        colors: [
                                                                          Color(0xFF4F5BFF),
                                                                          Color(0xFF7F89FF),
                                                                        ],
                                                                      )
                                                                    : null,
                                                                color: isSelected
                                                                    ? null
                                                                    : const Color(
                                                                        0xFFE0E3EB),
                                                              ),
                                                              padding: EdgeInsets.all(
                                                                responsive.scale(10),
                                                              ),
                                                              child: AnimatedSwitcher(
                                                                duration: const Duration(
                                                                    milliseconds: 200),
                                                                child: isSelected
                                                                    ? Icon(
                                                                        Icons.check,
                                                                        key: const ValueKey(
                                                                            'selected-check'),
                                                                        size: responsive
                                                                            .scale(18),
                                                                        color: Colors.white,
                                                                      )
                                                                    : Text(
                                                                        languageInitial,
                                                                        key: ValueKey(
                                                                            'initial-$languageInitial'),
                                                                        style: textTheme
                                                                            .labelLarge
                                                                            ?.copyWith(
                                                                              fontSize:
                                                                                  scaledFont(
                                                                                textTheme.labelLarge
                                                                                    ?.fontSize,
                                                                              ),
                                                                              fontWeight:
                                                                                  FontWeight.w700,
                                                                              color: const Color(
                                                                                  0xFF4C5670),
                                                                            ),
                                                                      ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                width: responsive
                                                                    .scale(14)),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisSize:
                                                                    MainAxisSize.min,
                                                                children: [
                                                                  Text(
                                                                    languageLabel,
                                                                    textAlign:
                                                                        TextAlign.start,
                                                                    style: textTheme
                                                                        .bodyLarge
                                                                        ?.copyWith(
                                                                      color: isSelected
                                                                          ? const Color(
                                                                              0xFF1D1F33)
                                                                          : const Color(
                                                                              0xFF364155),
                                                                      fontWeight: isSelected
                                                                          ? FontWeight.w700
                                                                          : FontWeight.w500,
                                                                      fontSize: scaledFont(
                                                                        textTheme
                                                                            .bodyLarge
                                                                            ?.fontSize,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      height: responsive
                                                                          .scale(4)),
                                                                  AnimatedOpacity(
                                                                    duration: const Duration(
                                                                        milliseconds: 200),
                                                                    opacity:
                                                                        isSelected ? 1 : 0.65,
                                                                    child: Text(
                                                                      isSelected
                                                                          ? localizations
                                                                              .languageSelectedCaption
                                                                          : localizations
                                                                              .languageTapToSelect,
                                                                      style: textTheme
                                                                          .bodySmall
                                                                          ?.copyWith(
                                                                        color: isSelected
                                                                            ? const Color(
                                                                                0xFF4F5BFF)
                                                                            : const Color(
                                                                                0xFF8A93A6),
                                                                        fontSize: scaledFont(
                                                                          textTheme.bodySmall
                                                                              ?.fontSize,
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
                                                  color: Colors.white,
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

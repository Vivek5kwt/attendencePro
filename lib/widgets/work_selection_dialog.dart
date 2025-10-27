import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/work.dart';

const _kAddNewWorkResult = '__add_new_work__';

Future<Work?> showWorkSelectionDialog({
  required BuildContext context,
  required List<Work> works,
  required AppLocalizations localization,
  String? initialSelectedWorkId,
  VoidCallback? onAddNewWork,
}) async {
  if (works.isEmpty) {
    return null;
  }

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xCC111827),
    builder: (dialogContext) {
      var selectedId = _initialWorkId(
        works: works,
        initialSelectedWorkId: initialSelectedWorkId,
      );

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: StatefulBuilder(
          builder: (context, setState) {
            final mediaQuery = MediaQuery.of(context);
            final double availableWidth = mediaQuery.size.width - 32;
            final double maxDialogWidth = math.min(
              420,
              availableWidth > 0 ? availableWidth : mediaQuery.size.width,
            );
            final double minDialogWidth = math.min(280, maxDialogWidth);
            final double maxDialogHeight = math.min(
              math.max(mediaQuery.size.height * 0.82, 360),
              520,
            );

            return Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: maxDialogWidth,
                        height: math.max(0, maxDialogHeight - 32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE7F1FF), Color(0xFFF7FAFF)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(36),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      minWidth: minDialogWidth,
                      maxWidth: maxDialogWidth,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33111B2B),
                          blurRadius: 40,
                          offset: Offset(0, 28),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Material(
                        color: Colors.white,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxDialogHeight),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 44),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            localization.selectWorkTitle,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF111827),
                                            ) ??
                                                const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF111827),
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                    _DialogCloseButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: math.min(
                                        mediaQuery.size.height * 0.4,
                                        320,
                                      ),
                                    ),
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      clipBehavior: Clip.none,
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: works.length,
                                      itemBuilder: (context, index) {
                                        final work = works[index];
                                        return _WorkSelectionTile(
                                          work: work,
                                          isSelected: work.id == selectedId,
                                          localization: localization,
                                          onTap: () {
                                            setState(() {
                                              selectedId = work.id;
                                            });
                                          },
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (onAddNewWork != null) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext)
                                            .pop(_kAddNewWorkResult);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        side: const BorderSide(
                                            color: Color(0xFFD1D5DB)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(18),
                                        ),
                                        foregroundColor:
                                        const Color(0xFF2563EB),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 32,
                                            width: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                const Color(0xFFD1D5DB),
                                              ),
                                              color: Colors.white,
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.add,
                                              size: 18,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              localization.addNewWorkLabel,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                fontWeight:
                                                FontWeight.w600,
                                                color: const Color(
                                                    0xFF2563EB),
                                              ) ??
                                                  const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                    Color(0xFF2563EB),
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (selectedId == null) {
                                        Navigator.of(dialogContext).pop();
                                        return;
                                      }
                                      Navigator.of(dialogContext)
                                          .pop(selectedId);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      backgroundColor:
                                      const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      localization.confirmSelectionButton,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ) ??
                                          const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  if (result == _kAddNewWorkResult) {
    onAddNewWork?.call();
    return null;
  }

  if (result == null) {
    return null;
  }

  for (final work in works) {
    if (work.id == result) {
      return work;
    }
  }
  return null;
}

String? _initialWorkId({
  required List<Work> works,
  String? initialSelectedWorkId,
}) {
  if (initialSelectedWorkId != null) {
    for (final work in works) {
      if (work.id == initialSelectedWorkId) {
        return work.id;
      }
    }
  }

  for (final work in works) {
    if (work.isActive) {
      return work.id;
    }
    final dynamic isActive = work.additionalData['is_active'] ??
        work.additionalData['isActive'] ??
        work.additionalData['active'] ??
        work.additionalData['is_current'] ??
        work.additionalData['isCurrent'] ??
        work.additionalData['currently_active'];
    if (isActive is bool && isActive) {
      return work.id;
    }
  }

  if (works.isEmpty) {
    return null;
  }
  return works.first.id;
}

class _WorkSelectionTile extends StatelessWidget {
  const _WorkSelectionTile({
    required this.work,
    required this.isSelected,
    required this.localization,
    required this.onTap,
  });

  final Work work;
  final bool isSelected;
  final AppLocalizations localization;
  final VoidCallback onTap;

  static const _gradientBorder = LinearGradient(
    colors: [Color(0xFF2E469D), Color(0xFF0E8CEA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final subtitle = _formatHourlyRate(work, localization);

    // Inner core card (white) used in both states
    final Widget _innerCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? Colors.white : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _WorkTileIcon(work: work),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ) ??
                      const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 28,
            width: 28,

            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? ClipOval(
                key: const ValueKey('selected'),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    AppAssets.icTick,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                ),
              )
                  : const SizedBox.shrink(key: ValueKey('unselected')),
            ),
          ),
        ],
      ),
    );

    // If selected, wrap the inner card with a thin gradient border outside.
    final Widget _tileBody = isSelected
        ? Container(
      decoration: BoxDecoration(
        gradient: _gradientBorder,
        borderRadius: BorderRadius.circular(26), // slightly larger radius
      ),
      padding: const EdgeInsets.all(2), // gradient stroke thickness
      child: _innerCard,
    )
        : _innerCard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          color: isSelected ? const Color(0xFFF2F7FF) : Colors.transparent,
          padding: EdgeInsets.zero,
          child: _tileBody,
        ),
      ),
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 36,
        width: 36,
        alignment: Alignment.center,
        child: Image.asset(
          AppAssets.icClose, // make sure this points to your close image
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

String _formatHourlyRate(Work work, AppLocalizations l) {
  final rate = work.hourlyRate;
  if (rate == null) {
    return '${l.hourlySalaryLabel}: ${l.notAvailableLabel}';
  }

  final double doubleValue = rate.toDouble();
  final bool isWhole = doubleValue.roundToDouble() == doubleValue;
  final formattedNumber = isWhole
      ? doubleValue.toStringAsFixed(0)
      : doubleValue.toStringAsFixed(2);

  String sanitized = formattedNumber;
  if (sanitized.contains('.')) {
    while (sanitized.endsWith('0')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    if (sanitized.endsWith('.')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
  }

  final currency = _resolveCurrencySymbol(work.additionalData);
  return '$currency$sanitized${l.workSelectionHourSuffix}';
}

String _resolveCurrencySymbol(Map<String, dynamic> data) {
  const defaultCurrency = r'$';
  final dynamic value = data['currency_symbol'] ??
      data['currencySymbol'] ??
      data['currency'] ??
      data['currencyCode'] ??
      data['currencyPrefix'];

  if (value is! String) {
    return defaultCurrency;
  }

  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return defaultCurrency;
  }

  final bool isAlphabeticCode = trimmed.length == 3 &&
      trimmed.codeUnits.every(
            (unit) => (unit >= 65 && unit <= 90) || (unit >= 97 && unit <= 122),
      );
  if (isAlphabeticCode) {
    return '$trimmed ';
  }

  return trimmed;
}

class _WorkTileIcon extends StatelessWidget {
  const _WorkTileIcon({required this.work});
  final Work work;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildIconWidget(),
      ),
    );
  }

  Widget _buildIconWidget() {
    final dynamic iconValue = work.additionalData['icon'] ??
        work.additionalData['image'] ??
        work.additionalData['asset'];

    if (iconValue is String && iconValue.trim().isNotEmpty) {
      final iconPath = iconValue.trim();
      if (iconPath.startsWith('http')) {
        return Image.network(
          iconPath,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholderIcon(),
        );
      }
      return Image.asset(
        iconPath,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholderIcon(),
      );
    }

    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    return Image.asset(
      AppAssets.workPlaceholder,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
    );
  }
}

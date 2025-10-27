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
    barrierColor: Colors.black.withOpacity(0.35),
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
              child: Container(
                constraints: BoxConstraints(
                  minWidth: minDialogWidth,
                  maxWidth: maxDialogWidth,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 42,
                      offset: const Offset(0, 24),
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
                                const SizedBox(width: 40),
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
                                      const SizedBox(height: 6),
                                      Text(
                                        localization.workSelectionSubtitle,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: const Color(0xFF6B7280),
                                                ) ??
                                            const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF6B7280),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: math.min(mediaQuery.size.height * 0.4, 320),
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 4),
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
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (onAddNewWork != null) ...[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(_kAddNewWorkResult);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
                                  label: Text(
                                    localization.addNewWorkLabel,
                                    style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2563EB),
                                            ) ??
                                        const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2563EB),
                                        ),
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
                                  Navigator.of(dialogContext).pop(selectedId);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  backgroundColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
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

  @override
  Widget build(BuildContext context) {
    final subtitle = _formatHourlyRate(work, localization);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
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
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? const Color(0xFF2563EB) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
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
  final formattedNumber =
      isWhole ? doubleValue.toStringAsFixed(0) : doubleValue.toStringAsFixed(2);
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
        (unit) =>
            (unit >= 65 && unit <= 90) || (unit >= 97 && unit <= 122),
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

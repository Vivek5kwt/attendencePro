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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: StatefulBuilder(
          builder: (context, setState) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localization.selectWorkTitle,
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
                    const SizedBox(height: 20),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              for (final work in works)
                                _WorkSelectionTile(
                                  work: work,
                                  isSelected: work.id == selectedId,
                                  localization: localization,
                                  onTap: () {
                                    setState(() {
                                      selectedId = work.id;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (onAddNewWork != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(_kAddNewWorkResult);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    AppAssets.workPlaceholder,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
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
  final formatted = isWhole
      ? doubleValue.toStringAsFixed(0)
      : doubleValue.toStringAsFixed(2);

  return '${l.hourlySalaryLabel}: $formatted';
}

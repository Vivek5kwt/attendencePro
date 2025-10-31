import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/work.dart';

const _kAddNewWorkResult = '__add_new_work__';
const _kEditWorkResultPrefix = '__edit_work__:';

Future<Work?> showWorkSelectionDialog({
  required BuildContext context,
  required List<Work> works,
  required AppLocalizations localization,
  String? initialSelectedWorkId,
  VoidCallback? onAddNewWork,
  ValueChanged<Work>? onEditWork,
}) async {
  final visibleWorks = works;

  if (visibleWorks.isEmpty) {
    return null;
  }

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xCC111827),
    builder: (dialogContext) {
      var selectedId = _initialWorkId(
        works: visibleWorks,
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
                                SizedBox(
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 48,
                                            ),
                                            child: Text(
                                              localization.selectWorkTitle,
                                              textAlign: TextAlign.center,
                                              softWrap: true,
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
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: _DialogCloseButton(
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: math.min(
                                        mediaQuery.size.height * 0.5,
                                        360,
                                      ),
                                    ),
                                    child: Scrollbar(
                                      thumbVisibility: visibleWorks.length > 3,
                                      interactive: true,
                                      child: ListView.separated(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        physics: const BouncingScrollPhysics(),
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
                                        itemCount: visibleWorks.length,
                                        itemBuilder: (context, index) {
                                          final work = visibleWorks[index];
                                          return _WorkSelectionTile(
                                            work: work,
                                            isSelected: work.id == selectedId,
                                            localization: localization,
                                            onTap: () {
                                              setState(() {
                                                selectedId = work.id;
                                              });
                                            },
                                            onEdit: onEditWork == null
                                                ? null
                                                : () {
                                                    Navigator.of(dialogContext)
                                                        .pop(
                                                      '$_kEditWorkResultPrefix${work.id}',
                                                    );
                                                  },
                                          );
                                        },
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (onAddNewWork != null) ...[
                                  const SizedBox(height: 16),
                                  _AddNewWorkLink(
                                    localization: localization,
                                    onTap: () {
                                      Navigator.of(dialogContext)
                                          .pop(_kAddNewWorkResult);
                                    },
                                  ),
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
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
                                        horizontal: 24,
                                      ),
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

  if (result.startsWith(_kEditWorkResultPrefix)) {
    final workId = result.substring(_kEditWorkResultPrefix.length);
    for (final work in visibleWorks) {
      if (work.id == workId) {
        onEditWork?.call(work);
        break;
      }
    }
    return null;
  }

  for (final work in visibleWorks) {
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
    this.onEdit,
  });

  final Work work;
  final bool isSelected;
  final AppLocalizations localization;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  static const _gradientBorder = LinearGradient(
    colors: [Color(0xFF2E469D), Color(0xFF0E8CEA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    // Inner core card (white) used in both states
    final textTheme = Theme.of(context).textTheme;

    final Widget _innerCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? Colors.white : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: isSelected
            ? []
            : const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: work.name,
                  waitDuration: const Duration(milliseconds: 300),
                  child: Text(
                    work.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 12),
            _EditWorkButton(
              label: localization.editWorkTooltip,
              onPressed: onEdit!,
            ),
          ],
        ],
      ),
    );

    // If selected, wrap the inner card with a thin gradient border outside.
    final Widget _tileBody = isSelected
        ? Container(
            decoration: BoxDecoration(
              gradient: _gradientBorder,
              borderRadius:
                  BorderRadius.circular(26), // slightly larger radius
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
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          padding: EdgeInsets.zero,
          child: _tileBody,
        ),
      ),
    );
  }
}

class _AddNewWorkLink extends StatelessWidget {
  const _AddNewWorkLink({
    required this.localization,
    required this.onTap,
  });

  final AppLocalizations localization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: const Color(0xFFB8C5FF),
              radius: 24,
              strokeWidth: 1.6,
              dashLength: 8,
              dashGap: 6,
            ),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F1F47),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    localization.addNewWorkLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.dashGap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = math.min(distance + dashLength, metric.length);
        dashedPath.addPath(
          metric.extractPath(distance, nextDistance),
          Offset.zero,
        );
        distance = nextDistance + dashGap;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        dashGap != oldDelegate.dashGap;
  }
}

class _EditWorkButton extends StatelessWidget {
  const _EditWorkButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ) ??
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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

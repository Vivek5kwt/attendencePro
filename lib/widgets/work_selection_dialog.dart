import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/work_bloc.dart';
import '../bloc/work_event.dart';
import '../bloc/work_state.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/work.dart';
import 'app_loader.dart';

const _kAddNewWorkResult = '__add_new_work__';
const _kEditWorkResultPrefix = '__edit_work__:';


Future<Work?> showWorkSelectionDialog({
  required BuildContext context,
  required AppLocalizations localization,
  String? initialSelectedWorkId,
  VoidCallback? onAddNewWork,
  ValueChanged<Work>? onEditWork,
}) async {
  final workBloc = context.read<WorkBloc>();

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xCC111827),
    builder: (dialogContext) {
      return BlocProvider.value(
        value: workBloc,
        child: _WorkSelectionDialog(
          localization: localization,
          initialSelectedWorkId: initialSelectedWorkId,
          onAddNewWork: onAddNewWork,
          onEditWork: onEditWork,
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
    final workState = workBloc.state;
    for (final work in workState.works) {
      if (work.id == workId) {
        onEditWork?.call(work);
        break;
      }
    }
    return null;
  }

  final workState = workBloc.state;
  for (final work in workState.works) {
    if (work.id == result) {
      return work;
    }
  }
  return null;
}

class _WorkSelectionDialog extends StatefulWidget {
  const _WorkSelectionDialog({
    required this.localization,
    this.initialSelectedWorkId,
    this.onAddNewWork,
    this.onEditWork,
  });

  final AppLocalizations localization;
  final String? initialSelectedWorkId;
  final VoidCallback? onAddNewWork;
  final ValueChanged<Work>? onEditWork;

  @override
  State<_WorkSelectionDialog> createState() => _WorkSelectionDialogState();
}

class _WorkSelectionDialogState extends State<_WorkSelectionDialog> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedId;
  WorkState? _lastWorkState;

  @override
  void initState() {
    super.initState();
    final initialState = context.read<WorkBloc>().state;
    _selectedId = _initialWorkId(
      works: initialState.works,
      initialSelectedWorkId: widget.initialSelectedWorkId,
    );
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final metrics = _scrollController.position;
    final state = _lastWorkState ?? context.read<WorkBloc>().state;
    final trigger = metrics.maxScrollExtent == 0
        ? 0
        : metrics.maxScrollExtent - 120;
    final shouldLoadMore =
        metrics.pixels >= trigger && state.nextPage != null && !state.isLoadingMore;
    if (shouldLoadMore) {
      context.read<WorkBloc>().add(const WorkLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
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
                      child: BlocBuilder<WorkBloc, WorkState>(
                        builder: (context, state) {
                          _lastWorkState = state;
                          final works = state.works;
                          final hasSelection = works.any((w) => w.id == _selectedId);
                          if (!hasSelection && works.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedId = _initialWorkId(
                                    works: works,
                                    initialSelectedWorkId: widget.initialSelectedWorkId,
                                  );
                                });
                              }
                            });
                          }

                          if (state.isLoading && works.isEmpty) {
                            return const Center(child: AppLoader());
                          }

                          if (works.isEmpty) {
                            return _buildEmptyContent(context);
                          }

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTitle(context),
                              const SizedBox(height: 32),
                              _buildList(context, works, state),
                              if (widget.onAddNewWork != null) ...[
                                const SizedBox(height: 16),
                                _AddNewWorkLink(
                                  localization: widget.localization,
                                  onTap: () {
                                    Navigator.of(context).pop(_kAddNewWorkResult);
                                  },
                                ),
                              ],
                              const SizedBox(height: 24),
                              _buildConfirmButton(context),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return SizedBox(
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
                  widget.localization.selectWorkTitle,
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
        ],
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(context),
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: AppLoader(),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<Work> works, WorkState state) {
    final mediaQuery = MediaQuery.of(context);
    final isLoadingMore = state.isLoadingMore;

    return Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: math.min(
            mediaQuery.size.height * 0.5,
            360,
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: works.length > 3,
          interactive: true,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: works.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= works.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final work = works[index];
              return _WorkSelectionTile(
                work: work,
                isSelected: work.id == _selectedId,
                localization: widget.localization,
                onTap: () {
                  setState(() {
                    _selectedId = work.id;
                  });
                },
                onEdit: widget.onEditWork == null
                    ? null
                    : () {
                        Navigator.of(context).pop(
                          '$_kEditWorkResultPrefix${work.id}',
                        );
                      },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (_selectedId == null) {
            Navigator.of(context).pop();
            return;
          }
          Navigator.of(context).pop(_selectedId);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          widget.localization.confirmSelectionButton,
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
    );
  }
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

    final Widget _tileBody = isSelected
        ? Container(
            decoration: BoxDecoration(
              gradient: _gradientBorder,
              borderRadius:
                  BorderRadius.circular(26),
            ),
            padding: const EdgeInsets.all(2),
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
          AppAssets.icClose,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

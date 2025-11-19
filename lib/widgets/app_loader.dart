import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// A reusable ink-drop loader that matches the current app theme.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 48, this.color});

  /// The size of the loading animation.
  final double size;

  /// Optional color override. Defaults to the theme's primary color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return LoadingAnimationWidget.inkDrop(
      color: effectiveColor,
      size: size,
    );
  }
}

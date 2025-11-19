import 'package:flutter/material.dart';

import '../utils/responsive.dart';

class PrimaryCtaButton extends StatelessWidget {
  const PrimaryCtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final effectiveHeight = height ?? responsive.scale(56);
    final isEnabled = onPressed != null && !isLoading;
    final borderRadius = BorderRadius.circular(responsive.scale(40));

    final gradient = const LinearGradient(
      colors: [
        Color(0xFF64A1FF),
        Color(0xFF3B6BFF),
        Color(0xFF2B47FF),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final disabledColor = Colors.blueGrey.shade200;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: effectiveHeight,
      decoration: BoxDecoration(
        gradient: isEnabled ? gradient : null,
        color: isEnabled ? null : disabledColor,
        borderRadius: borderRadius,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0x592B47FF),
                  offset: Offset(0, responsive.scale(12)),
                  blurRadius: responsive.scale(28),
                  spreadRadius: responsive.scale(1.2),
                ),
                BoxShadow(
                  color: const Color(0x332B47FF),
                  offset: Offset(0, responsive.scale(2)),
                  blurRadius: responsive.scale(4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          splashFactory: InkRipple.splashFactory,
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isEnabled)
                Positioned(
                  top: responsive.scale(6),
                  right: responsive.scale(12),
                  left: responsive.scale(12),
                  child: Container(
                    height: responsive.scale(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(responsive.scale(14)),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x66FFFFFF),
                          Color(0x11FFFFFF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.scale(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: responsive.scale(22),
                          color: Colors.white.withOpacity(isLoading ? 0.7 : 1),
                        ),
                        SizedBox(width: responsive.scale(10)),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: responsive.scaleText(18),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white.withOpacity(isLoading ? 0.7 : 1),
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
  }
}

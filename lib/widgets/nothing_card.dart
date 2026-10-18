import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NothingCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool hasRedDot;

  const NothingCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.hasRedDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Stack(
      children: [
        Padding(
          padding: padding,
          child: child,
        ),
        if (hasRedDot)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surf(context),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.brd(context),
              width: 1,
            ),
          ),
          child: cardContent,
        ),
      ),
    );
  }
}

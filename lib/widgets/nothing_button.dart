import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NothingButtonType { primary, secondary, danger, ghost }

class NothingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NothingButtonType type;
  final bool isExpanded;
  final double height;

  const NothingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = NothingButtonType.primary,
    this.isExpanded = false,
    this.height = 48,
  });

  const NothingButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = false,
    this.height = 48,
  }) : type = NothingButtonType.secondary;

  const NothingButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = false,
    this.height = 48,
  }) : type = NothingButtonType.danger;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case NothingButtonType.primary:
        bg = AppColors.txt(context);
        fg = AppColors.bg(context);
        border = AppColors.txt(context);
        break;
      case NothingButtonType.secondary:
        bg = AppColors.surfElevated(context);
        fg = AppColors.txt(context);
        border = AppColors.brd(context);
        break;
      case NothingButtonType.danger:
        bg = AppColors.isDark(context) ? AppColors.accentRedDim : AppColors.accentRedLightDim;
        fg = AppColors.danger;
        border = AppColors.danger.withValues(alpha: 0.5);
        break;
      case NothingButtonType.ghost:
        bg = Colors.transparent;
        fg = AppColors.txtSec(context);
        border = Colors.transparent;
        break;
    }

    final content = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );

    return SizedBox(
      height: height,
      width: isExpanded ? double.infinity : null,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: content,
      ),
    );
  }
}

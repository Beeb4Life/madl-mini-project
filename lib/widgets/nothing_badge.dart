import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NothingBadge extends StatelessWidget {
  final String label;
  final bool isAccented;
  final bool isCompleted;
  final IconData? icon;

  const NothingBadge({
    super.key,
    required this.label,
    this.isAccented = false,
    this.isCompleted = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surfElevated(context);
    Color borderColor = AppColors.brd(context);
    Color textColor = AppColors.txtSec(context);

    if (isAccented) {
      bgColor = AppColors.isDark(context) ? AppColors.accentRedDim : AppColors.accentRedLightDim;
      borderColor = AppColors.accentRed.withValues(alpha: 0.5);
      textColor = AppColors.isDark(context) ? AppColors.textPrimary : AppColors.accentRed;
    } else if (isCompleted) {
      bgColor = AppColors.isDark(context) ? Colors.white10 : Colors.black12;
      borderColor = AppColors.isDark(context) ? Colors.white30 : Colors.black26;
      textColor = AppColors.txt(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final isDark = AppColors.isDark(context);
    final bg = isError
        ? (isDark ? const Color(0xFF2A1515) : const Color(0xFFFFEBEE))
        : (isDark ? const Color(0xFF282830) : const Color(0xFF1E1E1E));
    final fg = isError
        ? (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFC62828))
        : Colors.white;
    final border = isError
        ? (isDark ? const Color(0xFFFF6B6B).withValues(alpha: 0.4) : const Color(0xFFEF9A9A))
        : (isDark ? const Color(0xFF484852) : const Color(0xFF404040));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isError ? AppColors.danger : AppColors.accentRed,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

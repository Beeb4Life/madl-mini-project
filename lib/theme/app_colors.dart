import 'package:flutter/material.dart';

class AppColors {
  // Dark palette: background is black, cards are sleek grey so they stand out cleanly
  static const Color background = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF1E1E24);
  static const Color surfaceElevated = Color(0xFF282830);
  static const Color surfaceHighlight = Color(0xFF32323C);
  
  static const Color border = Color(0xFF383842);
  static const Color borderSubtle = Color(0xFF26262E);
  static const Color borderBright = Color(0xFF555562);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFF3F3F46);

  // Light palette: background is light grey, cards are pure white with clean borders
  static const Color lightBackground = Color(0xFFF4F4F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEBEBF0);
  static const Color lightSurfaceHighlight = Color(0xFFE2E2E8);
  
  static const Color lightBorder = Color(0xFFD6D6DC);
  static const Color lightBorderSubtle = Color(0xFFE6E6EC);
  static const Color lightBorderBright = Color(0xFFA8A8B2);
  
  static const Color lightTextPrimary = Color(0xFF0A0A0A);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF8E8E93);
  static const Color lightTextDisabled = Color(0xFFC7C7CC);

  // Iconic Nothing OS red dot indicator / accent
  static const Color accentRed = Color(0xFFE50914);
  static const Color accentRedDim = Color(0xFF3B1010);
  static const Color accentRedLightDim = Color(0xFFFFECEC);
  
  // Status indicators in monochrome/red
  static const Color completed = Color(0xFFFFFFFF);
  static const Color pending = Color(0xFF71717A);
  static const Color danger = Color(0xFFFF453A);

  // Dynamic context-aware color helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? background : lightBackground;

  static Color surf(BuildContext context) =>
      isDark(context) ? surface : lightSurface;

  static Color surfElevated(BuildContext context) =>
      isDark(context) ? surfaceElevated : lightSurfaceElevated;

  static Color brd(BuildContext context) =>
      isDark(context) ? border : lightBorder;

  static Color brdSubtle(BuildContext context) =>
      isDark(context) ? borderSubtle : lightBorderSubtle;

  static Color txt(BuildContext context) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  static Color txtSec(BuildContext context) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  static Color txtMut(BuildContext context) =>
      isDark(context) ? textMuted : lightTextMuted;
}

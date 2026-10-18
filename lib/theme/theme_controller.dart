import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ThemeController {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  ThemeMode get themeMode => themeModeNotifier.value;
  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  Future<void> init() async {
    final mode = await DatabaseHelper.instance.getSetting('theme_mode');
    if (mode == 'light') {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  Future<void> toggleTheme() async {
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = newMode;
    await DatabaseHelper.instance.saveSetting('theme_mode', newMode == ThemeMode.dark ? 'dark' : 'light');
  }
}

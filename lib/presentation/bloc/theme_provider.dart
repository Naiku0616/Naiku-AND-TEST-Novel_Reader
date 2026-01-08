import 'package:flutter/material.dart';
import 'package:novel_reader/data/local/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await StorageService().getPreferences();
    final savedTheme = prefs.getString('theme_mode');
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await StorageService().getPreferences();
    String themeString = 'system';
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    await prefs.setString('theme_mode', themeString);
  }

  void toggleTheme() {
    ThemeMode newMode;

    // Get current actual theme mode
    ThemeMode currentMode = _themeMode;
    if (currentMode == ThemeMode.system) {
      // If system mode, determine actual mode based on system brightness
      final isSystemDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      currentMode = isSystemDark ? ThemeMode.dark : ThemeMode.light;
    }

    // Toggle to next mode
    if (currentMode == ThemeMode.light) {
      newMode = ThemeMode.dark;
    } else {
      newMode = ThemeMode.light;
    }

    _themeMode = newMode;
    notifyListeners();

    _saveThemeMode(newMode);
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await StorageService().getPreferences();
    String themeString = 'system';
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    await prefs.setString('theme_mode', themeString);
  }
}

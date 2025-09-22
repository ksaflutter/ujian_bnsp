import 'package:flutter/material.dart';

import '../../data/services/preference_service_lokin.dart';

class ThemeProvider extends ChangeNotifier {
  final PreferenceService _preferenceService = PreferenceService();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _isDarkMode = _preferenceService.isDarkMode;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _preferenceService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _preferenceService.setDarkMode(_isDarkMode);
      notifyListeners();
    }
  }
}

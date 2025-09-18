import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model_lokin.dart';

class PreferenceService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _languageKey = 'language';
  static const String _notificationEnabledKey = 'notification_enabled';

  static final PreferenceService _instance = PreferenceService._internal();
  factory PreferenceService() => _instance;
  PreferenceService._internal();

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferenceService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // TOKEN MANAGEMENT

  /// Save authentication token
  Future<bool> saveToken(String token) async {
    return await prefs.setString(_tokenKey, token);
  }

  /// Get authentication token
  String? getToken() {
    return prefs.getString(_tokenKey);
  }

  /// Check if user is logged in
  bool get isLoggedIn => getToken() != null && getToken()!.isNotEmpty;

  /// Clear authentication token
  Future<bool> clearToken() async {
    return await prefs.remove(_tokenKey);
  }

  // USER DATA MANAGEMENT

  /// Save user data
  Future<bool> saveUser(UserModelLokin user) async {
    final userJson = jsonEncode(user.toJson());
    return await prefs.setString(_userKey, userJson);
  }

  /// Get user data
  UserModelLokin? getUser() {
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson);
        return UserModelLokin.fromJson(userMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear user data
  Future<bool> clearUser() async {
    return await prefs.remove(_userKey);
  }

  // THEME MANAGEMENT

  /// Save dark mode preference
  Future<bool> setDarkMode(bool isDarkMode) async {
    return await prefs.setBool(_isDarkModeKey, isDarkMode);
  }

  /// Get dark mode preference
  bool get isDarkMode => prefs.getBool(_isDarkModeKey) ?? false;

  // FIRST TIME USER

  /// Check if this is first time opening the app
  bool get isFirstTime => prefs.getBool(_isFirstTimeKey) ?? true;

  /// Mark app as opened before
  Future<bool> setNotFirstTime() async {
    return await prefs.setBool(_isFirstTimeKey, false);
  }

  // REMINDER SETTINGS

  /// Save reminder time (in 24-hour format, e.g., "08:00")
  Future<bool> setReminderTime(String time) async {
    return await prefs.setString(_reminderTimeKey, time);
  }

  /// Get reminder time
  String get reminderTime => prefs.getString(_reminderTimeKey) ?? "08:00";

  /// Save reminder enabled status
  Future<bool> setReminderEnabled(bool enabled) async {
    return await prefs.setBool(_reminderEnabledKey, enabled);
  }

  /// Get reminder enabled status
  bool get isReminderEnabled => prefs.getBool(_reminderEnabledKey) ?? true;

  // LANGUAGE SETTINGS

  /// Save language preference
  Future<bool> setLanguage(String languageCode) async {
    return await prefs.setString(_languageKey, languageCode);
  }

  /// Get language preference
  String get language => prefs.getString(_languageKey) ?? 'id';

  // NOTIFICATION SETTINGS

  /// Save notification enabled status
  Future<bool> setNotificationEnabled(bool enabled) async {
    return await prefs.setBool(_notificationEnabledKey, enabled);
  }

  /// Get notification enabled status
  bool get isNotificationEnabled =>
      prefs.getBool(_notificationEnabledKey) ?? true;

  // BULK OPERATIONS

  /// Clear all user-related data (for logout)
  Future<void> clearAllUserData() async {
    await Future.wait([clearToken(), clearUser()]);
  }

  /// Clear all app data (for reset/reinstall)
  Future<void> clearAllData() async {
    await prefs.clear();
  }

  // UTILITY METHODS

  /// Get all stored preferences (for debugging)
  Map<String, dynamic> getAllPreferences() {
    final keys = prefs.getKeys();
    final Map<String, dynamic> preferences = {};

    for (String key in keys) {
      final value = prefs.get(key);
      preferences[key] = value;
    }

    return preferences;
  }

  /// Check if a specific key exists
  bool hasKey(String key) {
    return prefs.containsKey(key);
  }

  /// Remove a specific key
  Future<bool> removeKey(String key) async {
    return await prefs.remove(key);
  }

  // BACKUP AND RESTORE (Advanced feature)

  /// Create backup of user preferences
  Map<String, dynamic> createBackup() {
    return {
      'isDarkMode': isDarkMode,
      'reminderTime': reminderTime,
      'isReminderEnabled': isReminderEnabled,
      'language': language,
      'isNotificationEnabled': isNotificationEnabled,
    };
  }

  /// Restore preferences from backup
  Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    if (backup.containsKey('isDarkMode')) {
      await setDarkMode(backup['isDarkMode']);
    }
    if (backup.containsKey('reminderTime')) {
      await setReminderTime(backup['reminderTime']);
    }
    if (backup.containsKey('isReminderEnabled')) {
      await setReminderEnabled(backup['isReminderEnabled']);
    }
    if (backup.containsKey('language')) {
      await setLanguage(backup['language']);
    }
    if (backup.containsKey('isNotificationEnabled')) {
      await setNotificationEnabled(backup['isNotificationEnabled']);
    }
  }
}

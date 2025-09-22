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

  // ================= TOKEN MANAGEMENT =================

  Future<bool> saveToken(String token) async {
    return await prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return prefs.getString(_tokenKey);
  }

  bool get isLoggedIn => getToken() != null && getToken()!.isNotEmpty;

  Future<bool> clearToken() async {
    return await prefs.remove(_tokenKey);
  }

  // ================= USER DATA MANAGEMENT =================

  Future<bool> saveUser(UserModelLokin user) async {
    final userJson = jsonEncode(user.toJson());
    return await prefs.setString(_userKey, userJson);
  }

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

  Future<bool> clearUser() async {
    return await prefs.remove(_userKey);
  }

  // ================= THEME MANAGEMENT =================

  Future<bool> setDarkMode(bool isDarkMode) async {
    return await prefs.setBool(_isDarkModeKey, isDarkMode);
  }

  bool get isDarkMode => prefs.getBool(_isDarkModeKey) ?? false;

  // ================= FIRST TIME USER =================

  bool get isFirstTime => prefs.getBool(_isFirstTimeKey) ?? true;

  Future<bool> setNotFirstTime() async {
    return await prefs.setBool(_isFirstTimeKey, false);
  }

  // ================= REMINDER SETTINGS =================

  Future<bool> setReminderTime(String time) async {
    return await prefs.setString(_reminderTimeKey, time);
  }

  String get reminderTime => prefs.getString(_reminderTimeKey) ?? "08:00";

  Future<bool> setReminderEnabled(bool enabled) async {
    return await prefs.setBool(_reminderEnabledKey, enabled);
  }

  bool get isReminderEnabled => prefs.getBool(_reminderEnabledKey) ?? true;

  // ================= LANGUAGE SETTINGS =================

  Future<bool> setLanguage(String languageCode) async {
    return await prefs.setString(_languageKey, languageCode);
  }

  String get language => prefs.getString(_languageKey) ?? 'id';

  // ================= NOTIFICATION SETTINGS =================

  Future<bool> setNotificationEnabled(bool enabled) async {
    return await prefs.setBool(_notificationEnabledKey, enabled);
  }

  bool get isNotificationEnabled =>
      prefs.getBool(_notificationEnabledKey) ?? true;

  // ================= BULK OPERATIONS =================

  Future<void> clearAllUserData() async {
    await Future.wait([clearToken(), clearUser()]);
  }

  Future<void> clearAllData() async {
    await prefs.clear();
  }

  // ================= UTILITY METHODS =================

  Map<String, dynamic> getAllPreferences() {
    final keys = prefs.getKeys();
    final Map<String, dynamic> preferences = {};
    for (String key in keys) {
      preferences[key] = prefs.get(key);
    }
    return preferences;
  }

  bool hasKey(String key) {
    return prefs.containsKey(key);
  }

  Future<bool> removeKey(String key) async {
    return await prefs.remove(key);
  }

  // ================= BACKUP & RESTORE =================

  Map<String, dynamic> createBackup() {
    return {
      'isDarkMode': isDarkMode,
      'reminderTime': reminderTime,
      'isReminderEnabled': isReminderEnabled,
      'language': language,
      'isNotificationEnabled': isNotificationEnabled,
    };
  }

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

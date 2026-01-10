import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Mode Settings
enum ThemeSetting {
  light('Light', 'Clean, bright interface'),
  dark('Dark', 'Easy on the eyes'),
  system('System', 'Match device settings');

  final String label;
  final String description;

  const ThemeSetting(this.label, this.description);

  ThemeMode get themeMode {
    switch (this) {
      case ThemeSetting.light:
        return ThemeMode.light;
      case ThemeSetting.dark:
        return ThemeMode.dark;
      case ThemeSetting.system:
        return ThemeMode.system;
    }
  }

  static ThemeSetting fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeSetting.light;
      case 'dark':
        return ThemeSetting.dark;
      case 'system':
        return ThemeSetting.system;
      default:
        return ThemeSetting.light; // Default to light
    }
  }
}

/// Service for managing user preferences
class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;
  
  // Keys
  static const String _keyUserName = 'user_name';
  static const String _keyUserDob = 'user_dob';
  static const String _keyUserAvatar = 'user_avatar';
  static const String _keyCustomAvatarPath = 'custom_avatar_path';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyThemeSetting = 'theme_setting';
  static const String _keyUseDynamicColor = 'use_dynamic_color';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyPriceAlerts = 'price_alerts';
  static const String _keyHasSeenWelcome = 'has_seen_welcome';
  static const String _keyHasSeenLoading = 'has_seen_loading';

  /// Initialize the preferences service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// User Name
  String get userName => _prefs?.getString(_keyUserName) ?? 'Investor';
  Future<void> setUserName(String name) async {
    await _prefs?.setString(_keyUserName, name);
  }

  /// User Date of Birth
  DateTime? get userDob {
    final timestamp = _prefs?.getInt(_keyUserDob);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  Future<void> setUserDob(DateTime? dob) async {
    if (dob != null) {
      await _prefs?.setInt(_keyUserDob, dob.millisecondsSinceEpoch);
    } else {
      await _prefs?.remove(_keyUserDob);
    }
  }

  /// User Avatar Index (0-11 for different financial icons)
  int get userAvatarIndex => _prefs?.getInt(_keyUserAvatar) ?? 0;
  Future<void> setUserAvatarIndex(int index) async {
    await _prefs?.setInt(_keyUserAvatar, index);
  }

  /// Custom Avatar Image Path
  String? get customAvatarPath => _prefs?.getString(_keyCustomAvatarPath);
  Future<void> setCustomAvatarPath(String? path) async {
    if (path != null) {
      await _prefs?.setString(_keyCustomAvatarPath, path);
    } else {
      await _prefs?.remove(_keyCustomAvatarPath);
    }
  }

  /// Theme Setting (Light, Dark, System)
  ThemeSetting get themeSetting {
    final value = _prefs?.getString(_keyThemeSetting);
    if (value != null) {
      return ThemeSetting.fromString(value);
    }
    // Migration from old isDarkMode setting
    final isDark = _prefs?.getBool(_keyDarkMode);
    if (isDark != null) {
      return isDark ? ThemeSetting.dark : ThemeSetting.light;
    }
    return ThemeSetting.light; // Default to light
  }
  
  Future<void> setThemeSetting(ThemeSetting setting) async {
    await _prefs?.setString(_keyThemeSetting, setting.name);
    // Also update legacy key for compatibility
    await _prefs?.setBool(_keyDarkMode, setting == ThemeSetting.dark);
  }

  /// Use Dynamic Color (Material You)
  /// Only applies when theme setting is 'system'
  bool get useDynamicColor => _prefs?.getBool(_keyUseDynamicColor) ?? false;
  Future<void> setUseDynamicColor(bool value) async {
    await _prefs?.setBool(_keyUseDynamicColor, value);
  }

  /// Dark Mode (legacy, kept for compatibility)
  bool get isDarkMode => _prefs?.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(_keyDarkMode, value);
  }

  /// Notifications Enabled
  bool get notificationsEnabled => _prefs?.getBool(_keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_keyNotificationsEnabled, value);
  }

  /// Price Alerts
  bool get priceAlertsEnabled => _prefs?.getBool(_keyPriceAlerts) ?? true;
  Future<void> setPriceAlertsEnabled(bool value) async {
    await _prefs?.setBool(_keyPriceAlerts, value);
  }

  /// Has Seen Welcome Screen
  bool get hasSeenWelcome => _prefs?.getBool(_keyHasSeenWelcome) ?? false;
  Future<void> setHasSeenWelcome(bool value) async {
    await _prefs?.setBool(_keyHasSeenWelcome, value);
  }

  /// Has Seen Loading Screen (for first launch data fetch)
  bool get hasSeenLoading => _prefs?.getBool(_keyHasSeenLoading) ?? false;
  Future<void> setHasSeenLoading(bool value) async {
    await _prefs?.setBool(_keyHasSeenLoading, value);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class PreferencesService extends ChangeNotifier {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;
  
  static const String _keyTheme = 'theme_setting';
  static const String _keyUseDynamicColor = 'use_dynamic_color';
  static const String _keyUserName = 'user_name';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyPriceAlerts = 'price_alerts_enabled';
  static const String _keyHasSeenWelcome = 'has_seen_welcome';
  static const String _keyPrivacyMode = 'privacy_mode_enabled';
  // New Profile Keys
  static const String _keyUserDob = 'user_dob';
  static const String _keyUserAvatarIndex = 'user_avatar_index';
  static const String _keyCustomAvatarPath = 'custom_avatar_path';

  ThemeSetting _themeSetting = ThemeSetting.light;
  ThemeSetting get themeSetting => _themeSetting;

  bool _useDynamicColor = false;
  bool get useDynamicColor => _useDynamicColor;

  String _userName = '';
  String get userName => _userName;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _priceAlertsEnabled = true;
  bool get priceAlertsEnabled => _priceAlertsEnabled;

  bool _hasSeenWelcome = false;
  bool get hasSeenWelcome => _hasSeenWelcome;

  bool _isPrivacyModeEnabled = false;
  bool get isPrivacyModeEnabled => _isPrivacyModeEnabled;

  // New Profile Properties
  DateTime? _userDob;
  DateTime? get userDob => _userDob;

  int _userAvatarIndex = 0;
  int get userAvatarIndex => _userAvatarIndex;

  String? _customAvatarPath;
  String? get customAvatarPath => _customAvatarPath;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    final themeIndex = _prefs?.getInt(_keyTheme) ?? 0;
    _themeSetting = ThemeSetting.values[themeIndex];
    
    _useDynamicColor = _prefs?.getBool(_keyUseDynamicColor) ?? false;
    _userName = _prefs?.getString(_keyUserName) ?? '';
    _notificationsEnabled = _prefs?.getBool(_keyNotifications) ?? true;
    _priceAlertsEnabled = _prefs?.getBool(_keyPriceAlerts) ?? true;
    _hasSeenWelcome = _prefs?.getBool(_keyHasSeenWelcome) ?? false;
    _isPrivacyModeEnabled = _prefs?.getBool(_keyPrivacyMode) ?? false;
    
    // Load Profile Data
    final dobMillis = _prefs?.getInt(_keyUserDob);
    _userDob = dobMillis != null ? DateTime.fromMillisecondsSinceEpoch(dobMillis) : null;
    _userAvatarIndex = _prefs?.getInt(_keyUserAvatarIndex) ?? 0;
    _customAvatarPath = _prefs?.getString(_keyCustomAvatarPath);
    
    notifyListeners();
  }

  Future<void> setThemeSetting(ThemeSetting setting) async {
    _themeSetting = setting;
    await _prefs?.setInt(_keyTheme, setting.index);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    await _prefs?.setBool(_keyUseDynamicColor, value);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await _prefs?.setString(_keyUserName, name);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool(_keyNotifications, value);
    notifyListeners();
  }

  Future<void> setPriceAlertsEnabled(bool value) async {
    _priceAlertsEnabled = value;
    await _prefs?.setBool(_keyPriceAlerts, value);
    notifyListeners();
  }

  Future<void> setHasSeenWelcome(bool value) async {
    _hasSeenWelcome = value;
    await _prefs?.setBool(_keyHasSeenWelcome, value);
    notifyListeners();
  }

  Future<void> togglePrivacyMode() async {
    _isPrivacyModeEnabled = !_isPrivacyModeEnabled;
    await _prefs?.setBool(_keyPrivacyMode, _isPrivacyModeEnabled);
    notifyListeners();
  }

  // New Profile Setters
  Future<void> setUserDob(DateTime? date) async {
    _userDob = date;
    if (date != null) {
      await _prefs?.setInt(_keyUserDob, date.millisecondsSinceEpoch);
    } else {
      await _prefs?.remove(_keyUserDob);
    }
    notifyListeners();
  }

  Future<void> setUserAvatarIndex(int index) async {
    _userAvatarIndex = index;
    await _prefs?.setInt(_keyUserAvatarIndex, index);
    notifyListeners();
  }

  Future<void> setCustomAvatarPath(String? path) async {
    _customAvatarPath = path;
    if (path != null) {
      await _prefs?.setString(_keyCustomAvatarPath, path);
    } else {
      await _prefs?.remove(_keyCustomAvatarPath);
    }
    notifyListeners();
  }
}
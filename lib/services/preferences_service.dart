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
  // New Key for Privacy Mode
  static const String _keyPrivacyMode = 'privacy_mode_enabled';

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

  // New Property
  bool _isPrivacyModeEnabled = false;
  bool get isPrivacyModeEnabled => _isPrivacyModeEnabled;

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

  // Toggle Privacy Mode
  Future<void> togglePrivacyMode() async {
    _isPrivacyModeEnabled = !_isPrivacyModeEnabled;
    await _prefs?.setBool(_keyPrivacyMode, _isPrivacyModeEnabled);
    notifyListeners();
  }
}
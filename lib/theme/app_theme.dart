import 'package:flutter/material.dart';

enum ThemeSetting {
  light,
  dark,
  system,
}

extension ThemeSettingExtension on ThemeSetting {
  String get label {
    switch (this) {
      case ThemeSetting.light:
        return 'Light Mode';
      case ThemeSetting.dark:
        return 'Dark Mode';
      case ThemeSetting.system:
        return 'System Default';
    }
  }
  
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
}

class AppTheme {
  // --- Brand Colors ---
  static const Color robinhoodGreen = Color(0xFF00C805);
  static const Color robinhoodRed = Color(0xFFFF5000);
  static const Color goldPrimary = Color(0xFFFFD700); // Added for Gold
  
  // --- Chart Colors ---
  static const Color chartGreen = Color(0xFF00C805);
  static const Color chartRed = Color(0xFFFF5000);
  
  // --- Backgrounds & Surfaces ---
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color darkBackground = Color(0xFF000000);
  
  static const Color lightCard = Colors.white;
  static const Color darkCard = Color(0xFF1E1E1E);
  
  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF121212);
  
  // --- Text Colors ---
  static const Color lightText = Color(0xFF1F2937);
  static const Color darkText = Color(0xFFF3F4F6);
  static const Color mutedText = Color(0xFF6B7280);
}
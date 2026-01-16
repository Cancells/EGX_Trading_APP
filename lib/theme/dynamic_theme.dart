import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/preferences_service.dart';
import 'app_theme.dart';

class DynamicThemeProvider extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  
  ThemeSetting _themeSetting = ThemeSetting.system;
  bool _useDynamicColor = true;
  
  ThemeSetting get themeSetting => _themeSetting;
  bool get useDynamicColor => _useDynamicColor;
  ThemeMode get themeMode => _themeSetting.themeMode;

  void init() {
    _themeSetting = _prefs.themeSetting;
    _useDynamicColor = _prefs.useDynamicColor;
    notifyListeners();
  }

  Future<void> setThemeSetting(ThemeSetting setting) async {
    _themeSetting = setting;
    await _prefs.setThemeSetting(setting);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    await _prefs.setUseDynamicColor(value);
    notifyListeners();
  }

  ThemeData getLightTheme(ColorScheme? dynamicScheme) {
    if (_useDynamicColor && dynamicScheme != null) {
      return _buildTheme(dynamicScheme, Brightness.light);
    }
    return _buildTheme(BrandColors.lightScheme, Brightness.light);
  }

  ThemeData getDarkTheme(ColorScheme? dynamicScheme) {
    if (_useDynamicColor && dynamicScheme != null) {
      return _buildTheme(dynamicScheme, Brightness.dark);
    }
    return _buildTheme(BrandColors.darkScheme, Brightness.dark);
  }

  ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      
      // Removed manual CardTheme configuration to avoid version conflicts. 
      // Material 3 handles card styling automatically.
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
    );
  }
}

class BrandColors {
  static ColorScheme get lightScheme => ColorScheme.light(
    primary: AppTheme.robinhoodGreen,
    onPrimary: Colors.white,
    secondary: const Color(0xFF1F2937),
    surface: AppTheme.lightSurface,
    error: AppTheme.robinhoodRed,
  );

  static ColorScheme get darkScheme => ColorScheme.dark(
    primary: AppTheme.robinhoodGreen,
    onPrimary: Colors.black,
    secondary: const Color(0xFF059669),
    surface: AppTheme.darkSurface,
    error: AppTheme.robinhoodRed,
  );
}
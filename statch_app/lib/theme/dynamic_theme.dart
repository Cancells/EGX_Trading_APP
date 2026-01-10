import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/preferences_service.dart';
import 'app_theme.dart';

/// Dynamic Theme Provider for Material You support with 3-way theme setting
class DynamicThemeProvider extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  
  ColorScheme? _lightDynamic;
  ColorScheme? _darkDynamic;
  ThemeSetting _themeSetting = ThemeSetting.light;
  bool _useDynamicColor = false;
  
  ThemeSetting get themeSetting => _themeSetting;
  bool get useDynamicColor => _useDynamicColor;
  bool get supportsDynamicColor => _lightDynamic != null;
  
  ColorScheme? get lightDynamicScheme => _lightDynamic;
  ColorScheme? get darkDynamicScheme => _darkDynamic;

  ThemeMode get themeMode => _themeSetting.themeMode;

  /// Initialize from saved preferences
  void init() {
    _themeSetting = _prefs.themeSetting;
    _useDynamicColor = _prefs.useDynamicColor;
  }

  void setDynamicSchemes(ColorScheme? light, ColorScheme? dark) {
    _lightDynamic = light;
    _darkDynamic = dark;
    notifyListeners();
  }

  /// Set theme setting (Light, Dark, System)
  Future<void> setThemeSetting(ThemeSetting setting) async {
    _themeSetting = setting;
    await _prefs.setThemeSetting(setting);
    notifyListeners();
  }

  /// Toggle dynamic color (only applies when System theme is selected)
  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    await _prefs.setUseDynamicColor(value);
    notifyListeners();
  }

  /// Legacy toggle for compatibility
  void toggleDynamicColor(bool value) {
    setUseDynamicColor(value);
  }

  /// Check if dynamic color should be applied
  /// Only applies when theme is set to System/Dynamic AND useDynamicColor is true
  bool get shouldUseDynamicColor {
    return _themeSetting == ThemeSetting.system && _useDynamicColor && supportsDynamicColor;
  }

  /// Get the appropriate light theme
  ThemeData getLightTheme() {
    if (shouldUseDynamicColor && _lightDynamic != null) {
      return _buildThemeFromScheme(_lightDynamic!, Brightness.light);
    }
    return _buildBrandTheme(Brightness.light);
  }

  /// Get the appropriate dark theme
  ThemeData getDarkTheme() {
    if (shouldUseDynamicColor && _darkDynamic != null) {
      return _buildThemeFromScheme(_darkDynamic!, Brightness.dark);
    }
    return _buildBrandTheme(Brightness.dark);
  }

  /// Build theme using our custom Emerald Green brand palette
  ThemeData _buildBrandTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? BrandColors.darkScheme : BrandColors.lightScheme;
    return _buildThemeFromScheme(scheme, brightness);
  }

  ThemeData _buildThemeFromScheme(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? Colors.black : const Color(0xFFFAFAFA),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: _buildTextTheme(textColor),
      iconTheme: IconThemeData(
        color: textColor,
        size: 24,
      ),
      dividerColor: isDark ? Colors.white12 : Colors.black12,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      // Page transitions for smooth navigation
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
      displaySmall: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textColor),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: textColor),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: textColor.withValues(alpha: 0.7)),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.7)),
    );
  }
}

/// Brand color scheme for our custom Emerald Green palette
class BrandColors {
  static const Color emeraldPrimary = Color(0xFF00C805);
  static const Color emeraldLight = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  
  static const Color charcoalPrimary = Color(0xFF1F2937);
  static const Color charcoalLight = Color(0xFF374151);
  static const Color charcoalDark = Color(0xFF111827);
  
  static ColorScheme get lightScheme => ColorScheme.light(
    primary: emeraldPrimary,
    onPrimary: Colors.white,
    primaryContainer: emeraldLight.withValues(alpha: 0.2),
    onPrimaryContainer: emeraldDark,
    secondary: charcoalPrimary,
    onSecondary: Colors.white,
    secondaryContainer: charcoalLight.withValues(alpha: 0.1),
    onSecondaryContainer: charcoalDark,
    surface: Colors.white,
    onSurface: charcoalPrimary,
    error: const Color(0xFFFF5000),
    onError: Colors.white,
  );

  static ColorScheme get darkScheme => ColorScheme.dark(
    primary: emeraldPrimary,
    onPrimary: Colors.black,
    primaryContainer: emeraldDark.withValues(alpha: 0.3),
    onPrimaryContainer: emeraldLight,
    secondary: charcoalLight,
    onSecondary: Colors.white,
    secondaryContainer: charcoalDark.withValues(alpha: 0.5),
    onSecondaryContainer: Colors.white70,
    surface: const Color(0xFF1A1A1A),
    onSurface: Colors.white,
    error: const Color(0xFFFF5000),
    onError: Colors.white,
  );
}

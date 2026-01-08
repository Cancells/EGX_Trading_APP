import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';
import 'widgets/error_overlay.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize preferences
    await PreferencesService().init();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    runApp(const StatchApp());
  }, (error, stackTrace) {
    // Global error handler
    ErrorOverlay.showErrorWithAutoDismiss(
      error.toString(),
      duration: const Duration(seconds: 8),
    );
    debugPrint('ERROR: $error');
    debugPrint('STACK TRACE: $stackTrace');
  });
}

class StatchApp extends StatefulWidget {
  const StatchApp({super.key});

  @override
  State<StatchApp> createState() => _StatchAppState();
}

class _StatchAppState extends State<StatchApp> {
  final PreferencesService _prefsService = PreferencesService();
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _prefsService.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _prefsService.isDarkMode ? ThemeMode.dark : ThemeMode.light;
      
      // Update system UI overlay style based on theme
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _themeMode == ThemeMode.dark 
              ? Brightness.light 
              : Brightness.dark,
          systemNavigationBarColor: _themeMode == ThemeMode.dark 
              ? Colors.black 
              : Colors.white,
          systemNavigationBarIconBrightness: _themeMode == ThemeMode.dark 
              ? Brightness.light 
              : Brightness.dark,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Statch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        // Wrap with error overlay for debugging
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: ErrorOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: DashboardScreen(
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

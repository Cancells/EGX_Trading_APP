import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';
import 'services/investment_service.dart';
import 'services/pin_service.dart';
import 'services/currency_service.dart';
import 'theme/dynamic_theme.dart';
import 'widgets/error_overlay.dart';
import 'screens/welcome_screen.dart';
import 'screens/security_gate_screen.dart';
import 'screens/main_shell.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize services
    await PreferencesService().init();
    await InvestmentService().init();
    await PinService().init();
    await CurrencyService().init();
    
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
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DynamicThemeProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyService()),
        ],
        child: const StatchApp(),
      ),
    );
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
  final PinService _pinService = PinService();
  
  late ThemeMode _themeMode;
  AppState _appState = AppState.loading;

  @override
  void initState() {
    super.initState();
    _themeMode = _prefsService.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Determine initial app state
    if (!_prefsService.hasSeenWelcome) {
      setState(() => _appState = AppState.welcome);
    } else if (_pinService.isSecurityEnabled && (_pinService.isPinSet || _pinService.isBiometricEnabled)) {
      setState(() => _appState = AppState.securityGate);
    } else {
      setState(() => _appState = AppState.authenticated);
    }
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

  void _onWelcomeComplete() async {
    await _prefsService.setHasSeenWelcome(true);
    
    // Check if security should be shown
    if (_pinService.isSecurityEnabled && (_pinService.isPinSet || _pinService.isBiometricEnabled)) {
      setState(() => _appState = AppState.securityGate);
    } else {
      setState(() => _appState = AppState.authenticated);
    }
  }

  void _onAuthenticated() {
    setState(() => _appState = AppState.authenticated);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Update dynamic theme provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final themeProvider = context.read<DynamicThemeProvider>();
          themeProvider.setDynamicSchemes(lightDynamic, darkDynamic);
        });

        return Consumer<DynamicThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'Statch',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.getLightTheme(),
              darkTheme: themeProvider.getDarkTheme(),
              themeMode: _themeMode,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: ErrorOverlay(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: _buildHomeWidget(),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeWidget() {
    switch (_appState) {
      case AppState.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AppState.welcome:
        return WelcomeScreen(onGetStarted: _onWelcomeComplete);
      case AppState.securityGate:
        return SecurityGateScreen(onAuthenticated: _onAuthenticated);
      case AppState.authenticated:
        return MainShell(onThemeToggle: _toggleTheme);
    }
  }
}

enum AppState {
  loading,
  welcome,
  securityGate,
  authenticated,
}

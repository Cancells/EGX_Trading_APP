import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';
import 'services/investment_service.dart';
import 'services/pin_service.dart';
import 'services/currency_service.dart';
import 'services/market_data_service.dart'; // Import this
import 'theme/dynamic_theme.dart';
import 'widgets/error_overlay.dart';
import 'screens/welcome_screen.dart';
import 'screens/security_gate_screen.dart';
import 'screens/app_loading_screen.dart';
import 'screens/main_shell.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize services
    await PreferencesService().init();
    await InvestmentService().init();
    await PinService().init();
    await CurrencyService().init();
    
    // Initialize theme provider with saved preferences
    final themeProvider = DynamicThemeProvider();
    themeProvider.init();
    
    // Set system UI overlay style based on theme
    final isDark = themeProvider.themeSetting == ThemeSetting.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => CurrencyService()),
          // Added MarketDataService here for global access
          Provider(create: (_) => MarketDataService()), 
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
  
  AppState _appState = AppState.loading;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!_prefsService.hasSeenWelcome) {
      setState(() => _appState = AppState.welcome);
    } else {
      setState(() => _appState = AppState.loading);
    }
  }

  void _updateSystemUI(DynamicThemeProvider themeProvider) {
    final brightness = themeProvider.themeSetting == ThemeSetting.dark
        ? Brightness.dark
        : themeProvider.themeSetting == ThemeSetting.light
            ? Brightness.light
            : MediaQuery.of(context).platformBrightness;
    
    final isDark = brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  void _onWelcomeComplete() async {
    await _prefsService.setHasSeenWelcome(true);
    setState(() => _appState = AppState.loading);
  }

  void _onLoadingComplete() {
    setState(() => _appState = AppState.authenticated);
  }

  void _onSecurityRequired() {
    setState(() => _appState = AppState.securityGate);
  }

  void _onAuthenticated() {
    setState(() => _appState = AppState.authenticated);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final themeProvider = context.read<DynamicThemeProvider>();
          themeProvider.setDynamicSchemes(lightDynamic, darkDynamic);
          _updateSystemUI(themeProvider);
        });

        return Consumer<DynamicThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'Statch',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.getLightTheme(),
              darkTheme: themeProvider.getDarkTheme(),
              themeMode: themeProvider.themeMode,
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
        return AppLoadingScreen(
          onComplete: _onLoadingComplete,
          onSecurityRequired: _onSecurityRequired,
        );
      case AppState.welcome:
        return WelcomeScreen(onGetStarted: _onWelcomeComplete);
      case AppState.securityGate:
        return SecurityGateScreen(onAuthenticated: _onAuthenticated);
      case AppState.authenticated:
        return const MainShell();
    }
  }
}

enum AppState {
  loading,
  welcome,
  securityGate,
  authenticated,
}
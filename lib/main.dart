import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';
import 'services/investment_service.dart';
import 'services/pin_service.dart';
import 'services/currency_service.dart';
import 'services/market_data_service.dart'; 
import 'repositories/market_repository.dart';
import 'theme/dynamic_theme.dart';
import 'widgets/error_overlay.dart';
import 'screens/welcome_screen.dart';
import 'screens/security_gate_screen.dart';
import 'screens/app_loading_screen.dart';
import 'screens/dashboard_screen.dart'; // Updated to point to new Dashboard

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Services
    await PreferencesService().init();
    await InvestmentService().init();
    await PinService().init();
    
    final currencyService = CurrencyService();
    currencyService.init();
    
    final themeProvider = DynamicThemeProvider();
    themeProvider.init();
    
    final marketRepo = MarketRepository();
    marketRepo.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: currencyService),
          Provider(create: (_) => MarketDataService()),
          Provider.value(value: marketRepo), 
          ChangeNotifierProvider.value(value: InvestmentService()),
        ],
        child: const StatchApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('ERROR: $error');
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
    // 1. Dynamic Color Builder listens to system wallpaper
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Consumer<DynamicThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'Statch',
              debugShowCheckedModeBanner: false,
              
              // 2. Themes are generated based on system dynamic colors
              theme: themeProvider.getLightTheme(lightDynamic),
              darkTheme: themeProvider.getDarkTheme(darkDynamic),
              
              // 3. Theme Mode (Light/Dark/System) is respected
              themeMode: themeProvider.themeMode,
              
              builder: (context, child) {
                return ErrorOverlay(child: child ?? const SizedBox.shrink());
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
        return WelcomeScreen(onGetStarted: () async {
            await _prefsService.setHasSeenWelcome(true);
            setState(() => _appState = AppState.loading);
        });
      case AppState.securityGate:
        return SecurityGateScreen(onAuthenticated: _onAuthenticated);
      case AppState.authenticated:
        // Pointing to your new DashboardScreen with glassmorphism
        return const DashboardScreen(); 
    }
  }
}

enum AppState { loading, welcome, securityGate, authenticated }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';

// Services
import 'services/preferences_service.dart';
import 'services/investment_service.dart';
import 'services/pin_service.dart';
import 'services/currency_service.dart';
import 'services/market_data_service.dart'; 
import 'repositories/market_repository.dart';

// Theme & UI
import 'theme/dynamic_theme.dart';
import 'widgets/error_overlay.dart';
import 'screens/welcome_screen.dart';
import 'screens/security_gate_screen.dart';
import 'screens/app_loading_screen.dart';
import 'screens/dashboard_screen.dart';
import 'models/market_data.dart'; 

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 1. Initialize Singletons/Services
    final prefsService = PreferencesService();
    await prefsService.init();

    final investmentService = InvestmentService();
    await investmentService.init();

    final pinService = PinService();
    await pinService.init();
    
    // 2. Load Static Data
    try {
      await EgyptianStocks.init(); 
    } catch (e) {
      debugPrint("Error initializing stocks: $e");
    }
    
    final currencyService = CurrencyService();
    currencyService.init();
    
    final themeProvider = DynamicThemeProvider();
    themeProvider.init();
    
    final marketRepo = MarketRepository();
    marketRepo.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: prefsService), 
          Provider.value(value: pinService),   
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: currencyService),
          ChangeNotifierProvider.value(value: investmentService),
          Provider(create: (_) => MarketDataService()),
          Provider.value(value: marketRepo), 
        ],
        child: const StatchApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('CRITICAL APP ERROR: $error');
  });
}

class StatchApp extends StatefulWidget {
  const StatchApp({super.key});

  @override
  State<StatchApp> createState() => _StatchAppState();
}

class _StatchAppState extends State<StatchApp> {
  final PreferencesService _prefsService = PreferencesService(); 
  
  // Start with a neutral state, NOT loading, to prevent flicker
  AppState _appState = AppState.loading; 

  @override
  void initState() {
    super.initState();
    _decideInitialScreen();
  }

  Future<void> _decideInitialScreen() async {
    // Ensure prefs are fully ready
    if (!_prefsService.hasSeenWelcome) {
      // If user hasn't seen welcome, FORCE welcome state
      setState(() => _appState = AppState.welcome);
    } else {
      // Otherwise, go to normal loading (which handles PIN check)
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
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Consumer<DynamicThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'Statch',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.getLightTheme(lightDynamic),
              darkTheme: themeProvider.getDarkTheme(darkDynamic),
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
        return WelcomeScreen(
          onGetStarted: () async {
            // User explicitly clicked "Get Started"
            await _prefsService.setHasSeenWelcome(true);
            setState(() => _appState = AppState.loading);
          },
        );
      case AppState.securityGate:
        return SecurityGateScreen(onAuthenticated: _onAuthenticated);
      case AppState.authenticated:
        return const DashboardScreen(); 
    }
  }
}

enum AppState { loading, welcome, securityGate, authenticated }
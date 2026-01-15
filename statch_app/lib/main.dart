import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';
import 'services/investment_service.dart';
import 'services/pin_service.dart';
import 'services/currency_service.dart';
import 'services/market_data_service.dart'; 
import 'repositories/market_repository.dart'; // Import the Repository
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
    
    final themeProvider = DynamicThemeProvider();
    themeProvider.init();
    
    // Create and initialize repository
    final marketRepo = MarketRepository();
    
    // We can fire-and-forget init here, or await it if we want data before app starts
    // For better UX, we start it here so it loads while splash screen runs
    marketRepo.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => CurrencyService()),
          Provider(create: (_) => MarketDataService()),
          // Provide the Repository globally
          Provider<MarketRepository>.value(value: marketRepo), 
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
        return WelcomeScreen(onGetStarted: _onWelcomeComplete);
      case AppState.securityGate:
        return SecurityGateScreen(onAuthenticated: _onAuthenticated);
      case AppState.authenticated:
        return const MainShell();
    }
  }
}

enum AppState { loading, welcome, securityGate, authenticated }
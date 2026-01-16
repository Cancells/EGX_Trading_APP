import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Services
import 'services/preferences_service.dart';
import 'services/investment_service.dart';
import 'services/pin_service.dart';
import 'services/currency_service.dart';
import 'services/market_data_service.dart';
import 'repositories/market_repository.dart';

// UI
import 'screens/portfolio_screen.dart';
import 'screens/add_investment_screen.dart'; // Assume this exists based on context
import 'widgets/error_overlay.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set system overlay to transparent for full edge-to-edge glass effect
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));

    // Initialize Services
    final prefsService = PreferencesService();
    await prefsService.init();

    final investmentService = InvestmentService();
    await investmentService.init();

    final pinService = PinService();
    await pinService.init();

    final currencyService = CurrencyService();
    currencyService.init();

    final marketRepo = MarketRepository();
    marketRepo.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: prefsService),
          Provider.value(value: pinService),
          ChangeNotifierProvider.value(value: currencyService),
          ChangeNotifierProvider.value(value: investmentService),
          Provider(create: (_) => MarketDataService()),
          Provider.value(value: marketRepo),
        ],
        child: const StatchApp(),
      ),
    );
  }, (error, stack) => debugPrint('App Error: $error'));
}

class StatchApp extends StatelessWidget {
  const StatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Statch',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system, // Respects system setting
          // Fixed: Properly implement Material 3 Dynamic Color with fallback
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightDynamic ?? ColorScheme.fromSeed(
              seedColor: const Color(0xFF00C805), // Brand Green
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            textTheme: GoogleFonts.interTextTheme(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic ?? ColorScheme.fromSeed(
              seedColor: const Color(0xFF00C805),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF000000),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const PortfolioScreen(), // Direct to Portfolio for this demo
        );
      },
    );
  }
}
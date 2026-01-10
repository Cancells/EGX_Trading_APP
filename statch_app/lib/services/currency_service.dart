import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Supported currencies
enum Currency {
  egp('EGP', 'E£', 'Egyptian Pound'),
  usd('USD', '\$', 'US Dollar'),
  eur('EUR', '€', 'Euro');

  final String code;
  final String symbol;
  final String name;

  const Currency(this.code, this.symbol, this.name);
}

/// Currency Service for exchange rate management
class CurrencyService extends ChangeNotifier {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static const String _keyBaseCurrency = 'base_currency';
  static const String _keyExchangeRates = 'exchange_rates';
  static const String _keyLastUpdate = 'exchange_rates_last_update';

  SharedPreferences? _prefs;
  Timer? _updateTimer;
  
  Currency _baseCurrency = Currency.egp;
  Map<String, double> _exchangeRates = {
    'EGP': 1.0,
    'USD': 0.0204,  // Default fallback rates
    'EUR': 0.0188,
  };
  DateTime? _lastUpdate;
  bool _isLoading = false;

  Currency get baseCurrency => _baseCurrency;
  Map<String, double> get exchangeRates => _exchangeRates;
  DateTime? get lastUpdate => _lastUpdate;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedData();
    await fetchExchangeRates();
    _startPeriodicUpdates();
  }

  void _loadSavedData() {
    // Load base currency
    final currencyCode = _prefs?.getString(_keyBaseCurrency);
    if (currencyCode != null) {
      _baseCurrency = Currency.values.firstWhere(
        (c) => c.code == currencyCode,
        orElse: () => Currency.egp,
      );
    }

    // Load cached exchange rates
    final ratesJson = _prefs?.getString(_keyExchangeRates);
    if (ratesJson != null) {
      try {
        _exchangeRates = Map<String, double>.from(json.decode(ratesJson));
      } catch (_) {}
    }

    // Load last update time
    final lastUpdateMs = _prefs?.getInt(_keyLastUpdate);
    if (lastUpdateMs != null) {
      _lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMs);
    }
  }

  Future<void> setBaseCurrency(Currency currency) async {
    _baseCurrency = currency;
    await _prefs?.setString(_keyBaseCurrency, currency.code);
    notifyListeners();
  }

  /// Fetch exchange rates from API
  Future<void> fetchExchangeRates() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Using exchangerate-api.com free tier (EGP base)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/EGP'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        _exchangeRates = {
          'EGP': 1.0,
          'USD': (rates['USD'] as num?)?.toDouble() ?? 0.0204,
          'EUR': (rates['EUR'] as num?)?.toDouble() ?? 0.0188,
        };

        _lastUpdate = DateTime.now();
        
        // Cache the rates
        await _prefs?.setString(_keyExchangeRates, json.encode(_exchangeRates));
        await _prefs?.setInt(_keyLastUpdate, _lastUpdate!.millisecondsSinceEpoch);
      }
    } catch (e) {
      // Use cached/default rates on error
      debugPrint('Failed to fetch exchange rates: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    // Update every 30 minutes
    _updateTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      fetchExchangeRates();
    });
  }

  /// Convert amount from EGP to base currency
  double convertFromEgp(double amountInEgp) {
    final rate = _exchangeRates[_baseCurrency.code] ?? 1.0;
    return amountInEgp * rate;
  }

  /// Convert amount from base currency to EGP
  double convertToEgp(double amount) {
    final rate = _exchangeRates[_baseCurrency.code] ?? 1.0;
    if (rate == 0) return amount;
    return amount / rate;
  }

  /// Convert between any two currencies
  double convert(double amount, Currency from, Currency to) {
    if (from == to) return amount;
    
    // Convert to EGP first, then to target
    final fromRate = _exchangeRates[from.code] ?? 1.0;
    final toRate = _exchangeRates[to.code] ?? 1.0;
    
    if (fromRate == 0) return amount;
    final inEgp = amount / fromRate;
    return inEgp * toRate;
  }

  /// Format amount with currency symbol
  String formatCurrency(double amount, {Currency? currency}) {
    final curr = currency ?? _baseCurrency;
    final formatted = amount.toStringAsFixed(2);
    return '${curr.symbol}$formatted';
  }

  /// Get EGP to USD rate
  double get egpToUsd => _exchangeRates['USD'] ?? 0.0204;

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

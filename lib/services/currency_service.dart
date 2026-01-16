import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// REQUIRED: This enum must be outside the class
enum Currency {
  egp('EGP', 'Egyptian Pound', 'E£'),
  usd('USD', 'US Dollar', '\$'),
  eur('EUR', 'Euro', '€'),
  sar('SAR', 'Saudi Riyal', 'SR'),
  aed('AED', 'UAE Dirham', 'DH');

  final String code;
  final String name;
  final String symbol;
  
  const Currency(this.code, this.name, this.symbol);
}

class CurrencyService extends ChangeNotifier {
  // Singleton
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // State
  double _usdToEgp = 50.60; 
  double get usdToEgp => _usdToEgp;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Currency _baseCurrency = Currency.egp;
  Currency get baseCurrency => _baseCurrency;
  
  DateTime? _lastUpdate;
  DateTime? get lastUpdate => _lastUpdate;

  Future<void> init() async {
    await fetchRates();
  }

  void setBaseCurrency(Currency currency) {
    _baseCurrency = currency;
    notifyListeners();
  }

  // Alias for fetchRates to match SettingsScreen usage
  Future<void> fetchExchangeRates() => fetchRates();

  Future<void> fetchRates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates']['EGP'] as num).toDouble();
        
        if (rate > 10) { 
          _usdToEgp = rate;
          _lastUpdate = DateTime.now();
          debugPrint('✅ Updated USD/EGP Rate: $_usdToEgp');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Currency Fetch Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
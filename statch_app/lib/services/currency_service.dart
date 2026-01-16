import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CurrencyService extends ChangeNotifier {
  // Default fallback if internet is down (Safe estimate)
  double _usdToEgp = 50.60; 
  double get usdToEgp => _usdToEgp;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Singleton approach so we can access it anywhere easily
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  /// Call this when the app starts
  Future<void> init() async {
    await fetchRates();
  }

  Future<void> fetchRates() async {
    _isLoading = true;
    notifyListeners(); // Tell UI we are loading

    try {
      // Using a free public API for exchange rates
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates']['EGP'] as num).toDouble();
        
        // Basic sanity check to prevent bad data crashing math
        if (rate > 10) { 
          _usdToEgp = rate;
          debugPrint('✅ Updated USD/EGP Rate: $_usdToEgp');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Currency Fetch Error: $e');
      // On error, we just keep the default/last known rate
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
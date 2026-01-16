import 'dart:async';
import 'package:flutter/foundation.dart';
import 'yahoo_finance_service.dart';

class GoldService {
  static final GoldService _instance = GoldService._internal();
  factory GoldService() => _instance;
  GoldService._internal();

  final YahooFinanceService _yahooService = YahooFinanceService();

  double _goldSpotUsd = 0.0;
  double _usdToEgp = 50.60;

  static const double _ounceToGram = 31.1035;
  static const double _karat24 = 1.0;
  static const double _karat21 = 0.875;
  static const double _karat18 = 0.750;

  Future<void> init() async {
    await fetchGoldPrices();
  }

  Future<void> fetchGoldPrices() async {
    try {
      final futures = await Future.wait([
        _yahooService.fetchQuote('GC=F'), 
        _yahooService.fetchQuote('EGP=X'), 
      ]);

      final goldQuote = futures[0];
      final egpQuote = futures[1];

      if (goldQuote != null) _goldSpotUsd = goldQuote.price;
      if (egpQuote != null) _usdToEgp = egpQuote.price;

    } catch (e) {
      debugPrint('Error fetching gold prices: $e');
    }
  }

  double? getPriceBySymbol(String symbol) {
    if (symbol == 'GOLD_24K') return _calculatePrice(_karat24);
    if (symbol == 'GOLD_21K') return _calculatePrice(_karat21);
    if (symbol == 'GOLD_18K') return _calculatePrice(_karat18);
    if (symbol == 'GOLD_POUND') return _calculatePrice(_karat21) * 8;
    return null;
  }

  double _calculatePrice(double purity) {
    if (_goldSpotUsd <= 0 || _usdToEgp <= 0) return 0.0;
    return (_goldSpotUsd / _ounceToGram) * _usdToEgp * purity;
  }

  static bool isGoldSymbol(String symbol) {
    return symbol.startsWith('GOLD_');
  }
}
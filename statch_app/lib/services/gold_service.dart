import 'dart:async';
import 'package:flutter/foundation.dart';
import 'yahoo_finance_service.dart';
import 'currency_service.dart';

/// Egyptian Gold Karat types
enum GoldKarat {
  k24(24, '24K', 'Pure Gold'),
  k21(21, '21K', 'Egyptian Standard'),
  k18(18, '18K', 'Jewelry Gold');

  final int value;
  final String label;
  final String description;

  const GoldKarat(this.value, this.label, this.description);
}

/// Egyptian Gold Price Model
class EgyptianGoldPrice {
  final GoldKarat karat;
  final double pricePerGram;
  final double previousPrice;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;

  EgyptianGoldPrice({
    required this.karat,
    required this.pricePerGram,
    required this.previousPrice,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });

  bool get isPositive => change >= 0;

  EgyptianGoldPrice copyWith({
    GoldKarat? karat,
    double? pricePerGram,
    double? previousPrice,
    double? change,
    double? changePercent,
    DateTime? lastUpdated,
  }) {
    return EgyptianGoldPrice(
      karat: karat ?? this.karat,
      pricePerGram: pricePerGram ?? this.pricePerGram,
      previousPrice: previousPrice ?? this.previousPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Gold Investment for tracking purchases
class GoldInvestment {
  final String id;
  final GoldKarat karat;
  final double grams;
  final double purchasePricePerGram;
  final DateTime purchaseDate;
  double currentPricePerGram;

  GoldInvestment({
    required this.id,
    required this.karat,
    required this.grams,
    required this.purchasePricePerGram,
    required this.purchaseDate,
    this.currentPricePerGram = 0,
  });

  double get totalInvested => purchasePricePerGram * grams;
  double get currentValue => currentPricePerGram * grams;
  double get profitLoss => currentValue - totalInvested;
  double get profitLossPercent {
    if (totalInvested == 0) return 0;
    return (profitLoss / totalInvested) * 100;
  }
  bool get isProfit => profitLoss >= 0;
}

/// Gold Service for Egyptian gold pricing
class GoldService extends ChangeNotifier {
  static final GoldService _instance = GoldService._internal();
  factory GoldService() => _instance;
  GoldService._internal();

  final YahooFinanceService _yahooService = YahooFinanceService();
  final CurrencyService _currencyService = CurrencyService();
  
  Timer? _updateTimer;
  bool _isLoading = false;
  String? _error;

  // Current USD gold spot price per ounce
  double _goldSpotUsd = 0;
  double _previousGoldSpotUsd = 0;
  
  // Egyptian gold prices
  final Map<GoldKarat, EgyptianGoldPrice> _prices = {};
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get goldSpotUsd => _goldSpotUsd;
  Map<GoldKarat, EgyptianGoldPrice> get prices => Map.unmodifiable(_prices);

  /// Initialize and start fetching prices
  Future<void> init() async {
    await fetchPrices();
    _startPeriodicUpdates();
  }

  /// Fetch current gold prices
  Future<void> fetchPrices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch gold spot price in USD (per troy ounce)
      final goldQuote = await _yahooService.fetchQuote('GC=F');
      
      if (goldQuote != null) {
        _previousGoldSpotUsd = _goldSpotUsd > 0 ? _goldSpotUsd : goldQuote.previousClose;
        _goldSpotUsd = goldQuote.price;
        
        // Convert to EGP per gram
        // 1 troy ounce = 31.1035 grams
        // Gold price per gram in USD = spot price / 31.1035
        // Gold price per gram in EGP = USD price / EGP_to_USD rate
        
        final usdPerGram = _goldSpotUsd / 31.1035;
        final previousUsdPerGram = _previousGoldSpotUsd / 31.1035;
        final egpRate = _currencyService.egpToUsd;
        
        // Convert to EGP (divide by rate since rate is EGP->USD)
        final egp24kPerGram = egpRate > 0 ? usdPerGram / egpRate : usdPerGram * 49;
        final previousEgp24kPerGram = egpRate > 0 ? previousUsdPerGram / egpRate : previousUsdPerGram * 49;
        
        final now = DateTime.now();
        
        // Calculate prices for each karat
        for (final karat in GoldKarat.values) {
          final factor = karat.value / 24;
          final pricePerGram = egp24kPerGram * factor;
          final previousPrice = previousEgp24kPerGram * factor;
          final change = pricePerGram - previousPrice;
          final changePercent = previousPrice > 0 ? (change / previousPrice) * 100 : 0.0;
          
          _prices[karat] = EgyptianGoldPrice(
            karat: karat,
            pricePerGram: pricePerGram,
            previousPrice: previousPrice,
            change: change,
            changePercent: changePercent,
            lastUpdated: now,
          );
        }
      } else {
        _error = 'Failed to fetch gold prices';
      }
    } catch (e) {
      _error = 'Error fetching gold prices: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchPrices();
    });
  }

  /// Get price for a specific karat
  EgyptianGoldPrice? getPrice(GoldKarat karat) => _prices[karat];

  /// Calculate value of gold investment
  double calculateValue(GoldKarat karat, double grams) {
    final price = _prices[karat];
    if (price == null) return 0;
    return price.pricePerGram * grams;
  }

  /// Calculate profit/loss for a gold investment
  double calculateProfitLoss({
    required GoldKarat karat,
    required double grams,
    required double purchasePricePerGram,
  }) {
    final currentPrice = _prices[karat]?.pricePerGram ?? 0;
    return (currentPrice - purchasePricePerGram) * grams;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

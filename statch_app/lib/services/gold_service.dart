import 'dart:async';
import 'package:flutter/foundation.dart';
import 'yahoo_finance_service.dart';

/// Egyptian Gold Karat types
enum GoldKarat {
  k24(24, '24K', 'Pure Gold', 1.0),
  k21(21, '21K', 'Egyptian Standard', 0.875),
  k18(18, '18K', 'Jewelry Gold', 0.750);

  final int value;
  final String label;
  final String description;
  final double purityFactor;

  const GoldKarat(this.value, this.label, this.description, this.purityFactor);
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

/// Gold Pound (Geneh) Price Model - 8 grams of 21K gold
class GoldPoundPrice {
  final double price;
  final double previousPrice;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;

  GoldPoundPrice({
    required this.price,
    required this.previousPrice,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });

  bool get isPositive => change >= 0;

  GoldPoundPrice copyWith({
    double? price,
    double? previousPrice,
    double? change,
    double? changePercent,
    DateTime? lastUpdated,
  }) {
    return GoldPoundPrice(
      price: price ?? this.price,
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

/// Constants for gold calculations
class GoldConstants {
  /// Troy ounce in grams
  static const double troyOunceInGrams = 31.1035;
  
  /// Gold Pound (Geneh) weight in grams (21K)
  static const double goldPoundGrams = 8.0;
  
  /// Default workmanship fee per gram (EGP)
  static const double defaultWorkmanshipFee = 75.0;
  
  /// Workmanship fee range
  static const double minWorkmanshipFee = 50.0;
  static const double maxWorkmanshipFee = 150.0;
}

/// Gold Service for Egyptian gold pricing
class GoldService extends ChangeNotifier {
  static final GoldService _instance = GoldService._internal();
  factory GoldService() => _instance;
  GoldService._internal();

  final YahooFinanceService _yahooService = YahooFinanceService();
  
  Timer? _updateTimer;
  bool _isLoading = false;
  String? _error;

  // Current USD gold spot price per ounce
  double _goldSpotUsd = 0;
  double _previousGoldSpotUsd = 0;
  
  // Current USD to EGP exchange rate
  double _usdToEgp = 49.0; // Default fallback
  double _previousUsdToEgp = 49.0;
  
  // Workmanship toggle
  bool _includeWorkmanship = false;
  double _workmanshipFee = GoldConstants.defaultWorkmanshipFee;
  
  // Egyptian gold prices
  final Map<GoldKarat, EgyptianGoldPrice> _prices = {};
  GoldPoundPrice? _goldPoundPrice;
  
  // Ounce price in EGP
  double _ounceEgp = 0;
  double _previousOunceEgp = 0;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get goldSpotUsd => _goldSpotUsd;
  double get usdToEgp => _usdToEgp;
  double get ounceEgp => _ounceEgp;
  Map<GoldKarat, EgyptianGoldPrice> get prices => Map.unmodifiable(_prices);
  GoldPoundPrice? get goldPoundPrice => _goldPoundPrice;
  bool get includeWorkmanship => _includeWorkmanship;
  double get workmanshipFee => _workmanshipFee;

  /// Get price with optional workmanship
  double getPriceWithWorkmanship(double rawPrice) {
    if (_includeWorkmanship) {
      return rawPrice + _workmanshipFee;
    }
    return rawPrice;
  }

  /// Toggle workmanship inclusion
  void toggleWorkmanship() {
    _includeWorkmanship = !_includeWorkmanship;
    notifyListeners();
  }

  /// Set workmanship toggle
  void setWorkmanship(bool value) {
    _includeWorkmanship = value;
    notifyListeners();
  }

  /// Set workmanship fee
  void setWorkmanshipFee(double fee) {
    _workmanshipFee = fee.clamp(
      GoldConstants.minWorkmanshipFee,
      GoldConstants.maxWorkmanshipFee,
    );
    notifyListeners();
  }

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
      // Fetch gold spot price in USD (per troy ounce) - GC=F
      final goldQuote = await _yahooService.fetchQuote('GC=F');
      
      // Fetch USD to EGP exchange rate - EGP=X
      final egpQuote = await _yahooService.fetchQuote('EGP=X');
      
      if (goldQuote != null) {
        _previousGoldSpotUsd = _goldSpotUsd > 0 ? _goldSpotUsd : goldQuote.previousClose;
        _goldSpotUsd = goldQuote.price;
      }
      
      if (egpQuote != null) {
        // EGP=X gives us USD to EGP rate
        _previousUsdToEgp = _usdToEgp > 0 ? _usdToEgp : egpQuote.previousClose;
        _usdToEgp = egpQuote.price;
      }
      
      if (_goldSpotUsd > 0 && _usdToEgp > 0) {
        // Calculate ounce price in EGP
        // Ounce_EGP = (GC=F price) * (EGP=X rate)
        _previousOunceEgp = _previousGoldSpotUsd * _previousUsdToEgp;
        _ounceEgp = _goldSpotUsd * _usdToEgp;
        
        // Calculate 24K gram price in EGP
        // 24K Gram = Ounce_EGP / 31.1035
        final egp24kPerGram = _ounceEgp / GoldConstants.troyOunceInGrams;
        final previousEgp24kPerGram = _previousOunceEgp / GoldConstants.troyOunceInGrams;
        
        final now = DateTime.now();
        
        // Calculate prices for each karat
        for (final karat in GoldKarat.values) {
          final pricePerGram = egp24kPerGram * karat.purityFactor;
          final previousPrice = previousEgp24kPerGram * karat.purityFactor;
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
        
        // Calculate Gold Pound (Geneh) price
        // Gold Pound = 21K_Gram * 8
        final gold21k = _prices[GoldKarat.k21];
        if (gold21k != null) {
          final poundPrice = gold21k.pricePerGram * GoldConstants.goldPoundGrams;
          final previousPoundPrice = gold21k.previousPrice * GoldConstants.goldPoundGrams;
          final poundChange = poundPrice - previousPoundPrice;
          final poundChangePercent = previousPoundPrice > 0 
              ? (poundChange / previousPoundPrice) * 100 
              : 0.0;
          
          _goldPoundPrice = GoldPoundPrice(
            price: poundPrice,
            previousPrice: previousPoundPrice,
            change: poundChange,
            changePercent: poundChangePercent,
            lastUpdated: now,
          );
        }
      } else {
        _error = 'Failed to fetch gold prices or exchange rate';
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

  /// Get display price for a karat (with or without workmanship)
  double getDisplayPrice(GoldKarat karat) {
    final price = _prices[karat];
    if (price == null) return 0;
    return getPriceWithWorkmanship(price.pricePerGram);
  }

  /// Get display price for gold pound (with or without workmanship)
  double getGoldPoundDisplayPrice() {
    if (_goldPoundPrice == null) return 0;
    // Workmanship for gold pound is per gram * 8
    if (_includeWorkmanship) {
      return _goldPoundPrice!.price + (_workmanshipFee * GoldConstants.goldPoundGrams);
    }
    return _goldPoundPrice!.price;
  }

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

  /// Get gold ticker symbol for a karat type
  String getGoldSymbol(GoldKarat karat) {
    switch (karat) {
      case GoldKarat.k24:
        return 'GOLD_24K';
      case GoldKarat.k21:
        return 'GOLD_21K';
      case GoldKarat.k18:
        return 'GOLD_18K';
    }
  }

  /// Get gold price by symbol
  double? getPriceBySymbol(String symbol) {
    switch (symbol) {
      case 'GOLD_24K':
        return _prices[GoldKarat.k24]?.pricePerGram;
      case 'GOLD_21K':
        return _prices[GoldKarat.k21]?.pricePerGram;
      case 'GOLD_18K':
        return _prices[GoldKarat.k18]?.pricePerGram;
      case 'GOLD_POUND':
        return _goldPoundPrice?.price;
      default:
        return null;
    }
  }

  /// Check if symbol is a gold symbol
  static bool isGoldSymbol(String symbol) {
    return symbol.startsWith('GOLD_');
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

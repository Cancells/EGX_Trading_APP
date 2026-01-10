import 'dart:async';
import 'dart:math';
import '../models/market_data.dart';

/// Mock Market Data Service for Egyptian Market (2026)
class MarketDataService {
  static final MarketDataService _instance = MarketDataService._internal();
  factory MarketDataService() => _instance;
  MarketDataService._internal();

  final Random _random = Random();
  Timer? _updateTimer;
  
  final _marketDataController = StreamController<MarketData>.broadcast();
  Stream<MarketData> get marketDataStream => _marketDataController.stream;

  // Base values for 2026 Egyptian Market
  static const double _baseEgx30 = 41500.0;
  static const double _baseGold24k = 6850.0;
  static const double _baseGold21k = 6000.0;
  static const double _baseGold18k = 5140.0;
  static const double _baseGoldPound = 48000.0; // 8g of 21K
  
  // Stock base prices in EGP
  static const Map<String, Map<String, dynamic>> _stockData = {
    'COMI': {'name': 'Commercial International Bank', 'basePrice': 98.50, 'sector': 'Banks'},
    'TMGH': {'name': 'Talaat Mostafa Group Holding', 'basePrice': 45.20, 'sector': 'Real Estate'},
    'ETEL': {'name': 'Telecom Egypt', 'basePrice': 32.80, 'sector': 'Telecom'},
    'FWRY': {'name': 'Fawry for Banking Technology', 'basePrice': 8.75, 'sector': 'Fintech'},
    'HRHO': {'name': 'EFG Hermes', 'basePrice': 22.50, 'sector': 'Financial Services'},
    'SWDY': {'name': 'El Sewedy Electric', 'basePrice': 18.30, 'sector': 'Industrial'},
    'ABUK': {'name': 'Abou Kir Fertilizers', 'basePrice': 35.60, 'sector': 'Basic Resources'},
    'PHDC': {'name': 'Palm Hills Developments', 'basePrice': 4.85, 'sector': 'Real Estate'},
  };

  MarketData? _currentData;
  MarketData? get currentData => _currentData;

  /// Generate realistic price history
  List<double> _generatePriceHistory(double basePrice, int points, double volatility) {
    List<double> history = [];
    double current = basePrice * (0.97 + _random.nextDouble() * 0.03);
    
    for (int i = 0; i < points; i++) {
      double change = ((_random.nextDouble() - 0.48) * volatility * basePrice);
      current += change;
      current = current.clamp(basePrice * 0.9, basePrice * 1.1);
      history.add(current);
    }
    
    return history;
  }

  /// Generate initial market data
  MarketData _generateInitialData() {
    final now = DateTime.now();
    
    // EGX 30 Index
    final egx30History = _generatePriceHistory(_baseEgx30, 50, 0.002);
    final egx30Value = egx30History.last;
    final egx30Change = egx30Value - egx30History.first;
    
    final egx30 = MarketIndex(
      name: 'EGX 30',
      symbol: 'EGX30',
      value: egx30Value,
      change: egx30Change,
      changePercent: (egx30Change / egx30History.first) * 100,
      priceHistory: egx30History,
      lastUpdated: now,
    );
    
    // Gold 24K
    final gold24kChange = (_random.nextDouble() - 0.45) * 50;
    final gold24k = GoldPrice(
      karat: '24K',
      pricePerGram: _baseGold24k + gold24kChange,
      change: gold24kChange,
      changePercent: (gold24kChange / _baseGold24k) * 100,
      lastUpdated: now,
      description: 'Pure Gold',
    );
    
    // Gold 21K
    final gold21kChange = (_random.nextDouble() - 0.45) * 40;
    final gold21k = GoldPrice(
      karat: '21K',
      pricePerGram: _baseGold21k + gold21kChange,
      change: gold21kChange,
      changePercent: (gold21kChange / _baseGold21k) * 100,
      lastUpdated: now,
      description: 'Egyptian Standard',
    );
    
    // Gold 18K
    final gold18kChange = (_random.nextDouble() - 0.45) * 35;
    final gold18k = GoldPrice(
      karat: '18K',
      pricePerGram: _baseGold18k + gold18kChange,
      change: gold18kChange,
      changePercent: (gold18kChange / _baseGold18k) * 100,
      lastUpdated: now,
      description: 'Jewelry Gold',
    );
    
    // Gold Pound (Geneh) - 8 grams of 21K
    final goldPoundChange = gold21kChange * 8;
    final goldPound = GoldPoundPriceData(
      price: _baseGoldPound + goldPoundChange,
      change: goldPoundChange,
      changePercent: (goldPoundChange / _baseGoldPound) * 100,
      lastUpdated: now,
    );
    
    // Stocks
    final stocks = _stockData.entries.map((entry) {
      final basePrice = entry.value['basePrice'] as double;
      final history = _generatePriceHistory(basePrice, 50, 0.005);
      final currentPrice = history.last;
      final change = currentPrice - history.first;
      
      return Stock(
        symbol: entry.key,
        name: entry.value['name'] as String,
        price: currentPrice,
        change: change,
        changePercent: (change / history.first) * 100,
        priceHistory: history,
        lastUpdated: now,
        sector: entry.value['sector'] as String?,
      );
    }).toList();
    
    return MarketData(
      egx30: egx30,
      gold24k: gold24k,
      gold21k: gold21k,
      gold18k: gold18k,
      goldPound: goldPound,
      stocks: stocks,
      lastUpdated: now,
    );
  }

  /// Update market data with small changes
  MarketData _updateData(MarketData current) {
    final now = DateTime.now();
    
    // Update EGX 30
    final egx30Change = ((_random.nextDouble() - 0.48) * 0.002 * current.egx30.value);
    final newEgx30Value = current.egx30.value + egx30Change;
    final newEgx30History = [...current.egx30.priceHistory.skip(1), newEgx30Value];
    final totalEgx30Change = newEgx30Value - newEgx30History.first;
    
    final egx30 = current.egx30.copyWith(
      value: newEgx30Value,
      change: totalEgx30Change,
      changePercent: (totalEgx30Change / newEgx30History.first) * 100,
      priceHistory: newEgx30History,
      lastUpdated: now,
    );
    
    // Update Gold prices
    final gold24kPriceChange = ((_random.nextDouble() - 0.48) * 5);
    final gold24k = current.gold24k.copyWith(
      pricePerGram: current.gold24k.pricePerGram + gold24kPriceChange,
      change: current.gold24k.change + gold24kPriceChange,
      changePercent: ((current.gold24k.change + gold24kPriceChange) / _baseGold24k) * 100,
      lastUpdated: now,
    );
    
    final gold21kPriceChange = ((_random.nextDouble() - 0.48) * 4);
    final gold21k = current.gold21k.copyWith(
      pricePerGram: current.gold21k.pricePerGram + gold21kPriceChange,
      change: current.gold21k.change + gold21kPriceChange,
      changePercent: ((current.gold21k.change + gold21kPriceChange) / _baseGold21k) * 100,
      lastUpdated: now,
    );
    
    // Update Gold 18K
    final gold18kPriceChange = ((_random.nextDouble() - 0.48) * 3.5);
    final gold18k = current.gold18k?.copyWith(
      pricePerGram: (current.gold18k?.pricePerGram ?? _baseGold18k) + gold18kPriceChange,
      change: (current.gold18k?.change ?? 0) + gold18kPriceChange,
      changePercent: (((current.gold18k?.change ?? 0) + gold18kPriceChange) / _baseGold18k) * 100,
      lastUpdated: now,
    );
    
    // Update Gold Pound
    final goldPoundPriceChange = gold21kPriceChange * 8;
    final goldPound = current.goldPound?.copyWith(
      price: (current.goldPound?.price ?? _baseGoldPound) + goldPoundPriceChange,
      change: (current.goldPound?.change ?? 0) + goldPoundPriceChange,
      changePercent: (((current.goldPound?.change ?? 0) + goldPoundPriceChange) / _baseGoldPound) * 100,
      lastUpdated: now,
    );
    
    // Update Stocks
    final stocks = current.stocks.map((stock) {
      final priceChange = ((_random.nextDouble() - 0.48) * 0.005 * stock.price);
      final newPrice = stock.price + priceChange;
      final newHistory = [...stock.priceHistory.skip(1), newPrice];
      final totalChange = newPrice - newHistory.first;
      
      return stock.copyWith(
        price: newPrice,
        change: totalChange,
        changePercent: (totalChange / newHistory.first) * 100,
        priceHistory: newHistory,
        lastUpdated: now,
      );
    }).toList();
    
    return MarketData(
      egx30: egx30,
      gold24k: gold24k,
      gold21k: gold21k,
      gold18k: gold18k,
      goldPound: goldPound,
      stocks: stocks,
      lastUpdated: now,
    );
  }

  /// Start streaming market data
  void startStreaming() {
    _currentData = _generateInitialData();
    _marketDataController.add(_currentData!);
    
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentData != null) {
        _currentData = _updateData(_currentData!);
        _marketDataController.add(_currentData!);
      }
    });
  }

  /// Stop streaming market data
  void stopStreaming() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Dispose the service
  void dispose() {
    stopStreaming();
    _marketDataController.close();
  }
}

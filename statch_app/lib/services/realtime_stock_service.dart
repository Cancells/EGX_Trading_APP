import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'yahoo_finance_service.dart';

/// Real-time stock price data
class RealTimePrice {
  final String symbol;
  final double price;
  final double previousPrice;
  final double change;
  final double changePercent;
  final DateTime timestamp;
  final PriceDirection direction;

  RealTimePrice({
    required this.symbol,
    required this.price,
    required this.previousPrice,
    required this.change,
    required this.changePercent,
    required this.timestamp,
    required this.direction,
  });

  bool get isPositive => change >= 0;
}

/// Direction of price movement
enum PriceDirection {
  up,
  down,
  unchanged,
}

/// Real-time stock provider with 15-second refresh
class RealTimeStockService extends ChangeNotifier with WidgetsBindingObserver {
  static final RealTimeStockService _instance = RealTimeStockService._internal();
  factory RealTimeStockService() => _instance;
  RealTimeStockService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final YahooFinanceService _yahooService = YahooFinanceService();
  
  /// Update interval in seconds
  static const int _updateIntervalSeconds = 15;

  /// Tracked symbols and their prices
  final Map<String, RealTimePrice> _prices = {};
  
  /// Previous prices for detecting direction
  final Map<String, double> _previousPrices = {};

  /// Symbols to track
  final Set<String> _trackedSymbols = {};

  /// Stream controller for price updates
  final _priceController = StreamController<Map<String, RealTimePrice>>.broadcast();
  
  /// Timer for periodic updates
  Timer? _updateTimer;
  
  /// Whether the service is active
  bool _isActive = true;
  
  /// Whether currently fetching
  bool _isFetching = false;

  /// Stream of price updates
  Stream<Map<String, RealTimePrice>> get priceStream => _priceController.stream;

  /// Get current prices
  Map<String, RealTimePrice> get prices => Map.unmodifiable(_prices);

  /// Get price for a specific symbol
  RealTimePrice? getPrice(String symbol) => _prices[symbol];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pause();
        break;
    }
  }

  /// Start tracking symbols
  void startTracking(List<String> symbols) {
    _trackedSymbols.addAll(symbols);
    if (_trackedSymbols.isNotEmpty && _isActive) {
      _startTimer();
      // Fetch immediately
      _fetchPrices();
    }
  }

  /// Stop tracking a symbol
  void stopTracking(String symbol) {
    _trackedSymbols.remove(symbol);
    _prices.remove(symbol);
    _previousPrices.remove(symbol);
    
    if (_trackedSymbols.isEmpty) {
      _stopTimer();
    }
  }

  /// Stop tracking all symbols
  void stopTrackingAll() {
    _trackedSymbols.clear();
    _prices.clear();
    _previousPrices.clear();
    _stopTimer();
  }

  /// Resume updates
  void _resume() {
    _isActive = true;
    if (_trackedSymbols.isNotEmpty) {
      _startTimer();
      _fetchPrices(); // Fetch immediately on resume
    }
  }

  /// Pause updates
  void _pause() {
    _isActive = false;
    _stopTimer();
  }

  /// Start the update timer
  void _startTimer() {
    _stopTimer(); // Cancel any existing timer
    _updateTimer = Timer.periodic(
      const Duration(seconds: _updateIntervalSeconds),
      (_) => _fetchPrices(),
    );
  }

  /// Stop the update timer
  void _stopTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Fetch prices for all tracked symbols
  Future<void> _fetchPrices() async {
    if (_isFetching || _trackedSymbols.isEmpty || !_isActive) return;

    _isFetching = true;

    try {
      final quotes = await _yahooService.fetchMultipleQuotes(
        _trackedSymbols.toList(),
      );

      for (final entry in quotes.entries) {
        final symbol = entry.key;
        final quote = entry.value;

        // Get previous price for direction detection
        final previousPrice = _previousPrices[symbol] ?? quote.previousClose;
        
        // Determine price direction
        PriceDirection direction;
        if (quote.price > previousPrice) {
          direction = PriceDirection.up;
        } else if (quote.price < previousPrice) {
          direction = PriceDirection.down;
        } else {
          direction = PriceDirection.unchanged;
        }

        // Update previous price
        _previousPrices[symbol] = quote.price;

        // Create real-time price
        final realTimePrice = RealTimePrice(
          symbol: symbol,
          price: quote.price,
          previousPrice: previousPrice,
          change: quote.change,
          changePercent: quote.changePercent,
          timestamp: DateTime.now(),
          direction: direction,
        );

        _prices[symbol] = realTimePrice;
      }

      // Notify listeners
      _priceController.add(_prices);
      notifyListeners();
    } catch (e) {
      debugPrint('RealTimeStockService fetch error: $e');
    } finally {
      _isFetching = false;
    }
  }

  /// Force refresh prices
  Future<void> refresh() async {
    await _fetchPrices();
  }

  /// Dispose the service
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _priceController.close();
    super.dispose();
  }
}

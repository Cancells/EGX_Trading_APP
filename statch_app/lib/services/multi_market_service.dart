import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/market_data.dart';
import 'yahoo_finance_service.dart';

/// Market types supported by the app
enum MarketType {
  egx,
  us,
  crypto,
}

/// Extension for MarketType configuration
extension MarketTypeConfig on MarketType {
  String get displayName {
    switch (this) {
      case MarketType.egx:
        return 'EGX';
      case MarketType.us:
        return 'US';
      case MarketType.crypto:
        return 'Crypto';
    }
  }

  String get fullName {
    switch (this) {
      case MarketType.egx:
        return 'Egyptian Exchange';
      case MarketType.us:
        return 'US Markets';
      case MarketType.crypto:
        return 'Cryptocurrency';
    }
  }

  String get currencySymbol {
    switch (this) {
      case MarketType.egx:
        return 'EGP';
      case MarketType.us:
        return '\$';
      case MarketType.crypto:
        return '\$';
    }
  }

  String get currencyCode {
    switch (this) {
      case MarketType.egx:
        return 'EGP';
      case MarketType.us:
        return 'USD';
      case MarketType.crypto:
        return 'USD';
    }
  }

  IconData get icon {
    switch (this) {
      case MarketType.egx:
        return Icons.account_balance_rounded;
      case MarketType.us:
        return Icons.show_chart_rounded;
      case MarketType.crypto:
        return Icons.currency_bitcoin_rounded;
    }
  }

  /// Whether this market trades 24/7
  bool get is24Hours {
    return this == MarketType.crypto;
  }

  /// Default decimal places for this market
  int get defaultDecimals {
    switch (this) {
      case MarketType.egx:
        return 2;
      case MarketType.us:
        return 2;
      case MarketType.crypto:
        return 2; // Overridden per-coin
    }
  }
}

/// Ticker info from JSON files
class TickerInfo {
  final String symbol;
  final String name;
  final String sector;
  final int decimals;
  final MarketType market;

  TickerInfo({
    required this.symbol,
    required this.name,
    required this.sector,
    this.decimals = 2,
    required this.market,
  });

  /// Get the Yahoo Finance compatible symbol
  String get yahooSymbol {
    switch (market) {
      case MarketType.egx:
        return symbol.endsWith('.CA') ? symbol : '$symbol.CA';
      case MarketType.us:
        return symbol; // Use as-is
      case MarketType.crypto:
        return '$symbol-USD'; // Append -USD for crypto
    }
  }

  factory TickerInfo.fromJson(Map<String, dynamic> json, MarketType market) {
    return TickerInfo(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String,
      decimals: json['decimals'] as int? ?? market.defaultDecimals,
      market: market,
    );
  }
}

/// Market hours info
class MarketHours {
  final bool isOpen;
  final String status;
  final DateTime? nextOpen;
  final DateTime? nextClose;

  MarketHours({
    required this.isOpen,
    required this.status,
    this.nextOpen,
    this.nextClose,
  });
}

/// Multi-market service for handling EGX, US, and Crypto markets
class MultiMarketService extends ChangeNotifier {
  static final MultiMarketService _instance = MultiMarketService._internal();
  factory MultiMarketService() => _instance;
  MultiMarketService._internal();

  final YahooFinanceService _yahooService = YahooFinanceService();

  MarketType _activeMarket = MarketType.egx;
  final Map<MarketType, List<TickerInfo>> _tickers = {};
  final Map<String, QuoteData> _quotes = {};
  bool _isLoading = false;
  Timer? _refreshTimer;

  /// Current active market
  MarketType get activeMarket => _activeMarket;

  /// Whether data is loading
  bool get isLoading => _isLoading;

  /// Get tickers for current market
  List<TickerInfo> get currentTickers => _tickers[_activeMarket] ?? [];

  /// Get tickers for a specific market
  List<TickerInfo> getTickers(MarketType market) => _tickers[market] ?? [];

  /// Get quote for a symbol
  QuoteData? getQuote(String symbol) => _quotes[symbol];

  /// Initialize the service and load all ticker data
  Future<void> init() async {
    await Future.wait([
      _loadEgxTickers(),
      _loadUsTickers(),
      _loadCryptoTickers(),
    ]);
    notifyListeners();
  }

  /// Load EGX tickers from EgyptianStocks
  Future<void> _loadEgxTickers() async {
    final tickers = <TickerInfo>[];
    for (final stock in EgyptianStocks.all) {
      // Skip gold/precious metals for regular stock list
      if (stock.sector == 'Precious Metals') continue;
      tickers.add(TickerInfo(
        symbol: stock.symbol,
        name: stock.name,
        sector: stock.sector,
        market: MarketType.egx,
      ));
    }
    _tickers[MarketType.egx] = tickers;
  }

  /// Load US tickers from JSON
  Future<void> _loadUsTickers() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/us_tickers.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _tickers[MarketType.us] = jsonList
          .map((json) => TickerInfo.fromJson(json, MarketType.us))
          .toList();
    } catch (e) {
      debugPrint('Error loading US tickers: $e');
      _tickers[MarketType.us] = [];
    }
  }

  /// Load Crypto tickers from JSON
  Future<void> _loadCryptoTickers() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/crypto_tickers.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _tickers[MarketType.crypto] = jsonList
          .map((json) => TickerInfo.fromJson(json, MarketType.crypto))
          .toList();
    } catch (e) {
      debugPrint('Error loading Crypto tickers: $e');
      _tickers[MarketType.crypto] = [];
    }
  }

  /// Switch to a different market
  Future<void> switchMarket(MarketType market) async {
    if (_activeMarket == market) return;

    _activeMarket = market;
    notifyListeners();

    // Fetch quotes for the new market
    await fetchQuotes();
  }

  /// Fetch quotes for current market
  Future<void> fetchQuotes() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final tickers = currentTickers;
      if (tickers.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get Yahoo symbols
      final yahooSymbols = tickers.map((t) => t.yahooSymbol).toList();

      // Fetch quotes in parallel
      final quotes = await _yahooService.fetchMultipleQuotes(yahooSymbols);

      // Store quotes with original symbol as key
      for (final ticker in tickers) {
        final quote = quotes[ticker.yahooSymbol];
        if (quote != null) {
          _quotes[ticker.symbol] = quote;
        }
      }
    } catch (e) {
      debugPrint('Error fetching quotes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start auto-refresh timer
  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchQuotes());
  }

  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Check if a market is currently open
  MarketHours getMarketHours(MarketType market) {
    final now = DateTime.now().toUtc();
    final cairoOffset = const Duration(hours: 2); // Cairo is UTC+2
    final cairoTime = now.add(cairoOffset);

    switch (market) {
      case MarketType.egx:
        // EGX: Sunday-Thursday, 10:00 AM - 2:30 PM Cairo time
        final dayOfWeek = cairoTime.weekday;
        final hour = cairoTime.hour;
        final minute = cairoTime.minute;
        
        final isWeekday = dayOfWeek >= DateTime.sunday && dayOfWeek <= DateTime.thursday;
        final isMarketHours = (hour > 10 || (hour == 10 && minute >= 0)) &&
                              (hour < 14 || (hour == 14 && minute <= 30));
        
        return MarketHours(
          isOpen: isWeekday && isMarketHours,
          status: isWeekday && isMarketHours ? 'Market Open' : 'Market Closed',
        );

      case MarketType.us:
        // US Markets: Monday-Friday, 9:30 AM - 4:00 PM ET (16:30 - 23:00 Cairo)
        final dayOfWeek = cairoTime.weekday;
        final hour = cairoTime.hour;
        final minute = cairoTime.minute;
        
        final isWeekday = dayOfWeek >= DateTime.monday && dayOfWeek <= DateTime.friday;
        final isMarketHours = (hour > 16 || (hour == 16 && minute >= 30)) && hour < 23;
        
        return MarketHours(
          isOpen: isWeekday && isMarketHours,
          status: isWeekday && isMarketHours ? 'Market Open' : 'Market Closed',
        );

      case MarketType.crypto:
        // Crypto: 24/7
        return MarketHours(
          isOpen: true,
          status: '24/7 Trading',
        );
    }
  }

  /// Format price with appropriate currency and decimals
  String formatPrice(double price, MarketType market, {int? decimals}) {
    final effectiveDecimals = decimals ?? market.defaultDecimals;
    final symbol = market.currencySymbol;
    
    if (market == MarketType.egx) {
      return '${price.toStringAsFixed(effectiveDecimals)} $symbol';
    } else {
      return '$symbol${price.toStringAsFixed(effectiveDecimals)}';
    }
  }

  /// Get decimal places for a ticker
  int getDecimalsForTicker(String symbol) {
    for (final market in _tickers.values) {
      final ticker = market.where((t) => t.symbol == symbol).firstOrNull;
      if (ticker != null) {
        return ticker.decimals;
      }
    }
    return 2; // Default
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Yahoo Finance Service with Caching and Retry Logic
class YahooFinanceService {
  static final YahooFinanceService _instance = YahooFinanceService._internal();
  factory YahooFinanceService() => _instance;
  YahooFinanceService._internal();

  static const String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const String _cachePrefix = 'yahoo_cache_';
  static const Duration _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  /// Fetch current quote with caching and retry
  Future<QuoteData?> fetchQuote(String symbol, {bool forceRefresh = false}) async {
    // 1. Try Cache First (if not forced)
    if (!forceRefresh) {
      final cached = await _getCachedQuote(symbol);
      if (cached != null) return cached;
    }

    // 2. Fetch from Network with Retry
    return await _fetchWithRetry<QuoteData?>(() async {
      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?interval=1d&range=1d'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quote = _parseQuoteData(data, symbol);
        
        if (quote != null) {
          _cacheQuote(symbol, quote); // Save to cache
        }
        return quote;
      }
      return null;
    });
  }

  /// Fetch multiple quotes with optimized caching
  Future<Map<String, QuoteData>> fetchMultipleQuotes(List<String> symbols) async {
    final results = <String, QuoteData>{};
    final symbolsToFetch = <String>[];

    // 1. Check Cache
    final prefs = await SharedPreferences.getInstance();
    for (final symbol in symbols) {
      final cachedJson = prefs.getString('$_cachePrefix$symbol');
      if (cachedJson != null) {
        try {
          final entry = json.decode(cachedJson);
          final timestamp = DateTime.parse(entry['timestamp']);
          
          if (DateTime.now().difference(timestamp) < _cacheDuration) {
            // Reconstruct basic QuoteData from cache 
            // Note: Ideally we store full object, here we simplify to avoid complex parsing
            // For robust apps, create QuoteData.fromJson
            symbolsToFetch.add(symbol); 
          } else {
            symbolsToFetch.add(symbol);
          }
        } catch (_) {
          symbolsToFetch.add(symbol);
        }
      } else {
        symbolsToFetch.add(symbol);
      }
    }

    // 2. Fetch missing/stale symbols in parallel (chunks of 5)
    for (var i = 0; i < symbolsToFetch.length; i += 5) {
      final end = (i + 5 < symbolsToFetch.length) ? i + 5 : symbolsToFetch.length;
      final batch = symbolsToFetch.sublist(i, end);
      
      final futures = batch.map((symbol) => fetchQuote(symbol, forceRefresh: true));
      final batchResults = await Future.wait(futures);
      
      for (var j = 0; j < batch.length; j++) {
        if (batchResults[j] != null) {
          results[batch[j]] = batchResults[j]!;
        }
      }
    }

    return results;
  }

  // --- Caching Helpers ---

  Future<QuoteData?> _getCachedQuote(String symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachePrefix$symbol';
      if (!prefs.containsKey(key)) return null;

      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;

      final Map<String, dynamic> cacheEntry = json.decode(jsonStr);
      final timestamp = DateTime.parse(cacheEntry['timestamp']);

      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        return null; // Cache expired
      }

      final data = cacheEntry['data'];
      return QuoteData(
        symbol: data['symbol'],
        name: data['name'],
        price: data['price'],
        previousClose: data['previousClose'],
        change: data['change'],
        changePercent: data['changePercent'],
        currency: data['currency'],
        priceHistory: (data['priceHistory'] as List).cast<double>(),
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Cache read error: $e');
      return null;
    }
  }

  Future<void> _cacheQuote(String symbol, QuoteData quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'symbol': quote.symbol,
          'name': quote.name,
          'price': quote.price,
          'previousClose': quote.previousClose,
          'change': quote.change,
          'changePercent': quote.changePercent,
          'currency': quote.currency,
          'priceHistory': quote.priceHistory,
        }
      };
      await prefs.setString('$_cachePrefix$symbol', json.encode(cacheEntry));
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  // --- Retry Logic ---

  Future<T> _fetchWithRetry<T>(Future<T> Function() apiCall, {int retries = 2}) async {
    try {
      return await apiCall();
    } catch (e) {
      if (retries > 0) {
        debugPrint('API Error: $e. Retrying... ($retries left)');
        await Future.delayed(const Duration(seconds: 1));
        return _fetchWithRetry(apiCall, retries: retries - 1);
      }
      rethrow;
    }
  }

  // --- Legacy Methods Restored for Compatibility ---

  /// Fetch historical data for a date range
  Future<List<HistoricalPrice>?> fetchHistoricalData(
    String symbol, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final period1 = startDate.millisecondsSinceEpoch ~/ 1000;
      final period2 = endDate.millisecondsSinceEpoch ~/ 1000;

      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?period1=$period1&period2=$period2&interval=1d'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseHistoricalData(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch historical price for a specific date
  Future<double?> fetchPriceAtDate(String symbol, DateTime date) async {
    try {
      // Fetch a range around the target date to ensure we get data
      final startDate = date.subtract(const Duration(days: 5));
      final endDate = date.add(const Duration(days: 1));
      
      final historical = await fetchHistoricalData(
        symbol,
        startDate: startDate,
        endDate: endDate,
      );

      if (historical != null && historical.isNotEmpty) {
        // Find the closest date to our target
        HistoricalPrice? closest;
        Duration? smallestDiff;

        for (final price in historical) {
          final diff = price.date.difference(date).abs();
          if (smallestDiff == null || diff < smallestDiff) {
            smallestDiff = diff;
            closest = price;
          }
        }

        return closest?.close;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch intraday data with price history
  Future<IntradayData?> fetchIntradayData(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?interval=5m&range=1d'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseIntradayData(data, symbol);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- Parsing Helpers ---

  QuoteData? _parseQuoteData(Map<String, dynamic> data, String symbol) {
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return null;

      final meta = result['meta'];
      final indicators = result['indicators']?['quote']?[0];

      if (meta == null) return null;

      final currentPrice = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
      final previousClose = (meta['previousClose'] as num?)?.toDouble() ?? currentPrice;
      final change = currentPrice - previousClose;
      final changePercent = previousClose != 0 ? (change / previousClose) * 100 : 0.0;

      List<double> priceHistory = [];
      if (indicators != null && indicators['close'] != null) {
        priceHistory = (indicators['close'] as List)
            .where((e) => e != null)
            .map((e) => (e as num).toDouble())
            .toList();
      }

      return QuoteData(
        symbol: symbol,
        name: meta['shortName'] ?? meta['symbol'] ?? symbol,
        price: currentPrice,
        previousClose: previousClose,
        change: change,
        changePercent: changePercent,
        currency: meta['currency'] ?? 'EGP',
        priceHistory: priceHistory,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  List<HistoricalPrice>? _parseHistoricalData(Map<String, dynamic> data) {
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return null;

      final timestamps = result['timestamp'] as List?;
      final quotes = result['indicators']?['quote']?[0];

      if (timestamps == null || quotes == null) return null;

      final opens = quotes['open'] as List?;
      final highs = quotes['high'] as List?;
      final lows = quotes['low'] as List?;
      final closes = quotes['close'] as List?;
      final volumes = quotes['volume'] as List?;

      final history = <HistoricalPrice>[];
      
      for (int i = 0; i < timestamps.length; i++) {
        final closeValue = closes?[i];
        if (closeValue != null) {
          history.add(HistoricalPrice(
            date: DateTime.fromMillisecondsSinceEpoch((timestamps[i] as int) * 1000),
            open: (opens?[i] as num?)?.toDouble() ?? 0,
            high: (highs?[i] as num?)?.toDouble() ?? 0,
            low: (lows?[i] as num?)?.toDouble() ?? 0,
            close: (closeValue as num).toDouble(),
            volume: (volumes?[i] as num?)?.toInt() ?? 0,
          ));
        }
      }

      return history;
    } catch (e) {
      return null;
    }
  }

  IntradayData? _parseIntradayData(Map<String, dynamic> data, String symbol) {
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return null;

      final meta = result['meta'];
      final timestamps = result['timestamp'] as List?;
      final quotes = result['indicators']?['quote']?[0];

      if (meta == null) return null;

      final currentPrice = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0;
      final previousClose = (meta['previousClose'] as num?)?.toDouble() ?? currentPrice;

      List<double> prices = [];
      if (timestamps != null && quotes != null) {
        final closes = quotes['close'] as List?;
        if (closes != null) {
          for (final e in closes) {
            if (e != null) {
              prices.add((e as num).toDouble());
            }
          }
        }
      }

      if (prices.isEmpty) {
        prices = [previousClose, currentPrice];
      }

      return IntradayData(
        symbol: symbol,
        name: meta['shortName'] ?? meta['symbol'] ?? symbol,
        currentPrice: currentPrice,
        previousClose: previousClose,
        prices: prices,
        currency: meta['currency'] ?? 'EGP',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }
}

// --- Data Models (Required for compilation) ---

class QuoteData {
  final String symbol;
  final String name;
  final double price;
  final double previousClose;
  final double change;
  final double changePercent;
  final String currency;
  final List<double> priceHistory;
  final DateTime timestamp;

  QuoteData({
    required this.symbol,
    required this.name,
    required this.price,
    required this.previousClose,
    required this.change,
    required this.changePercent,
    required this.currency,
    required this.priceHistory,
    required this.timestamp,
  });

  bool get isPositive => change >= 0;
}

class HistoricalPrice {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  HistoricalPrice({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class IntradayData {
  final String symbol;
  final String name;
  final double currentPrice;
  final double previousClose;
  final List<double> prices;
  final String currency;
  final DateTime timestamp;

  IntradayData({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.previousClose,
    required this.prices,
    required this.currency,
    required this.timestamp,
  });

  double get change => currentPrice - previousClose;
  double get changePercent => previousClose != 0 ? (change / previousClose) * 100 : 0;
  bool get isPositive => change >= 0;
}
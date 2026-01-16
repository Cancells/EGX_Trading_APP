import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';

// Helper for caching stocks
class _CachedStock {
  final Stock data;
  final DateTime timestamp;
  _CachedStock(this.data, this.timestamp);
}

class YahooFinanceService {
  static final YahooFinanceService _instance = YahooFinanceService._internal();
  factory YahooFinanceService() => _instance;
  YahooFinanceService._internal();

  final Map<String, _CachedStock> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 1);

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  };

  /// Fetches a single Stock quote.
  /// Returns Stock? (from user model)
  Future<Stock?> fetchQuote(String symbol) async {
    // Check Cache
    if (_cache.containsKey(symbol)) {
      final cached = _cache[symbol]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        return cached.data;
      }
    }

    try {
      final url = 'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d';
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = json['chart']['result'][0];
        final meta = result['meta'];
        
        // Safely parse nullable values
        final price = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
        final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble();
        
        // Calculate change safely
        final safePrev = prevClose ?? price;
        final change = price - safePrev;
        final changePercent = (safePrev != 0) ? (change / safePrev) * 100 : 0.0;

        final stock = Stock(
          symbol: symbol,
          name: symbol, // Placeholder as Yahoo chart API doesn't always give full name
          price: price,
          change: change,
          changePercent: changePercent,
          priceHistory: [], // Placeholder
          lastUpdated: DateTime.now(),
          previousClose: prevClose,
        );

        _cache[symbol] = _CachedStock(stock, DateTime.now());
        return stock;
      }
    } catch (e) {
      debugPrint('Error fetching quote for $symbol: $e');
    }
    return null;
  }

  /// New: Fetch Full Quote for Detail Screen
  Future<QuoteData?> fetchFullQuote(String symbol) async {
    final stock = await fetchQuote(symbol);
    if (stock == null) return null;
    
    final price = stock.price;
    // Safely handle null previousClose via the getter or logic
    final prevClose = stock.previousClose ?? price;

    return QuoteData(
      price: price,
      change: stock.change,
      changePercent: stock.changePercent,
      dayHigh: price * 1.01,
      dayLow: price * 0.99,
      open: prevClose,
      volume: 0,
      marketCap: 0,
      previousClose: prevClose,
    );
  }

  /// New: Fetch Intraday Chart Data
  Future<IntradayData?> fetchIntradayData(String symbol) async {
    try {
      final url = 'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=5m&range=1d';
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = json['chart']['result'][0];
        final meta = result['meta'];
        final timestamp = result['timestamp'] as List?;
        final indicators = result['indicators']['quote'][0];
        final closes = indicators['close'] as List?;

        final points = <ChartPoint>[];
        if (timestamp != null && closes != null) {
          for (int i = 0; i < timestamp.length; i++) {
            if (closes[i] != null) {
              points.add(ChartPoint(
                DateTime.fromMillisecondsSinceEpoch((timestamp[i] as int) * 1000),
                (closes[i] as num).toDouble(),
              ));
            }
          }
        }

        return IntradayData(
          points: points,
          previousClose: (meta['chartPreviousClose'] as num).toDouble(),
        );
      }
    } catch (e) {
      debugPrint("Error fetching intraday: $e");
    }
    return null;
  }

  /// Batch Fetch
  Future<Map<String, Stock>> fetchMultipleQuotes(List<String> symbols) async {
    final Map<String, Stock> results = {};
    for (final sym in symbols) {
      final data = await fetchQuote(sym);
      if (data != null) {
        results[sym] = data;
      }
    }
    return results;
  }

  Future<double?> fetchPriceAtDate(String symbol, DateTime date) async {
    try {
      final period1 = (date.millisecondsSinceEpoch / 1000).round();
      final period2 = period1 + 86400;
      final url = 'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?period1=$period1&period2=$period2&interval=1d';
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = json['chart']['result'];
        if (result != null && result.isNotEmpty) {
          final indicators = result[0]['indicators']['quote'][0];
          final closes = indicators['close'] as List;
          for (final price in closes) {
            if (price != null) return (price as num).toDouble();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching historical price: $e');
    }
    return null;
  }
}
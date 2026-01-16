import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';

// Helper for caching
class _CachedData {
  final MarketData data;
  final DateTime timestamp;
  _CachedData(this.data, this.timestamp);
}

class YahooFinanceService {
  static final YahooFinanceService _instance = YahooFinanceService._internal();
  factory YahooFinanceService() => _instance;
  YahooFinanceService._internal();

  final Map<String, _CachedData> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 1);

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  };

  /// Main Fetch Method (Cached)
  Future<MarketData?> fetchQuote(String symbol) async {
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
        
        final price = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
        final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble();
        final change = price - (prevClose ?? price);
        final changePercent = (prevClose != null && prevClose != 0) ? (change / prevClose) * 100 : 0.0;

        // Use the constructor that matches the updated MarketData class
        final marketData = MarketData(
          egx30: MarketIndex(name: '', symbol: '', value: 0, change: 0, changePercent: 0, priceHistory: [], lastUpdated: DateTime.now()),
          gold24k: GoldPrice(karat: '', pricePerGram: 0, change: 0, changePercent: 0, lastUpdated: DateTime.now()),
          gold21k: GoldPrice(karat: '', pricePerGram: 0, change: 0, changePercent: 0, lastUpdated: DateTime.now()),
          stocks: [],
          lastUpdated: DateTime.now(),
          // Compatibility Fields
          symbol: symbol,
          price: price,
          change: change,
          changePercent: changePercent,
          volume: 0,
          previousClose: prevClose,
        );

        _cache[symbol] = _CachedData(marketData, DateTime.now());
        return marketData;
      }
    } catch (e) {
      debugPrint('Error fetching quote for $symbol: $e');
    }
    return null;
  }

  /// New: Fetch Full Quote for Detail Screen
  Future<QuoteData?> fetchFullQuote(String symbol) async {
    final md = await fetchQuote(symbol);
    if (md == null) return null;
    
    // Fix: Handle nulls safely
    final price = md.price ?? 0.0;
    final prevClose = md.previousClose ?? price;

    return QuoteData(
      price: price,
      change: md.change ?? 0.0,
      changePercent: md.changePercent ?? 0.0,
      dayHigh: price * 1.01,
      dayLow: price * 0.99,
      open: prevClose,
      volume: md.volume ?? 0.0,
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

  Future<Map<String, MarketData>> fetchMultipleQuotes(List<String> symbols) async {
    final Map<String, MarketData> results = {};
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
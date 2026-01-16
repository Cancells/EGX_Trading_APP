import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';

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

  // Gold Conversions
  static const double _ounceToGram = 31.1035;
  static const double _karat24 = 1.0;
  static const double _karat21 = 0.875;
  static const double _karat18 = 0.750;

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  };

  /// Fetches a single Stock quote.
  Future<Stock?> fetchQuote(String symbol) async {
    // 1. Handle Special Gold Tickers
    if (symbol.startsWith('GOLD_')) {
        return _fetchDerivedGoldQuote(symbol);
    }

    // 2. Normal Stock Fetch
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
        final safePrev = prevClose ?? price;
        final change = price - safePrev;
        final changePercent = (safePrev != 0) ? (change / safePrev) * 100 : 0.0;

        final stock = Stock(
          symbol: symbol,
          name: symbol,
          price: price,
          change: change,
          changePercent: changePercent,
          priceHistory: [],
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

  /// Internal helper to fake a "Stock" object for Gold based on GC=F
  Future<Stock?> _fetchDerivedGoldQuote(String goldSymbol) async {
    // We need Gold Futures AND USD/EGP rate
    final goldFut = await fetchQuote('GC=F');
    final usdeGp = await fetchQuote('EGP=X');

    if (goldFut == null || usdeGp == null) return null;

    double purity = 1.0;
    if (goldSymbol == 'GOLD_21K') purity = _karat21;
    if (goldSymbol == 'GOLD_18K') purity = _karat18;

    // Calculate Price in EGP
    final price = (goldFut.price / _ounceToGram) * usdeGp.price * purity;
    final prevPrice = (goldFut.previousClose! / _ounceToGram) * usdeGp.previousClose! * purity;
    
    final change = price - prevPrice;
    final changePct = (change / prevPrice) * 100;

    return Stock(
      symbol: goldSymbol,
      name: goldSymbol.replaceAll('_', ' '),
      price: price,
      change: change,
      changePercent: changePct,
      priceHistory: [],
      lastUpdated: DateTime.now(),
      previousClose: prevPrice,
      currencySymbol: 'EGP',
    );
  }

  Future<double?> fetchPriceAtDate(String symbol, DateTime date) async {
    // 1. Redirect Gold History requests to GC=F
    if (symbol.startsWith('GOLD_')) {
      final rawGoldPrice = await fetchPriceAtDate('GC=F', date);
      if (rawGoldPrice == null) return null;

      // We technically need historical USD/EGP too, but for simplicity
      // we might use current USD rate or try to fetch historical USD.
      // Better accuracy: fetch historical USD too.
      final historicalUsd = await fetchPriceAtDate('EGP=X', date) ?? 50.0; // Fallback

      double purity = 1.0;
      if (symbol == 'GOLD_21K') purity = _karat21;
      if (symbol == 'GOLD_18K') purity = _karat18;

      return (rawGoldPrice / _ounceToGram) * historicalUsd * purity;
    }

    // 2. Normal History Fetch
    try {
      final period1 = (date.millisecondsSinceEpoch / 1000).round();
      final period2 = period1 + 86400; // +1 day
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

  // ... (Keep fetchFullQuote, fetchIntradayData, fetchMultipleQuotes same as before) ...
  Future<QuoteData?> fetchFullQuote(String symbol) async {
    final stock = await fetchQuote(symbol);
    if (stock == null) return null;
    final price = stock.price;
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

  Future<IntradayData?> fetchIntradayData(String symbol) async {
    // If Gold, redirect chart to GC=F (showing USD trend is better than nothing)
    final actualSymbol = symbol.startsWith('GOLD_') ? 'GC=F' : symbol;
    
    try {
      final url = 'https://query1.finance.yahoo.com/v8/finance/chart/$actualSymbol?interval=5m&range=1d';
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
}
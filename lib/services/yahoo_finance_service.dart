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
  static const double _karat21 = 0.875;
  static const double _karat18 = 0.750;

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  };

  /// Fetch a single quote (checks cache or uses batch for one)
  Future<Stock?> fetchQuote(String symbol) async {
    if (symbol.startsWith('GOLD_')) return _fetchDerivedGoldQuote(symbol);
    
    // Check cache
    if (_cache.containsKey(symbol)) {
       final cached = _cache[symbol]!;
       if (DateTime.now().difference(cached.timestamp) < _cacheDuration) return cached.data;
    }
    
    final map = await fetchMultipleQuotes([symbol]);
    return map[symbol];
  }

  /// Batch fetch multiple stocks efficiently
  Future<Map<String, Stock>> fetchMultipleQuotes(List<String> symbols) async {
    final Map<String, Stock> results = {};
    if (symbols.isEmpty) return results;

    // Separate normal stocks from our custom GOLD symbols
    final stockSymbols = symbols.where((s) => !s.startsWith('GOLD_')).toList();
    final goldSymbols = symbols.where((s) => s.startsWith('GOLD_')).toList();

    // 1. Fetch Stocks in Batches (V7 API)
    if (stockSymbols.isNotEmpty) {
      // Fetch in chunks of 10 to be safe
      for (var i = 0; i < stockSymbols.length; i += 10) {
        final end = (i + 10 < stockSymbols.length) ? i + 10 : stockSymbols.length;
        final chunk = stockSymbols.sublist(i, end);
        final joined = chunk.join(',');
        
        try {
          final url = 'https://query1.finance.yahoo.com/v7/finance/quote?symbols=$joined';
          final response = await http.get(Uri.parse(url), headers: _headers);
          
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            final quoteResponse = json['quoteResponse']['result'] as List;
            
            for (var item in quoteResponse) {
              final symbol = item['symbol'];
              final price = (item['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
              final prevClose = (item['regularMarketPreviousClose'] as num?)?.toDouble() ?? price;
              final change = price - prevClose;
              final changePercent = (item['regularMarketChangePercent'] as num?)?.toDouble() ?? 0.0;

              final stock = Stock(
                symbol: symbol,
                name: item['shortName'] ?? symbol,
                price: price,
                change: change,
                changePercent: changePercent,
                priceHistory: [],
                lastUpdated: DateTime.now(),
                previousClose: prevClose,
              );
              
              results[symbol] = stock;
              _cache[symbol] = _CachedStock(stock, DateTime.now());
            }
          }
        } catch (e) {
          debugPrint("Batch Fetch Error for chunk $joined: $e");
        }
      }
    }

    // 2. Fetch Derived Gold Prices (Requires fetching GC=F and EGP=X)
    if (goldSymbols.isNotEmpty) {
      for (final goldSym in goldSymbols) {
        final stock = await _fetchDerivedGoldQuote(goldSym);
        if (stock != null) results[goldSym] = stock;
      }
    }

    return results;
  }

  Future<Stock?> _fetchDerivedGoldQuote(String goldSymbol) async {
    // We reuse the batch fetch for components
    final map = await fetchMultipleQuotes(['GC=F', 'EGP=X']);
    final goldFut = map['GC=F'];
    final usdeGp = map['EGP=X'];

    if (goldFut == null || usdeGp == null) return null;

    double purity = 1.0;
    if (goldSymbol == 'GOLD_21K') purity = _karat21;
    if (goldSymbol == 'GOLD_18K') purity = _karat18;

    final price = (goldFut.price / _ounceToGram) * usdeGp.price * purity;
    final prevPrice = (goldFut.previousClose! / _ounceToGram) * usdeGp.previousClose! * purity;
    
    final change = price - prevPrice;
    final changePct = (prevPrice != 0) ? (change / prevPrice) * 100 : 0.0;

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

  /// REQUIRED METHOD: Fetches historical price for a specific date
  Future<double?> fetchPriceAtDate(String symbol, DateTime date) async {
    // Handle Gold
    if (symbol.startsWith('GOLD_')) {
      final rawGoldPrice = await fetchPriceAtDate('GC=F', date);
      // For simplicity in history, we use current USD rate or fallback, 
      // ideally we'd fetch historical EGP=X too.
      final historicalUsd = await fetchPriceAtDate('EGP=X', date) ?? 50.0;

      if (rawGoldPrice == null) return null;

      double purity = 1.0;
      if (symbol == 'GOLD_21K') purity = _karat21;
      if (symbol == 'GOLD_18K') purity = _karat18;

      return (rawGoldPrice / _ounceToGram) * historicalUsd * purity;
    }

    try {
      final period1 = (date.millisecondsSinceEpoch / 1000).round();
      final period2 = period1 + 86400; // +1 day window
      final url = 'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?period1=$period1&period2=$period2&interval=1d';
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = json['chart']['result'];
        if (result != null && result.isNotEmpty) {
          final indicators = result[0]['indicators']['quote'][0];
          final closes = indicators['close'] as List;
          // Return the first valid close price found in that window
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

  Future<IntradayData?> fetchIntradayData(String symbol) async {
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
  
  Future<QuoteData?> fetchFullQuote(String symbol) async {
    final stock = await fetchQuote(symbol);
    if (stock == null) return null;
    return QuoteData(
      price: stock.price,
      change: stock.change,
      changePercent: stock.changePercent,
      dayHigh: stock.price * 1.01, // Mocked as full data often needs separate API
      dayLow: stock.price * 0.99,
      open: stock.previousClose ?? stock.price,
      volume: 0,
      marketCap: 0,
      previousClose: stock.previousClose ?? stock.price,
    );
  }
}
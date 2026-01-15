import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market_data.dart';
import '../services/yahoo_finance_service.dart';
import '../services/market_data_service.dart'; // Keep for fallback if needed

class MarketRepository {
  final YahooFinanceService _apiService = YahooFinanceService();
  final _controller = StreamController<MarketData>.broadcast();
  static const String _storageKey = 'market_data_dashboard_cache';

  Stream<MarketData> get marketStream => _controller.stream;

  /// Initialize: Load cache immediately, then fetch fresh data
  Future<void> init() async {
    // 1. Emit Cached Data immediately
    final cached = await _loadFromCache();
    if (cached != null) {
      _controller.add(cached);
    }

    // 2. Fetch Fresh Data
    await refresh();
  }

  Future<void> refresh() async {
    try {
      // This logic replaces the Mock generation with Real Data fetching
      // We construct the MarketData object from multiple API calls
      
      // A. Fetch EGX 30
      final egx30Quote = await _apiService.fetchQuote('^EGX30');
      
      // B. Fetch Gold (Using global proxies or specific tickers)
      final goldQuote = await _apiService.fetchQuote('GC=F'); // Gold Futures
      
      // C. Fetch key stocks (Sample list)
      final stockSymbols = ['COMI.CA', 'TMGH.CA', 'FWRY.CA', 'HRHO.CA', 'SWDY.CA'];
      final stockQuotes = await _apiService.fetchMultipleQuotes(stockSymbols);

      // D. Construct MarketData object
      final now = DateTime.now();
      
      final newData = MarketData(
        egx30: MarketIndex(
          name: 'EGX 30',
          symbol: '^EGX30',
          value: egx30Quote?.price ?? 0,
          change: egx30Quote?.change ?? 0,
          changePercent: egx30Quote?.changePercent ?? 0,
          priceHistory: egx30Quote?.priceHistory ?? [],
          lastUpdated: now,
        ),
        // Mapping real gold prices requires a formula (Spot Price * Currency * Weight)
        // For simplicity here, we map the raw future or fallback to existing logic
        gold24k: GoldPrice(
          karat: '24K',
          pricePerGram: (goldQuote?.price ?? 2600) * 31.1 * 50, // Dummy conversion logic
          change: goldQuote?.change ?? 0,
          changePercent: goldQuote?.changePercent ?? 0,
          lastUpdated: now,
        ),
        gold21k: GoldPrice(
          karat: '21K', 
          pricePerGram: 0, // Implement calculation
          change: 0, 
          changePercent: 0, 
          lastUpdated: now
        ), 
        stocks: stockQuotes.values.map((q) => Stock(
          symbol: q.symbol,
          name: q.name,
          price: q.price,
          change: q.change,
          changePercent: q.changePercent,
          priceHistory: q.priceHistory,
          lastUpdated: now,
        )).toList(),
        lastUpdated: now,
      );

      // 3. Save to Cache
      await _saveToCache(newData);
      
      // 4. Emit Fresh Data
      _controller.add(newData);
      
    } catch (e) {
      debugPrint('MarketRepository Refresh Error: $e');
      // On error, we rely on the cache already emitted
    }
  }

  Future<void> _saveToCache(MarketData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(data.toJson()));
  }

  Future<MarketData?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        return MarketData.fromJson(json.decode(jsonStr));
      }
    } catch (e) {
      debugPrint('Error loading market cache: $e');
    }
    return null;
  }

  void dispose() {
    _controller.close();
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market_data.dart';
import '../services/yahoo_finance_service.dart';

class MarketRepository {
  final YahooFinanceService _apiService = YahooFinanceService();
  final _controller = StreamController<MarketData>.broadcast();
  static const String _storageKey = 'market_data_dashboard_v2_cache';

  // Expose the stream for the UI to listen to
  Stream<MarketData> get marketStream => _controller.stream;

  /// Initialize: Load cache immediately, then fetch fresh data
  Future<void> init() async {
    // 1. Emit Cached Data immediately (Instant Load)
    final cached = await _loadFromCache();
    if (cached != null) {
      debugPrint('MarketRepository: Loaded data from cache');
      _controller.add(cached);
    }

    // 2. Fetch Fresh Data (Background Refresh)
    await refresh();
  }

  Future<void> refresh() async {
    try {
      debugPrint('MarketRepository: Fetching fresh data...');
      
      // A. Fetch EGX 30 Index
      final egx30Quote = await _apiService.fetchQuote('^EGX30');
      
      // B. Fetch Gold Spot Price (GC=F is Gold Futures)
      final goldQuote = await _apiService.fetchQuote('GC=F'); 
      
      // C. Fetch key stocks for the dashboard list
      final stockSymbols = ['COMI.CA', 'TMGH.CA', 'FWRY.CA', 'HRHO.CA', 'SWDY.CA', 'ETEL.CA'];
      final stockQuotes = await _apiService.fetchMultipleQuotes(stockSymbols);

      // D. Construct the full MarketData object
      final now = DateTime.now();
      
      // Calculate Gold Price in EGP (Approximate formula: Spot * USD/EGP rate * conversion)
      // For V2, we use the direct values or a safe fallback
      final goldBasePrice = goldQuote?.price ?? 2600.0;
      
      final newData = MarketData(
        egx30: MarketIndex(
          name: 'EGX 30',
          symbol: '^EGX30',
          value: egx30Quote?.price ?? 17000.0,
          change: egx30Quote?.change ?? 0.0,
          changePercent: egx30Quote?.changePercent ?? 0.0,
          priceHistory: egx30Quote?.priceHistory ?? [],
          lastUpdated: now,
        ),
        gold24k: GoldPrice(
          karat: '24K',
          pricePerGram: _calculateGoldPrice(goldBasePrice, 24),
          change: goldQuote?.change ?? 0,
          changePercent: goldQuote?.changePercent ?? 0,
          lastUpdated: now,
          description: 'Pure Gold (99.9%)',
        ),
        gold21k: GoldPrice(
          karat: '21K', 
          pricePerGram: _calculateGoldPrice(goldBasePrice, 21),
          change: goldQuote?.change ?? 0, 
          changePercent: goldQuote?.changePercent ?? 0, 
          lastUpdated: now,
          description: 'Standard Gold',
        ),
        gold18k: GoldPrice(
          karat: '18K',
          pricePerGram: _calculateGoldPrice(goldBasePrice, 18),
          change: goldQuote?.change ?? 0,
          changePercent: goldQuote?.changePercent ?? 0,
          lastUpdated: now,
          description: 'Jewelry Gold',
        ),
        goldPound: GoldPoundPriceData(
          price: _calculateGoldPrice(goldBasePrice, 21) * 8, // 8 grams of 21K
          change: (goldQuote?.change ?? 0) * 8,
          changePercent: goldQuote?.changePercent ?? 0,
          lastUpdated: now,
        ),
        stocks: stockQuotes.values.map((q) => Stock(
          symbol: q.symbol,
          name: q.name,
          price: q.price,
          change: q.change,
          changePercent: q.changePercent,
          priceHistory: q.priceHistory,
          lastUpdated: now,
          currencySymbol: 'EGP',
        )).toList(),
        lastUpdated: now,
      );

      // 3. Save to Cache
      await _saveToCache(newData);
      
      // 4. Emit Fresh Data
      _controller.add(newData);
      debugPrint('MarketRepository: Fresh data emitted');
      
    } catch (e) {
      debugPrint('MarketRepository Refresh Error: $e');
      // If offline, we just silently fail and keep showing cached data
    }
  }

  // Simplified conversion helper (replace with real formula in production)
  double _calculateGoldPrice(double spotPriceUsd, int karat) {
    // 1 oz = 31.1035 grams
    // Rough estimation: Spot / 31.1 * 50 (USD rate) * (Karat/24)
    // Adjust 50.0 to your real USD/EGP rate service later
    const usdRate = 50.5; 
    final price24k = (spotPriceUsd / 31.1035) * usdRate;
    return price24k * (karat / 24);
  }

  Future<void> _saveToCache(MarketData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(data.toJson()));
    } catch (e) {
      debugPrint('Error saving cache: $e');
    }
  }

  Future<MarketData?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        return MarketData.fromJson(json.decode(jsonStr));
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    }
    return null;
  }

  void dispose() {
    _controller.close();
  }
}
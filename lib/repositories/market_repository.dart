import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/market_data.dart';
import '../services/simulated_market_service.dart';
import '../services/fast_gold_service.dart'; // Ensure this is imported

class MarketRepository {
  final SimulatedMarketService _simService = SimulatedMarketService();
  final FastGoldService _goldService = FastGoldService();
  
  final _controller = StreamController<MarketData>.broadcast();
  Stream<MarketData> get marketStream => _controller.stream;

  // Cache for calculating daily change manually
  double? _lastGoldPrice;

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    try {
      // 1. Fetch Simulated Stocks (EGX)
      final simData = await _simService.getMarketData();
      
      // 2. Fetch REAL Live Gold & Silver Prices
      final realGold = await _goldService.fetchLivePrices();
      
      // Calculate Gold Change manually (API gives snapshot)
      final current24k = realGold['24k']!.pricePerGram;
      double goldChange = 0.0;
      double goldChangePct = 0.0;
      
      if (_lastGoldPrice != null) {
        goldChange = current24k - _lastGoldPrice!;
        if (_lastGoldPrice != 0) {
          goldChangePct = (goldChange / _lastGoldPrice!) * 100;
        }
      }
      _lastGoldPrice = current24k;

      // 3. Merge Real Gold/Silver into Market Data
      final mergedData = MarketData(
        egx30: simData.egx30,
        gold24k: realGold['24k']!.copyWith(change: goldChange, changePercent: goldChangePct),
        gold21k: realGold['21k']!.copyWith(change: goldChange * (21/24), changePercent: goldChangePct),
        gold18k: realGold['18k']!.copyWith(change: goldChange * (18/24), changePercent: goldChangePct),
        
        // PASS SILVER DATA HERE
        silver: realGold['silver'], 
        
        goldPound: GoldPoundPriceData(
          price: realGold['21k']!.pricePerGram * 8, 
          change: (goldChange * (21/24)) * 8,
          changePercent: goldChangePct,
          lastUpdated: DateTime.now(),
        ),
        
        stocks: simData.stocks,
        lastUpdated: DateTime.now(),
      );

      _controller.add(mergedData);
      
    } catch (e) {
      debugPrint('Repository Refresh Error: $e');
    }
  }

  void dispose() {
    _controller.close();
  }
}
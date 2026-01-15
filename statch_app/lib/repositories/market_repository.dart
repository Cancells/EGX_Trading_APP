import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/market_data.dart';
import '../services/simulated_market_service.dart'; // Import the new service

class MarketRepository {
  // Switch to simulation service for reliable data presentation
  final SimulatedMarketService _dataService = SimulatedMarketService();
  final _controller = StreamController<MarketData>.broadcast();
  
  Stream<MarketData> get marketStream => _controller.stream;

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    try {
      // Fetch realistic simulated data
      final data = await _dataService.getMarketData();
      _controller.add(data);
    } catch (e) {
      debugPrint('Error fetching market data: $e');
    }
  }

  void dispose() {
    _controller.close();
  }
}
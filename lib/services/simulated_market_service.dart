import 'dart:math';
import '../models/market_data.dart';

/// Generates realistic-looking market data for demo purposes
/// Solves the issue of Yahoo Finance returning empty/broken EGX data
class SimulatedMarketService {
  final Random _rnd = Random();

  /// Generate a full market snapshot
  Future<MarketData> getMarketData() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network

    final now = DateTime.now();
    
    // 1. Generate realistic EGX 30 movement
    final egx30History = _generateIntradayCurve(17500, volatility: 0.015);
    final egx30Current = egx30History.last;
    final egx30Open = egx30History.first;
    
    // 2. Generate Gold Prices (Simulate live connection)
    // Base price ~ 3650 EGP/gram for 24K
    final gold24kPrice = 3650.0 + _rnd.nextDouble() * 20 - 10; 
    
    return MarketData(
      egx30: MarketIndex(
        name: 'EGX 30',
        symbol: '^EGX30',
        value: egx30Current,
        change: egx30Current - egx30Open,
        changePercent: ((egx30Current - egx30Open) / egx30Open) * 100,
        priceHistory: egx30History,
        lastUpdated: now,
      ),
      gold24k: GoldPrice(
        karat: '24K',
        pricePerGram: gold24kPrice,
        change: 15.5,
        changePercent: 0.45,
        lastUpdated: now,
        description: 'Pure Gold',
      ),
      gold21k: GoldPrice(
        karat: '21K',
        pricePerGram: gold24kPrice * (21/24),
        change: 12.0,
        changePercent: 0.45,
        lastUpdated: now,
        description: 'Standard',
      ),
      gold18k: GoldPrice(
        karat: '18K',
        pricePerGram: gold24kPrice * (18/24),
        change: 9.5,
        changePercent: 0.45,
        lastUpdated: now,
        description: 'Jewelry',
      ),
      stocks: _generateStockList(),
      lastUpdated: now,
    );
  }

  List<Stock> _generateStockList() {
    final stocks = [
      {'s': 'COMI.CA', 'n': 'CIB Egypt', 'p': 82.50, 'v': 0.02},
      {'s': 'FWRY.CA', 'n': 'Fawry', 'p': 6.20, 'v': 0.03},
      {'s': 'TMGH.CA', 'n': 'Talaat Moustafa', 'p': 55.40, 'v': 0.025},
      {'s': 'ETEL.CA', 'n': 'Telecom Egypt', 'p': 38.90, 'v': 0.015},
      {'s': 'EKHO.CA', 'n': 'Egypt Kuwait', 'p': 41.20, 'v': 0.01},
      {'s': 'HRHO.CA', 'n': 'EFG Hermes', 'p': 19.80, 'v': 0.02},
      {'s': 'SWDY.CA', 'n': 'Elsewedy Elec', 'p': 34.50, 'v': 0.02},
    ];

    return stocks.map((s) {
      final basePrice = s['p'] as double;
      final volatility = s['v'] as double;
      final history = _generateIntradayCurve(basePrice, volatility: volatility);
      final current = history.last;
      final open = history.first;

      return Stock(
        symbol: s['s'] as String,
        name: s['n'] as String,
        price: current,
        change: current - open,
        changePercent: ((current - open) / open) * 100,
        priceHistory: history,
        lastUpdated: DateTime.now(),
        currencySymbol: 'EGP',
      );
    }).toList();
  }

  /// Math magic to make lines look like real stock charts
  List<double> _generateIntradayCurve(double basePrice, {double volatility = 0.01}) {
    List<double> points = [];
    double current = basePrice;
    
    // Create 50 data points
    for (int i = 0; i < 50; i++) {
      // Random walk
      double change = (current * volatility) * (_rnd.nextDouble() - 0.5);
      // Add trend (slightly bullish)
      change += (current * 0.0005); 
      current += change;
      points.add(current);
    }
    return points;
  }
}
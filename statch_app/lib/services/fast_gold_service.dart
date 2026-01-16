import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';
import 'currency_service.dart'; // Import CurrencyService

class FastGoldService {
  // Public endpoint for live gold spot price
  static const String _endpoint = 'https://data-asg.goldprice.org/dbXRates/USD';
  
  Future<Map<String, GoldPrice>> fetchLivePrices() async {
    try {
      final response = await http.get(
        Uri.parse(_endpoint),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body);
        final items = jsonMap['items'] as List<dynamic>;
        if (items.isNotEmpty) {
          final data = items[0];
          final xauUsd = (data['xauPrice'] as num).toDouble(); // Gold Spot
          final xagUsd = (data['xagPrice'] as num).toDouble(); // Silver Spot
          
          return _calculateEgyptianPrices(xauUsd, xagUsd);
        }
      }
    } catch (e) {
      debugPrint('FastGoldService Error: $e');
    }
    
    // Fallback if API fails
    return _calculateEgyptianPrices(2650.0, 31.0); 
  }

  Map<String, GoldPrice> _calculateEgyptianPrices(double xauSpotUsd, double xagSpotUsd) {
    final now = DateTime.now();
    
    // 1. Get Real-Time USD Rate from our CurrencyService
    final egpRate = CurrencyService().usdToEgp; 
    
    // 2. Math: (Spot / 31.1035) * USD_Rate
    const ozToGram = 31.1035;
    
    final price24k = (xauSpotUsd / ozToGram) * egpRate;
    final price21k = price24k * (21 / 24);
    final price18k = price24k * (18 / 24);
    final priceSilver = (xagSpotUsd / ozToGram) * egpRate;

    return {
      '24k': GoldPrice(
        karat: '24K',
        pricePerGram: price24k,
        change: 0,
        changePercent: 0,
        lastUpdated: now,
        description: 'Pure Gold (99.9%)',
      ),
      '21k': GoldPrice(
        karat: '21K',
        pricePerGram: price21k,
        change: 0,
        changePercent: 0,
        lastUpdated: now,
        description: 'Standard (Jewelry)',
      ),
      '18k': GoldPrice(
        karat: '18K',
        pricePerGram: price18k,
        change: 0,
        changePercent: 0,
        lastUpdated: now,
        description: 'Economy Gold',
      ),
      'silver': GoldPrice(
        karat: 'Silver',
        pricePerGram: priceSilver,
        change: 0,
        changePercent: 0,
        lastUpdated: now,
        description: 'Pure Silver (99.9%)',
      ),
    };
  }
}
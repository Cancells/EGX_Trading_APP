import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

// --- Core Market Data Models ---

class MarketIndex {
  final String name;
  final String symbol;
  final double value;
  final double change;
  final double changePercent;
  final List<double> priceHistory;
  final DateTime lastUpdated;

  MarketIndex({
    required this.name,
    required this.symbol,
    required this.value,
    required this.change,
    required this.changePercent,
    required this.priceHistory,
    required this.lastUpdated,
  });

  bool get isPositive => change >= 0;

  Map<String, dynamic> toJson() => {
    'name': name,
    'symbol': symbol,
    'value': value,
    'change': change,
    'changePercent': changePercent,
    'priceHistory': priceHistory,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    return MarketIndex(
      name: json['name'],
      symbol: json['symbol'],
      value: (json['value'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      priceHistory: (json['priceHistory'] as List).map((e) => (e as num).toDouble()).toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  MarketIndex copyWith({
    String? name,
    String? symbol,
    double? value,
    double? change,
    double? changePercent,
    List<double>? priceHistory,
    DateTime? lastUpdated,
  }) {
    return MarketIndex(
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      value: value ?? this.value,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      priceHistory: priceHistory ?? this.priceHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class GoldPrice {
  final String karat;
  final double pricePerGram;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;
  final String? description;

  GoldPrice({
    required this.karat,
    required this.pricePerGram,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
    this.description,
  });

  bool get isPositive => change >= 0;

  GoldPrice copyWith({
    String? karat,
    double? pricePerGram,
    double? change,
    double? changePercent,
    DateTime? lastUpdated,
    String? description,
  }) {
    return GoldPrice(
      karat: karat ?? this.karat,
      pricePerGram: pricePerGram ?? this.pricePerGram,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
    'karat': karat,
    'pricePerGram': pricePerGram,
    'change': change,
    'changePercent': changePercent,
    'lastUpdated': lastUpdated.toIso8601String(),
    'description': description,
  };

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      karat: json['karat'],
      pricePerGram: (json['pricePerGram'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      description: json['description'],
    );
  }
}

class GoldPoundPriceData {
  final double price;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;

  GoldPoundPriceData({
    required this.price,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });

  bool get isPositive => change >= 0;

  GoldPoundPriceData copyWith({
    double? price,
    double? change,
    double? changePercent,
    DateTime? lastUpdated,
  }) {
    return GoldPoundPriceData(
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'price': price,
    'change': change,
    'changePercent': changePercent,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory GoldPoundPriceData.fromJson(Map<String, dynamic> json) {
    return GoldPoundPriceData(
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

class Stock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final List<double> priceHistory;
  final DateTime lastUpdated;
  final String? sector;
  final String? website;
  final DateTime? listedDate;
  final String currencySymbol;
  final int decimals;
  final String? marketType; 
  final double? previousClose;

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.priceHistory,
    required this.lastUpdated,
    this.sector,
    this.website,
    this.listedDate,
    this.currencySymbol = 'EGP',
    this.decimals = 2,
    this.marketType,
    this.previousClose,
  });

  bool get isPositive => change >= 0;
  
  bool get isNew {
    if (listedDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(listedDate!);
    return difference.inDays <= 30;
  }

  String get formattedPrice {
    final priceStr = price.toStringAsFixed(decimals);
    if (currencySymbol == 'EGP') {
      return '$priceStr EGP';
    } else {
      return '$currencySymbol$priceStr';
    }
  }

  Stock copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change,
    double? changePercent,
    List<double>? priceHistory,
    DateTime? lastUpdated,
    String? sector,
    String? website,
    DateTime? listedDate,
    String? currencySymbol,
    int? decimals,
    String? marketType,
    double? previousClose,
  }) {
    return Stock(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      priceHistory: priceHistory ?? this.priceHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sector: sector ?? this.sector,
      website: website ?? this.website,
      listedDate: listedDate ?? this.listedDate,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      decimals: decimals ?? this.decimals,
      marketType: marketType ?? this.marketType,
      previousClose: previousClose ?? this.previousClose,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'price': price,
    'change': change,
    'changePercent': changePercent,
    'priceHistory': priceHistory,
    'lastUpdated': lastUpdated.toIso8601String(),
    'sector': sector,
    'website': website,
    'listedDate': listedDate?.toIso8601String(),
    'currencySymbol': currencySymbol,
    'decimals': decimals,
    'marketType': marketType,
    'previousClose': previousClose,
  };

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      priceHistory: (json['priceHistory'] as List).map((e) => (e as num).toDouble()).toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      sector: json['sector'],
      website: json['website'],
      listedDate: json['listedDate'] != null ? DateTime.parse(json['listedDate']) : null,
      currencySymbol: json['currencySymbol'] ?? 'EGP',
      decimals: json['decimals'] ?? 2,
      marketType: json['marketType'],
      previousClose: (json['previousClose'] as num?)?.toDouble(),
    );
  }
}

class MarketData {
  final MarketIndex egx30;
  final GoldPrice gold24k;
  final GoldPrice gold21k;
  final GoldPrice? gold18k;
  final GoldPoundPriceData? goldPound;
  final GoldPrice? silver; 
  final List<Stock> stocks;
  final DateTime lastUpdated;

  MarketData({
    required this.egx30,
    required this.gold24k,
    required this.gold21k,
    this.gold18k,
    this.goldPound,
    this.silver,
    required this.stocks,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'egx30': egx30.toJson(),
    'gold24k': gold24k.toJson(),
    'gold21k': gold21k.toJson(),
    'gold18k': gold18k?.toJson(),
    'goldPound': goldPound?.toJson(),
    'silver': silver?.toJson(), 
    'stocks': stocks.map((s) => s.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      egx30: MarketIndex.fromJson(json['egx30']),
      gold24k: GoldPrice.fromJson(json['gold24k']),
      gold21k: GoldPrice.fromJson(json['gold21k']),
      gold18k: json['gold18k'] != null ? GoldPrice.fromJson(json['gold18k']) : null,
      goldPound: json['goldPound'] != null ? GoldPoundPriceData.fromJson(json['goldPound']) : null,
      silver: json['silver'] != null ? GoldPrice.fromJson(json['silver']) : null,
      stocks: (json['stocks'] as List).map((e) => Stock.fromJson(e)).toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

// --- Helper Classes (Updated for Dynamic Loading) ---

class EgyptianStock {
  final String symbol;
  final String name;
  final String sector;
  final String? website;
  final DateTime? listedDate;

  const EgyptianStock({
    required this.symbol,
    required this.name,
    required this.sector,
    this.website,
    this.listedDate,
  });

  bool get isNew {
    if (listedDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(listedDate!);
    return difference.inDays <= 30;
  }
  
  // Factory to create from JSON
  factory EgyptianStock.fromJson(Map<String, dynamic> json) {
    return EgyptianStock(
      symbol: json['symbol'],
      name: json['name'],
      sector: json['sector'],
    );
  }
}

class EgyptianStocks {
  // 1. Static list to hold loaded data
  static List<EgyptianStock> _stocks = [];
  static bool _isLoaded = false;

  // 2. Hardcoded Precious Metals (Not in JSON)
  static List<EgyptianStock> get preciousMetals => [
    const EgyptianStock(symbol: 'GOLD_24K', name: 'Gold 24K (Gram)', sector: 'Precious Metals'),
    const EgyptianStock(symbol: 'GOLD_21K', name: 'Gold 21K (Gram)', sector: 'Precious Metals'),
    const EgyptianStock(symbol: 'GOLD_18K', name: 'Gold 18K (Gram)', sector: 'Precious Metals'),
    const EgyptianStock(symbol: 'GOLD_POUND', name: 'Egyptian Gold Pound (8g)', sector: 'Precious Metals'),
  ];

  // 3. Initialization Method - CALL THIS IN MAIN.DART
  static Future<void> init() async {
    if (_isLoaded) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/egx_tickers.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _stocks = jsonList.map((json) => EgyptianStock.fromJson(json)).toList();
      _isLoaded = true;
      debugPrint('✅ Loaded ${_stocks.length} EGX tickers from assets');
    } catch (e) {
      debugPrint('❌ Error loading EGX tickers: $e');
    }
  }

  // 4. Get All Stocks (Metals + Loaded Stocks)
  static List<EgyptianStock> get all => [
    ...preciousMetals,
    ..._stocks,
  ];

  // 5. Helpers
  static List<EgyptianStock> bySector(String sector) {
    return all.where((stock) => stock.sector == sector).toList();
  }

  static EgyptianStock? bySymbol(String symbol) {
    try {
      return all.firstWhere((stock) => stock.symbol == symbol);
    } catch (_) {
      return null;
    }
  }
}

// --- Detail Screen Helper Models ---

class QuoteData {
  final double price;
  final double change;
  final double changePercent;
  final double dayHigh;
  final double dayLow;
  final double open;
  final double volume;
  final double marketCap;
  final double? peRatio;
  final double? dividendYield;
  final double previousClose;

  QuoteData({
    required this.price,
    required this.change,
    required this.changePercent,
    required this.dayHigh,
    required this.dayLow,
    required this.open,
    required this.volume,
    required this.marketCap,
    this.peRatio,
    this.dividendYield,
    required this.previousClose,
  });
}

class IntradayData {
  final List<ChartPoint> points;
  final double previousClose;

  IntradayData({required this.points, required this.previousClose});
}

class ChartPoint {
  final DateTime time;
  final double price;

  ChartPoint(this.time, this.price);
}
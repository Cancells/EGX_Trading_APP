// Market Data Models for Egyptian Market

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

  GoldPrice({
    required this.karat,
    required this.pricePerGram,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });

  bool get isPositive => change >= 0;

  GoldPrice copyWith({
    String? karat,
    double? pricePerGram,
    double? change,
    double? changePercent,
    DateTime? lastUpdated,
  }) {
    return GoldPrice(
      karat: karat ?? this.karat,
      pricePerGram: pricePerGram ?? this.pricePerGram,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
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

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.priceHistory,
    required this.lastUpdated,
  });

  bool get isPositive => change >= 0;

  Stock copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change,
    double? changePercent,
    List<double>? priceHistory,
    DateTime? lastUpdated,
  }) {
    return Stock(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      priceHistory: priceHistory ?? this.priceHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class MarketData {
  final MarketIndex egx30;
  final GoldPrice gold24k;
  final GoldPrice gold21k;
  final List<Stock> stocks;
  final DateTime lastUpdated;

  MarketData({
    required this.egx30,
    required this.gold24k,
    required this.gold21k,
    required this.stocks,
    required this.lastUpdated,
  });
}

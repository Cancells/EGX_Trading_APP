import 'dart:convert';

/// Investment model for tracking user investments
class Investment {
  final String id;
  final String symbol;
  final String name;
  final double quantity;
  final DateTime purchaseDate;
  final double purchasePrice;
  double currentPrice;
  final DateTime createdAt;

  Investment({
    required this.id,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.purchaseDate,
    required this.purchasePrice,
    this.currentPrice = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate total invested amount
  double get totalInvested => purchasePrice * quantity;

  /// Calculate current value
  double get currentValue => currentPrice * quantity;

  /// Calculate profit/loss amount
  double get profitLoss => (currentPrice - purchasePrice) * quantity;

  /// Calculate profit/loss percentage
  double get profitLossPercent {
    if (purchasePrice == 0) return 0;
    return ((currentPrice - purchasePrice) / purchasePrice) * 100;
  }

  /// Check if investment is profitable
  bool get isProfit => profitLoss >= 0;

  /// Copy with updated current price
  Investment copyWith({
    String? id,
    String? symbol,
    String? name,
    double? quantity,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? currentPrice,
    DateTime? createdAt,
  }) {
    return Investment(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'currentPrice': currentPrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON map
  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Serialize list of investments to JSON string
  static String encodeList(List<Investment> investments) {
    return json.encode(investments.map((e) => e.toJson()).toList());
  }

  /// Deserialize list of investments from JSON string
  static List<Investment> decodeList(String jsonString) {
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) => Investment.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// Portfolio summary statistics
class PortfolioSummary {
  final double totalInvested;
  final double currentValue;
  final double totalProfitLoss;
  final double totalProfitLossPercent;
  final int totalInvestments;
  final int profitableInvestments;

  PortfolioSummary({
    required this.totalInvested,
    required this.currentValue,
    required this.totalProfitLoss,
    required this.totalProfitLossPercent,
    required this.totalInvestments,
    required this.profitableInvestments,
  });

  bool get isProfit => totalProfitLoss >= 0;

  factory PortfolioSummary.fromInvestments(List<Investment> investments) {
    if (investments.isEmpty) {
      return PortfolioSummary(
        totalInvested: 0,
        currentValue: 0,
        totalProfitLoss: 0,
        totalProfitLossPercent: 0,
        totalInvestments: 0,
        profitableInvestments: 0,
      );
    }

    double totalInvested = 0;
    double currentValue = 0;
    int profitable = 0;

    for (final investment in investments) {
      totalInvested += investment.totalInvested;
      currentValue += investment.currentValue;
      if (investment.isProfit) profitable++;
    }

    final profitLoss = currentValue - totalInvested;
    final profitLossPercent = totalInvested != 0 
        ? (profitLoss / totalInvested) * 100 
        : 0.0;

    return PortfolioSummary(
      totalInvested: totalInvested,
      currentValue: currentValue,
      totalProfitLoss: profitLoss,
      totalProfitLossPercent: profitLossPercent,
      totalInvestments: investments.length,
      profitableInvestments: profitable,
    );
  }
}

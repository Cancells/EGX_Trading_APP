import 'dart:convert';

class Investment {
  final String id;
  final String symbol;
  final String name;
  final double quantity;
  final DateTime purchaseDate;
  final double purchasePrice;
  final double currentPrice;

  Investment({
    required this.id,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.currentPrice,
  });

  // --- Derived Getters (Fix for missing properties) ---
  
  double get currentValue => quantity * currentPrice;
  double get investedValue => quantity * purchasePrice;
  
  double get totalGain => currentValue - investedValue;
  
  double get totalGainPercent {
    if (investedValue == 0) return 0.0;
    return (totalGain / investedValue) * 100;
  }

  // --- Serialization ---

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'currentPrice': currentPrice,
    };
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      symbol: map['symbol'],
      name: map['name'],
      quantity: (map['quantity'] as num).toDouble(),
      purchaseDate: DateTime.parse(map['purchaseDate']),
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      currentPrice: (map['currentPrice'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Investment.fromJson(String source) => 
      Investment.fromMap(json.decode(source));

  static String encodeList(List<Investment> investments) => 
      json.encode(investments.map((x) => x.toMap()).toList());

  static List<Investment> decodeList(String source) => 
      (json.decode(source) as List).map((x) => Investment.fromMap(x)).toList();

  Investment copyWith({
    String? id,
    String? symbol,
    String? name,
    double? quantity,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? currentPrice,
  }) {
    return Investment(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
}

class PortfolioSummary {
  final double totalValue;
  final double totalGain;
  final double totalGainPercent;
  final double dayGain;
  final double dayGainPercent;

  PortfolioSummary({
    required this.totalValue,
    required this.totalGain,
    required this.totalGainPercent,
    required this.dayGain,
    required this.dayGainPercent,
  });

  factory PortfolioSummary.fromInvestments(List<Investment> investments) {
    double totalValue = 0;
    double totalInvested = 0;
    
    // Simplified calculation
    for (var inv in investments) {
      totalValue += inv.currentValue;
      totalInvested += inv.investedValue;
    }

    double totalGain = totalValue - totalInvested;
    double totalGainPercent = totalInvested == 0 ? 0 : (totalGain / totalInvested) * 100;

    return PortfolioSummary(
      totalValue: totalValue,
      totalGain: totalGain,
      totalGainPercent: totalGainPercent,
      dayGain: 0, // Placeholder as we don't track day history in this simplified model
      dayGainPercent: 0,
    );
  }
}
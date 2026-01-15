import 'dart:convert';

// Market Data Models

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

  // Added copyWith for easier state updates
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

  // Crucial: copyWith for Repository updates
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
    );
  }
}

class MarketData {
  final MarketIndex egx30;
  final GoldPrice gold24k;
  final GoldPrice gold21k;
  final GoldPrice? gold18k;
  final GoldPoundPriceData? goldPound;
  final GoldPrice? silver; // <--- Added Silver
  final List<Stock> stocks;
  final DateTime lastUpdated;

  MarketData({
    required this.egx30,
    required this.gold24k,
    required this.gold21k,
    this.gold18k,
    this.goldPound,
    this.silver, // <--- Added to constructor
    required this.stocks,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'egx30': egx30.toJson(),
    'gold24k': gold24k.toJson(),
    'gold21k': gold21k.toJson(),
    'gold18k': gold18k?.toJson(),
    'goldPound': goldPound?.toJson(),
    'silver': silver?.toJson(), // <--- Added to JSON
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
      silver: json['silver'] != null ? GoldPrice.fromJson(json['silver']) : null, // <--- Added from JSON
      stocks: (json['stocks'] as List).map((e) => Stock.fromJson(e)).toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

// Keep EgyptianStock / EgyptianStocks classes as is
// ... (The rest of the file remains the same as your existing code)
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
}

class EgyptianStocks {
  static List<EgyptianStock> get preciousMetals => [
    const EgyptianStock(symbol: 'GOLD_24K', name: 'Gold 24K (Gram)', sector: 'Precious Metals'),
    const EgyptianStock(symbol: 'GOLD_21K', name: 'Gold 21K (Gram)', sector: 'Precious Metals'),
    const EgyptianStock(symbol: 'GOLD_18K', name: 'Gold 18K (Gram)', sector: 'Precious Metals'),
    const EgyptianStock(symbol: 'GOLD_POUND', name: 'Egyptian Gold Pound (8g)', sector: 'Precious Metals'),
  ];

  static List<EgyptianStock> get banks => [
    EgyptianStock(symbol: 'COMI.CA', name: 'Commercial International Bank (CIB)', sector: 'Banks', website: 'cibeg.com'),
    EgyptianStock(symbol: 'CIEB.CA', name: 'Credit Agricole Egypt', sector: 'Banks', website: 'credit-agricole.com.eg'),
    EgyptianStock(symbol: 'ADIB.CA', name: 'Abu Dhabi Islamic Bank', sector: 'Banks', website: 'adib.eg'),
    EgyptianStock(symbol: 'HDBK.CA', name: 'Housing & Development Bank', sector: 'Banks', website: 'hdb-egy.com'),
  ];

  static List<EgyptianStock> get realEstate => [
    EgyptianStock(symbol: 'TMGH.CA', name: 'Talaat Moustafa Group', sector: 'Real Estate', website: 'talaatmoustafa.com'),
    EgyptianStock(symbol: 'PHDC.CA', name: 'Palm Hills Developments', sector: 'Real Estate', website: 'palmhillsdevelopments.com'),
    EgyptianStock(symbol: 'HELI.CA', name: 'Heliopolis Housing', sector: 'Real Estate', website: 'heliopoliscompany.com'),
    EgyptianStock(symbol: 'ORHD.CA', name: 'Orascom Development', sector: 'Real Estate', website: 'orascomdh.com'),
    EgyptianStock(symbol: 'EMFD.CA', name: 'Emaar Misr', sector: 'Real Estate', website: 'emaarmisr.com'),
    EgyptianStock(symbol: 'PORT.CA', name: 'Porto Group', sector: 'Real Estate', website: 'portogroup.com.eg', listedDate: DateTime(2025, 12, 20)),
    EgyptianStock(symbol: 'ACAMD.CA', name: 'Arab Co. for Asset Management', sector: 'Real Estate'),
    EgyptianStock(symbol: 'MENA.CA', name: 'Mena Touristic & Real Estate', sector: 'Real Estate'),
  ];

  static List<EgyptianStock> get telecom => [
    EgyptianStock(symbol: 'ETEL.CA', name: 'Telecom Egypt', sector: 'Telecom', website: 'te.eg'),
  ];

  static List<EgyptianStock> get fintech => [
    EgyptianStock(symbol: 'FWRY.CA', name: 'Fawry Banking & Payment', sector: 'Fintech', website: 'fawry.com'),
  ];

  static List<EgyptianStock> get financialServices => [
    EgyptianStock(symbol: 'HRHO.CA', name: 'EFG Hermes', sector: 'Financial Services', website: 'efghermes.com'),
    EgyptianStock(symbol: 'BTFH.CA', name: 'Beltone Financial', sector: 'Financial Services', website: 'beltoneholding.com'),
    EgyptianStock(symbol: 'CNFN.CA', name: 'Contact Financial', sector: 'Financial Services', website: 'contactcars.com', listedDate: DateTime(2025, 12, 25)),
  ];

  static List<EgyptianStock> get investments => [
    EgyptianStock(symbol: 'EKHO.CA', name: 'Egypt Kuwait Holding', sector: 'Investments', website: 'ekholding.com'),
    EgyptianStock(symbol: 'CCAP.CA', name: 'Qalaa Holdings', sector: 'Investments', website: 'qalaaholdings.com'),
    EgyptianStock(symbol: 'BINV.CA', name: 'B Investments', sector: 'Investments'),
    EgyptianStock(symbol: 'AIH.CA', name: 'Arabia Investments Holding', sector: 'Investments'),
    EgyptianStock(symbol: 'AMIA.CA', name: 'Arab Moltaqa Investments', sector: 'Investments'),
  ];

  static List<EgyptianStock> get basicResources => [
    EgyptianStock(symbol: 'ABUK.CA', name: 'Abou Kir Fertilizers', sector: 'Basic Resources', website: 'aboukir.com'),
    EgyptianStock(symbol: 'MFPC.CA', name: 'Mopco Fertilizers', sector: 'Basic Resources', website: 'mopco-eg.com'),
    EgyptianStock(symbol: 'ESRS.CA', name: 'Ezz Steel', sector: 'Basic Resources', website: 'ezzsteel.com'),
    EgyptianStock(symbol: 'EGAL.CA', name: 'Egypt Aluminum', sector: 'Basic Resources', website: 'egyptalum.com.eg'),
    EgyptianStock(symbol: 'KIMA.CA', name: 'Egyptian Chemical Industries', sector: 'Basic Resources'),
    EgyptianStock(symbol: 'ATQA.CA', name: 'Misr National Steel', sector: 'Basic Resources'),
  ];

  static List<EgyptianStock> get industrial => [
    EgyptianStock(symbol: 'SWDY.CA', name: 'El Sewedy Electric', sector: 'Industrial', website: 'elsewedy.com'),
  ];

  static List<EgyptianStock> get healthcare => [
    EgyptianStock(symbol: 'ISPH.CA', name: 'Ibnsina Pharma', sector: 'Healthcare', website: 'ibnsinapharma.com'),
    EgyptianStock(symbol: 'CLHO.CA', name: 'Cleopatra Hospitals', sector: 'Healthcare', website: 'cleopatrahospitals.com'),
    EgyptianStock(symbol: 'RMDA.CA', name: 'Rameda Pharmaceuticals', sector: 'Healthcare', website: 'rameda-pharma.com'),
    EgyptianStock(symbol: 'SPMD.CA', name: 'Speed Medical', sector: 'Healthcare', website: 'speedmedical.net'),
    EgyptianStock(symbol: 'MPCI.CA', name: 'Memphis Pharmaceuticals', sector: 'Healthcare', listedDate: DateTime(2026, 1, 5)),
  ];

  static List<EgyptianStock> get all => [
    ...preciousMetals,
    ...banks,
    ...realEstate,
    ...telecom,
    ...fintech,
    ...financialServices,
    ...investments,
    ...basicResources,
    ...industrial,
    ...healthcare,
  ];

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
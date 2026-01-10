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
}

/// Gold Pound (Geneh) price model - 8 grams of 21K gold
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
  final String? marketType; // 'egx', 'us', 'crypto'

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
  
  /// Check if the stock was listed within the last 30 days
  bool get isNew {
    if (listedDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(listedDate!);
    return difference.inDays <= 30;
  }

  /// Format price with appropriate currency symbol and decimals
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
    );
  }
}

class MarketData {
  final MarketIndex egx30;
  final GoldPrice gold24k;
  final GoldPrice gold21k;
  final GoldPrice? gold18k;
  final GoldPoundPriceData? goldPound;
  final List<Stock> stocks;
  final DateTime lastUpdated;

  MarketData({
    required this.egx30,
    required this.gold24k,
    required this.gold21k,
    this.gold18k,
    this.goldPound,
    required this.stocks,
    required this.lastUpdated,
  });
}

/// Egyptian Stock info for reference
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

  /// Check if the stock was listed within the last 30 days
  bool get isNew {
    if (listedDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(listedDate!);
    return difference.inDays <= 30;
  }
}

/// List of all Egyptian stocks with website and listing date info
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
    EgyptianStock(symbol: 'PORT.CA', name: 'Porto Group', sector: 'Real Estate', website: 'portogroup.com.eg', listedDate: DateTime(2025, 12, 20)), // NEW
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
    EgyptianStock(symbol: 'CNFN.CA', name: 'Contact Financial', sector: 'Financial Services', website: 'contactcars.com', listedDate: DateTime(2025, 12, 25)), // NEW
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
    EgyptianStock(symbol: 'MPCI.CA', name: 'Memphis Pharmaceuticals', sector: 'Healthcare', listedDate: DateTime(2026, 1, 5)), // NEW
  ];

  static List<EgyptianStock> get technology => [
    EgyptianStock(symbol: 'EFIH.CA', name: 'e-finance', sector: 'Technology', website: 'efinance.com.eg'),
    EgyptianStock(symbol: 'RAYA.CA', name: 'Raya Holding', sector: 'Technology', website: 'rayacorp.com'),
    EgyptianStock(symbol: 'RACC.CA', name: 'Raya Contact Center', sector: 'Technology', website: 'rayacc.com'),
  ];

  static List<EgyptianStock> get energy => [
    EgyptianStock(symbol: 'AMOC.CA', name: 'Alexandria Mineral Oils', sector: 'Energy', website: 'amoc-eg.com'),
    EgyptianStock(symbol: 'SKPC.CA', name: 'Sidi Kerir Petrochemicals', sector: 'Energy', website: 'sidpec.com'),
  ];

  static List<EgyptianStock> get foodAndBeverage => [
    EgyptianStock(symbol: 'JUFO.CA', name: 'Juhayna Food Industries', sector: 'Food & Beverage', website: 'juhayna.com'),
    EgyptianStock(symbol: 'DOMT.CA', name: 'Arabian Food Ind. DOMTY', sector: 'Food & Beverage', website: 'domty.com'),
    EgyptianStock(symbol: 'EFID.CA', name: 'Edita Food Industries', sector: 'Food & Beverage', website: 'edita.com.eg'),
    EgyptianStock(symbol: 'AJWA.CA', name: 'Ajwa Group', sector: 'Food & Beverage'),
    EgyptianStock(symbol: 'OLFI.CA', name: 'Obour Land', sector: 'Food & Beverage', website: 'obourland.com'),
    EgyptianStock(symbol: 'SCFM.CA', name: 'South Cairo & Giza Mills', sector: 'Food & Beverage'),
    EgyptianStock(symbol: 'ZEOT.CA', name: 'Extracted Oils', sector: 'Food & Beverage'),
    EgyptianStock(symbol: 'POUL.CA', name: 'Cairo Poultry', sector: 'Food & Beverage'),
    EgyptianStock(symbol: 'ADPC.CA', name: 'Arab Dairy - Panda', sector: 'Food & Beverage'),
    EgyptianStock(symbol: 'EIUD.CA', name: 'Upper Egypt Flour Mills', sector: 'Food & Beverage'),
  ];

  static List<EgyptianStock> get textiles => [
    EgyptianStock(symbol: 'ORWE.CA', name: 'Oriental Weavers', sector: 'Textiles', website: 'orientalweavers.com'),
    EgyptianStock(symbol: 'DSCW.CA', name: 'Dice Sport & Casual Wear', sector: 'Textiles'),
  ];

  static List<EgyptianStock> get construction => [
    EgyptianStock(symbol: 'ORAS.CA', name: 'Orascom Construction', sector: 'Construction', website: 'orascom.com'),
    EgyptianStock(symbol: 'GGCC.CA', name: 'Giza General Contracting', sector: 'Construction'),
    EgyptianStock(symbol: 'UEGC.CA', name: 'Upper Egypt Contracting', sector: 'Construction'),
  ];

  static List<EgyptianStock> get buildingMaterials => [
    EgyptianStock(symbol: 'ARCC.CA', name: 'Arabian Cement', sector: 'Building Materials', website: 'arabcement.com'),
    EgyptianStock(symbol: 'MCQE.CA', name: 'Misr Cement Qena', sector: 'Building Materials'),
  ];

  static List<EgyptianStock> get automotive => [
    EgyptianStock(symbol: 'AUTO.CA', name: 'GB Auto', sector: 'Automotive', website: 'gbauto.com.eg'),
  ];

  static List<EgyptianStock> get tobacco => [
    EgyptianStock(symbol: 'EAST.CA', name: 'Eastern Company', sector: 'Tobacco', website: 'easternco.com.eg'),
  ];

  static List<EgyptianStock> get education => [
    EgyptianStock(symbol: 'CIRA.CA', name: 'Cairo Investment & Real Estate', sector: 'Education'),
  ];

  static List<EgyptianStock> get tourism => [
    EgyptianStock(symbol: 'EGTS.CA', name: 'Egyptian Resorts', sector: 'Tourism'),
  ];

  /// Get all stocks as a single list
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
    ...technology,
    ...energy,
    ...foodAndBeverage,
    ...textiles,
    ...construction,
    ...buildingMaterials,
    ...automotive,
    ...tobacco,
    ...education,
    ...tourism,
  ];

  /// Get stocks by sector
  static List<EgyptianStock> bySector(String sector) {
    return all.where((stock) => stock.sector == sector).toList();
  }

  /// Get all sectors
  static List<String> get sectors => [
    'Precious Metals',
    'Banks',
    'Real Estate',
    'Telecom',
    'Fintech',
    'Financial Services',
    'Investments',
    'Basic Resources',
    'Industrial',
    'Healthcare',
    'Technology',
    'Energy',
    'Food & Beverage',
    'Textiles',
    'Construction',
    'Building Materials',
    'Automotive',
    'Tobacco',
    'Education',
    'Tourism',
  ];

  /// Get stock info by symbol
  static EgyptianStock? bySymbol(String symbol) {
    try {
      return all.firstWhere((stock) => stock.symbol == symbol);
    } catch (_) {
      return null;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Yahoo Finance Service for fetching real-time market data
class YahooFinanceService {
  static final YahooFinanceService _instance = YahooFinanceService._internal();
  factory YahooFinanceService() => _instance;
  YahooFinanceService._internal();

  static const String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  
  // Egyptian Stock Exchange symbols (Cairo exchange uses .CA suffix)
  static const Map<String, String> egxSymbols = {
    // Banks
    'COMI.CA': 'Commercial International Bank (CIB)',
    'CIEB.CA': 'Credit Agricole Egypt',
    'ADIB.CA': 'Abu Dhabi Islamic Bank',
    'HDBK.CA': 'Housing & Development Bank',
    
    // Real Estate
    'TMGH.CA': 'Talaat Moustafa Group',
    'PHDC.CA': 'Palm Hills Developments',
    'HELI.CA': 'Heliopolis Housing',
    'ORHD.CA': 'Orascom Development',
    'EMFD.CA': 'Emaar Misr',
    'PORT.CA': 'Porto Group',
    'ACAMD.CA': 'Arab Co. for Asset Management',
    'MENA.CA': 'Mena Touristic & Real Estate',
    
    // Telecom
    'ETEL.CA': 'Telecom Egypt',
    
    // Fintech
    'FWRY.CA': 'Fawry Banking & Payment',
    
    // Financial Services
    'HRHO.CA': 'EFG Hermes',
    'BTFH.CA': 'Beltone Financial',
    'CNFN.CA': 'Contact Financial',
    
    // Investments
    'EKHO.CA': 'Egypt Kuwait Holding',
    'CCAP.CA': 'Qalaa Holdings',
    'BINV.CA': 'B Investments',
    'AIH.CA': 'Arabia Investments Holding',
    'AMIA.CA': 'Arab Moltaqa Investments',
    
    // Basic Resources
    'ABUK.CA': 'Abou Kir Fertilizers',
    'MFPC.CA': 'Mopco Fertilizers',
    'ESRS.CA': 'Ezz Steel',
    'EGAL.CA': 'Egypt Aluminum',
    'KIMA.CA': 'Egyptian Chemical Industries',
    'ATQA.CA': 'Misr National Steel',
    
    // Industrial
    'SWDY.CA': 'El Sewedy Electric',
    
    // Healthcare
    'ISPH.CA': 'Ibnsina Pharma',
    'CLHO.CA': 'Cleopatra Hospitals',
    'RMDA.CA': 'Rameda Pharmaceuticals',
    'SPMD.CA': 'Speed Medical',
    'MPCI.CA': 'Memphis Pharmaceuticals',
    
    // Technology
    'EFIH.CA': 'e-finance',
    'RAYA.CA': 'Raya Holding',
    'RACC.CA': 'Raya Contact Center',
    
    // Energy
    'AMOC.CA': 'Alexandria Mineral Oils',
    'SKPC.CA': 'Sidi Kerir Petrochemicals',
    
    // Food & Beverage
    'JUFO.CA': 'Juhayna Food Industries',
    'DOMT.CA': 'Arabian Food Ind. DOMTY',
    'EFID.CA': 'Edita Food Industries',
    'AJWA.CA': 'Ajwa Group',
    'OLFI.CA': 'Obour Land',
    'SCFM.CA': 'South Cairo & Giza Mills',
    'ZEOT.CA': 'Extracted Oils',
    'POUL.CA': 'Cairo Poultry',
    'ADPC.CA': 'Arab Dairy - Panda',
    'EIUD.CA': 'Upper Egypt Flour Mills',
    
    // Textiles
    'ORWE.CA': 'Oriental Weavers',
    'DSCW.CA': 'Dice Sport & Casual Wear',
    
    // Construction
    'ORAS.CA': 'Orascom Construction',
    'GGCC.CA': 'Giza General Contracting',
    'UEGC.CA': 'Upper Egypt Contracting',
    
    // Building Materials
    'ARCC.CA': 'Arabian Cement',
    'MCQE.CA': 'Misr Cement Qena',
    
    // Automotive
    'AUTO.CA': 'GB Auto',
    
    // Tobacco
    'EAST.CA': 'Eastern Company',
    
    // Education
    'CIRA.CA': 'Cairo Investment & Real Estate',
    
    // Tourism
    'EGTS.CA': 'Egyptian Resorts',
  };

  // Precious Metals symbols (virtual tickers for gold tracking)
  static const Map<String, String> preciousMetalsSymbols = {
    'GOLD_24K': 'Gold 24K (Gram)',
    'GOLD_21K': 'Gold 21K (Gram)',
    'GOLD_18K': 'Gold 18K (Gram)',
    'GOLD_POUND': 'Egyptian Gold Pound (8g)',
  };

  // EGX 30 Index
  static const String egx30Symbol = '^EGX30';
  
  // Gold symbols
  static const String goldSpotSymbol = 'GC=F'; // Gold Futures
  static const String goldUsdSymbol = 'XAUUSD=X'; // Gold/USD

  // Currency symbols
  static const String usdEgpSymbol = 'EGP=X'; // USD to EGP

  /// Check if a symbol is a gold/precious metal virtual ticker
  static bool isGoldSymbol(String symbol) {
    return preciousMetalsSymbols.containsKey(symbol);
  }

  /// Get all available symbols including gold
  static Map<String, String> get allSymbols => {
    ...preciousMetalsSymbols,
    ...egxSymbols,
  };

  /// Fetch current quote for a symbol
  Future<QuoteData?> fetchQuote(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?interval=1d&range=1d'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseQuoteData(data, symbol);
      }
      return null;
    } catch (e) {
      // Return null on error - caller should handle fallback
      return null;
    }
  }

  /// Fetch historical data for a date range
  Future<List<HistoricalPrice>?> fetchHistoricalData(
    String symbol, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final period1 = startDate.millisecondsSinceEpoch ~/ 1000;
      final period2 = endDate.millisecondsSinceEpoch ~/ 1000;

      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?period1=$period1&period2=$period2&interval=1d'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseHistoricalData(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch historical price for a specific date
  Future<double?> fetchPriceAtDate(String symbol, DateTime date) async {
    try {
      // Fetch a range around the target date to ensure we get data
      final startDate = date.subtract(const Duration(days: 5));
      final endDate = date.add(const Duration(days: 1));
      
      final historical = await fetchHistoricalData(
        symbol,
        startDate: startDate,
        endDate: endDate,
      );

      if (historical != null && historical.isNotEmpty) {
        // Find the closest date to our target
        HistoricalPrice? closest;
        Duration? smallestDiff;

        for (final price in historical) {
          final diff = price.date.difference(date).abs();
          if (smallestDiff == null || diff < smallestDiff) {
            smallestDiff = diff;
            closest = price;
          }
        }

        return closest?.close;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch intraday data with price history
  Future<IntradayData?> fetchIntradayData(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?interval=5m&range=1d'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseIntradayData(data, symbol);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch multiple quotes in batch
  Future<Map<String, QuoteData>> fetchMultipleQuotes(List<String> symbols) async {
    final results = <String, QuoteData>{};
    
    // Fetch in parallel
    final futures = symbols.map((symbol) async {
      final quote = await fetchQuote(symbol);
      if (quote != null) {
        results[symbol] = quote;
      }
    });

    await Future.wait(futures);
    return results;
  }

  QuoteData? _parseQuoteData(Map<String, dynamic> data, String symbol) {
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return null;

      final meta = result['meta'];
      final indicators = result['indicators']?['quote']?[0];

      if (meta == null) return null;

      final currentPrice = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
      final previousClose = (meta['previousClose'] as num?)?.toDouble() ?? currentPrice;
      final change = currentPrice - previousClose;
      final changePercent = previousClose != 0 ? (change / previousClose) * 100 : 0.0;

      // Get price history from indicators
      List<double> priceHistory = [];
      if (indicators != null && indicators['close'] != null) {
        priceHistory = (indicators['close'] as List)
            .where((e) => e != null)
            .map((e) => (e as num).toDouble())
            .toList();
      }

      return QuoteData(
        symbol: symbol,
        name: meta['shortName'] ?? meta['symbol'] ?? symbol,
        price: currentPrice,
        previousClose: previousClose,
        change: change,
        changePercent: changePercent,
        currency: meta['currency'] ?? 'EGP',
        priceHistory: priceHistory,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  List<HistoricalPrice>? _parseHistoricalData(Map<String, dynamic> data) {
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return null;

      final timestamps = result['timestamp'] as List?;
      final quotes = result['indicators']?['quote']?[0];

      if (timestamps == null || quotes == null) return null;

      final opens = quotes['open'] as List?;
      final highs = quotes['high'] as List?;
      final lows = quotes['low'] as List?;
      final closes = quotes['close'] as List?;
      final volumes = quotes['volume'] as List?;

      final history = <HistoricalPrice>[];
      
      for (int i = 0; i < timestamps.length; i++) {
        final closeValue = closes?[i];
        if (closeValue != null) {
          history.add(HistoricalPrice(
            date: DateTime.fromMillisecondsSinceEpoch((timestamps[i] as int) * 1000),
            open: (opens?[i] as num?)?.toDouble() ?? 0,
            high: (highs?[i] as num?)?.toDouble() ?? 0,
            low: (lows?[i] as num?)?.toDouble() ?? 0,
            close: (closeValue as num).toDouble(),
            volume: (volumes?[i] as num?)?.toInt() ?? 0,
          ));
        }
      }

      return history;
    } catch (e) {
      return null;
    }
  }

  IntradayData? _parseIntradayData(Map<String, dynamic> data, String symbol) {
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return null;

      final meta = result['meta'];
      final timestamps = result['timestamp'] as List?;
      final quotes = result['indicators']?['quote']?[0];

      if (meta == null) return null;

      final currentPrice = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0;
      final previousClose = (meta['previousClose'] as num?)?.toDouble() ?? currentPrice;

      List<double> prices = [];
      if (timestamps != null && quotes != null) {
        final closes = quotes['close'] as List?;
        if (closes != null) {
          for (final e in closes) {
            if (e != null) {
              prices.add((e as num).toDouble());
            }
          }
        }
      }

      // Ensure we have at least some data points
      if (prices.isEmpty) {
        prices = [previousClose, currentPrice];
      }

      return IntradayData(
        symbol: symbol,
        name: meta['shortName'] ?? meta['symbol'] ?? symbol,
        currentPrice: currentPrice,
        previousClose: previousClose,
        prices: prices,
        currency: meta['currency'] ?? 'EGP',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Quote data model
class QuoteData {
  final String symbol;
  final String name;
  final double price;
  final double previousClose;
  final double change;
  final double changePercent;
  final String currency;
  final List<double> priceHistory;
  final DateTime timestamp;

  QuoteData({
    required this.symbol,
    required this.name,
    required this.price,
    required this.previousClose,
    required this.change,
    required this.changePercent,
    required this.currency,
    required this.priceHistory,
    required this.timestamp,
  });

  bool get isPositive => change >= 0;
}

/// Historical price data model
class HistoricalPrice {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  HistoricalPrice({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

/// Intraday data with price series
class IntradayData {
  final String symbol;
  final String name;
  final double currentPrice;
  final double previousClose;
  final List<double> prices;
  final String currency;
  final DateTime timestamp;

  IntradayData({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.previousClose,
    required this.prices,
    required this.currency,
    required this.timestamp,
  });

  double get change => currentPrice - previousClose;
  double get changePercent => previousClose != 0 ? (change / previousClose) * 100 : 0;
  bool get isPositive => change >= 0;
}

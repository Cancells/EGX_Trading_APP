import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Sparkline data periods
enum SparklinePeriod {
  day,
  week,
  month,
  ytd,
  fiveYear,
}

/// Extension for period configuration
extension SparklinePeriodConfig on SparklinePeriod {
  String get yahooRange {
    switch (this) {
      case SparklinePeriod.day:
        return '1d';
      case SparklinePeriod.week:
        return '5d';
      case SparklinePeriod.month:
        return '1mo';
      case SparklinePeriod.ytd:
        return 'ytd';
      case SparklinePeriod.fiveYear:
        return '5y';
    }
  }

  String get yahooInterval {
    switch (this) {
      case SparklinePeriod.day:
        return '5m';
      case SparklinePeriod.week:
        return '60m';
      case SparklinePeriod.month:
        return '1d';
      case SparklinePeriod.ytd:
        return '1wk';
      case SparklinePeriod.fiveYear:
        return '1mo';
    }
  }

  String get displayName {
    switch (this) {
      case SparklinePeriod.day:
        return '1D';
      case SparklinePeriod.week:
        return '1W';
      case SparklinePeriod.month:
        return '1M';
      case SparklinePeriod.ytd:
        return 'YTD';
      case SparklinePeriod.fiveYear:
        return '5Y';
    }
  }

  /// Cache duration for this period
  Duration get cacheDuration {
    switch (this) {
      case SparklinePeriod.day:
        return const Duration(minutes: 5);
      case SparklinePeriod.week:
        return const Duration(minutes: 15);
      case SparklinePeriod.month:
        return const Duration(hours: 1);
      case SparklinePeriod.ytd:
        return const Duration(hours: 6);
      case SparklinePeriod.fiveYear:
        return const Duration(days: 1);
    }
  }
}

/// Sparkline data model
class SparklineData {
  final String symbol;
  final SparklinePeriod period;
  final List<double> prices;
  final DateTime fetchedAt;
  final double? firstPrice;
  final double? lastPrice;

  SparklineData({
    required this.symbol,
    required this.period,
    required this.prices,
    required this.fetchedAt,
    this.firstPrice,
    this.lastPrice,
  });

  bool get isPositive {
    if (firstPrice == null || lastPrice == null) {
      if (prices.length < 2) return true;
      return prices.last >= prices.first;
    }
    return lastPrice! >= firstPrice!;
  }

  double get changePercent {
    if (firstPrice == null || lastPrice == null || firstPrice == 0) {
      if (prices.length < 2 || prices.first == 0) return 0;
      return ((prices.last - prices.first) / prices.first) * 100;
    }
    return ((lastPrice! - firstPrice!) / firstPrice!) * 100;
  }

  /// Check if cached data is still valid
  bool get isValid {
    final age = DateTime.now().difference(fetchedAt);
    return age < period.cacheDuration;
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'period': period.index,
    'prices': prices,
    'fetchedAt': fetchedAt.toIso8601String(),
    'firstPrice': firstPrice,
    'lastPrice': lastPrice,
  };

  factory SparklineData.fromJson(Map<String, dynamic> json) {
    return SparklineData(
      symbol: json['symbol'] as String,
      period: SparklinePeriod.values[json['period'] as int],
      prices: (json['prices'] as List).map((e) => (e as num).toDouble()).toList(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      firstPrice: json['firstPrice'] as double?,
      lastPrice: json['lastPrice'] as double?,
    );
  }
}

/// Custom cache manager for sparkline data
class SparklineCacheManager {
  static const key = 'sparklineCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(minutes: 5),
      maxNrOfCacheObjects: 200,
    ),
  );
}

/// Sparkline Service for fetching and caching chart data
class SparklineService extends ChangeNotifier {
  static final SparklineService _instance = SparklineService._internal();
  factory SparklineService() => _instance;
  SparklineService._internal();

  static const String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';

  // In-memory cache for quick access
  final Map<String, SparklineData> _cache = {};

  /// Get cache key for a symbol and period
  String _getCacheKey(String symbol, SparklinePeriod period) {
    return '${symbol}_${period.name}';
  }

  /// Fetch sparkline data with caching
  Future<SparklineData?> fetchSparklineData(
    String symbol,
    SparklinePeriod period,
  ) async {
    final cacheKey = _getCacheKey(symbol, period);

    // Check in-memory cache first
    final cached = _cache[cacheKey];
    if (cached != null && cached.isValid) {
      return cached;
    }

    // Try to fetch from network
    try {
      final range = period.yahooRange;
      final interval = period.yahooInterval;

      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?range=$range&interval=$interval'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sparklineData = _parseSparklineData(data, symbol, period);
        
        if (sparklineData != null) {
          // Store in cache
          _cache[cacheKey] = sparklineData;
          return sparklineData;
        }
      }
    } catch (e) {
      debugPrint('Sparkline fetch error for $symbol: $e');
    }

    // Return cached data even if expired, or null
    return cached;
  }

  /// Parse Yahoo Finance response into sparkline data
  SparklineData? _parseSparklineData(
    Map<String, dynamic> data,
    String symbol,
    SparklinePeriod period,
  ) {
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return null;

      final meta = result['meta'];
      final quotes = result['indicators']?['quote']?[0];

      if (quotes == null) return null;

      final closes = quotes['close'] as List?;
      if (closes == null || closes.isEmpty) return null;

      // Filter out null values and convert to doubles
      final prices = closes
          .where((e) => e != null)
          .map((e) => (e as num).toDouble())
          .toList();

      if (prices.isEmpty) return null;

      final previousClose = (meta?['previousClose'] as num?)?.toDouble();
      final currentPrice = (meta?['regularMarketPrice'] as num?)?.toDouble();

      return SparklineData(
        symbol: symbol,
        period: period,
        prices: prices,
        fetchedAt: DateTime.now(),
        firstPrice: previousClose ?? prices.first,
        lastPrice: currentPrice ?? prices.last,
      );
    } catch (e) {
      debugPrint('Sparkline parse error: $e');
      return null;
    }
  }

  /// Fetch sparkline data for multiple symbols
  Future<Map<String, SparklineData>> fetchMultipleSparklines(
    List<String> symbols,
    SparklinePeriod period,
  ) async {
    final results = <String, SparklineData>{};

    // Fetch in parallel
    final futures = symbols.map((symbol) async {
      final data = await fetchSparklineData(symbol, period);
      if (data != null) {
        results[symbol] = data;
      }
    });

    await Future.wait(futures);
    return results;
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  /// Clear cached data for a specific symbol
  void clearCacheForSymbol(String symbol) {
    _cache.removeWhere((key, _) => key.startsWith(symbol));
  }
}

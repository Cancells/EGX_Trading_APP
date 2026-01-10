import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/investment.dart';
import 'yahoo_finance_service.dart';
import 'gold_service.dart';

/// Service for managing user investments
class InvestmentService {
  static final InvestmentService _instance = InvestmentService._internal();
  factory InvestmentService() => _instance;
  InvestmentService._internal();

  static const String _storageKey = 'user_investments';
  
  final YahooFinanceService _yahooService = YahooFinanceService();
  final GoldService _goldService = GoldService();
  SharedPreferences? _prefs;
  
  List<Investment> _investments = [];
  List<Investment> get investments => List.unmodifiable(_investments);

  final _investmentsController = StreamController<List<Investment>>.broadcast();
  Stream<List<Investment>> get investmentsStream => _investmentsController.stream;

  Timer? _updateTimer;

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadInvestments();
    _startPriceUpdates();
  }

  /// Load investments from storage
  Future<void> _loadInvestments() async {
    final jsonString = _prefs?.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        _investments = Investment.decodeList(jsonString);
        _investmentsController.add(_investments);
      } catch (e) {
        _investments = [];
      }
    }
  }

  /// Save investments to storage
  Future<void> _saveInvestments() async {
    final jsonString = Investment.encodeList(_investments);
    await _prefs?.setString(_storageKey, jsonString);
    _investmentsController.add(_investments);
  }

  /// Add a new investment
  Future<Investment?> addInvestment({
    required String symbol,
    required String name,
    required double quantity,
    required DateTime purchaseDate,
  }) async {
    // Fetch historical price for purchase date
    double? purchasePrice = await _yahooService.fetchPriceAtDate(symbol, purchaseDate);
    
    // If we can't get historical price, try current price as fallback
    if (purchasePrice == null) {
      final quote = await _yahooService.fetchQuote(symbol);
      purchasePrice = quote?.price;
    }

    if (purchasePrice == null || purchasePrice == 0) {
      return null; // Can't add without a valid price
    }

    // Fetch current price
    final currentQuote = await _yahooService.fetchQuote(symbol);
    final currentPrice = currentQuote?.price ?? purchasePrice;

    final investment = Investment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      name: name,
      quantity: quantity,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      currentPrice: currentPrice,
    );

    _investments.add(investment);
    await _saveInvestments();
    
    return investment;
  }

  /// Add investment with manual price entry
  Future<Investment?> addInvestmentWithPrice({
    required String symbol,
    required String name,
    required double quantity,
    required DateTime purchaseDate,
    required double purchasePrice,
  }) async {
    // Fetch current price
    double currentPrice = purchasePrice;
    
    if (GoldService.isGoldSymbol(symbol)) {
      currentPrice = _goldService.getPriceBySymbol(symbol) ?? purchasePrice;
    } else {
      final currentQuote = await _yahooService.fetchQuote(symbol);
      currentPrice = currentQuote?.price ?? purchasePrice;
    }

    final investment = Investment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      name: name,
      quantity: quantity,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      currentPrice: currentPrice,
    );

    _investments.add(investment);
    await _saveInvestments();
    
    return investment;
  }

  /// Add a gold investment
  Future<Investment?> addGoldInvestment({
    required String symbol,
    required String name,
    required double quantity,
    required DateTime purchaseDate,
    required double purchasePrice,
    double? currentPrice,
  }) async {
    final goldCurrentPrice = currentPrice ?? _goldService.getPriceBySymbol(symbol) ?? purchasePrice;

    final investment = Investment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      name: name,
      quantity: quantity,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      currentPrice: goldCurrentPrice,
    );

    _investments.add(investment);
    await _saveInvestments();
    
    return investment;
  }

  /// Remove an investment
  Future<void> removeInvestment(String id) async {
    _investments.removeWhere((inv) => inv.id == id);
    await _saveInvestments();
  }

  /// Update an investment
  Future<void> updateInvestment(Investment investment) async {
    final index = _investments.indexWhere((inv) => inv.id == investment.id);
    if (index != -1) {
      _investments[index] = investment;
      await _saveInvestments();
    }
  }

  /// Get portfolio summary
  PortfolioSummary get portfolioSummary {
    return PortfolioSummary.fromInvestments(_investments);
  }

  /// Start periodic price updates
  void _startPriceUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateAllPrices();
    });
    // Initial update
    _updateAllPrices();
  }

  /// Update prices for all investments
  Future<void> _updateAllPrices() async {
    if (_investments.isEmpty) return;

    bool hasChanges = false;
    
    // Separate gold symbols from regular symbols
    final goldSymbols = <String>{};
    final regularSymbols = <String>{};
    
    for (final inv in _investments) {
      if (GoldService.isGoldSymbol(inv.symbol)) {
        goldSymbols.add(inv.symbol);
      } else {
        regularSymbols.add(inv.symbol);
      }
    }
    
    // Fetch quotes for regular symbols
    final quotes = await _yahooService.fetchMultipleQuotes(regularSymbols.toList());

    // Update investments with new prices
    for (int i = 0; i < _investments.length; i++) {
      final symbol = _investments[i].symbol;
      double? newPrice;
      
      if (GoldService.isGoldSymbol(symbol)) {
        // Get gold price from gold service
        newPrice = _goldService.getPriceBySymbol(symbol);
      } else {
        // Get regular stock price from quotes
        newPrice = quotes[symbol]?.price;
      }
      
      if (newPrice != null && newPrice != _investments[i].currentPrice) {
        _investments[i] = _investments[i].copyWith(currentPrice: newPrice);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _investmentsController.add(_investments);
      // Don't save to storage on every price update (only structure changes)
    }
  }

  /// Force refresh prices
  Future<void> refreshPrices() async {
    await _updateAllPrices();
  }

  /// Stop price updates
  void stopUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Dispose the service
  void dispose() {
    stopUpdates();
    _investmentsController.close();
  }
}

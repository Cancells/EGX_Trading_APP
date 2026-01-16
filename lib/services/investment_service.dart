import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart'; 
import '../models/investment.dart';
import 'yahoo_finance_service.dart';
import 'gold_service.dart';
import '../models/market_data.dart';

class InvestmentService extends ChangeNotifier {
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

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadInvestments();
    _startPriceUpdates();
  }

  // --- Encryption ---
  enc.Key _getEncryptionKey() {
    const keySeed = 'statch_app_secure_investment_data_seed_2026';
    final bytes = utf8.encode(keySeed);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  String _encryptData(String plainText) {
    try {
      final key = _getEncryptionKey();
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(enc.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      return plainText;
    }
  }

  String _decryptData(String encryptedText) {
    if (encryptedText.isEmpty) return '';
    if (!encryptedText.contains(':')) return encryptedText;
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return encryptedText;
      final key = _getEncryptionKey();
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final encrypter = enc.Encrypter(enc.AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return encryptedText;
    }
  }

  // --- Storage ---
  Future<void> _loadInvestments() async {
    final rawString = _prefs?.getString(_storageKey);
    if (rawString != null && rawString.isNotEmpty) {
      try {
        final jsonString = _decryptData(rawString);
        _investments = Investment.decodeList(jsonString);
        _investmentsController.add(_investments);
        notifyListeners();
      } catch (e) {
        _investments = [];
        notifyListeners();
      }
    }
  }

  Future<void> _saveInvestments() async {
    final jsonString = Investment.encodeList(_investments);
    final encryptedString = _encryptData(jsonString);
    await _prefs?.setString(_storageKey, encryptedString);
    _investmentsController.add(_investments);
    notifyListeners();
  }

  // --- Actions ---
  
  /// Add investment with auto-fetched price
  Future<Investment?> addInvestment({
    required String symbol,
    required String name,
    required double quantity,
    required DateTime purchaseDate,
  }) async {
    double? purchasePrice = await _yahooService.fetchPriceAtDate(symbol, purchaseDate);
    final stock = await _yahooService.fetchQuote(symbol);
    
    if (purchasePrice == null || purchasePrice == 0) {
      purchasePrice = stock?.price;
    }

    if (purchasePrice == null || purchasePrice == 0) return null;

    final currentPrice = stock?.price ?? purchasePrice;

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

  /// Add investment with manual price (Fix for AddInvestmentScreen error)
  Future<Investment?> addInvestmentWithPrice({
    required String symbol,
    required String name,
    required double quantity,
    required DateTime purchaseDate,
    required double purchasePrice,
  }) async {
    // Attempt to get current live price
    final stock = await _yahooService.fetchQuote(symbol);
    
    // If live price fails, fallback to purchase price to avoid 0.0 value
    double currentPrice = stock?.price ?? purchasePrice;
    if (currentPrice == 0) currentPrice = purchasePrice;

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

  Future<Investment?> addGoldInvestment({
    required String symbol,
    required String name,
    required double quantity,
    required DateTime purchaseDate,
    required double purchasePrice,
    double? currentPrice,
  }) async {
    double? fetchedPrice = await _yahooService.fetchPriceAtDate(symbol, purchaseDate);
    final histPrice = fetchedPrice ?? purchasePrice;
    
    final stock = await _yahooService.fetchQuote(symbol);
    final livePrice = stock?.price ?? histPrice;

    final investment = Investment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      name: name,
      quantity: quantity,
      purchaseDate: purchaseDate,
      purchasePrice: histPrice,
      currentPrice: livePrice,
    );

    _investments.add(investment);
    await _saveInvestments();
    return investment;
  }

  Future<void> removeInvestment(String id) async {
    _investments.removeWhere((inv) => inv.id == id);
    await _saveInvestments();
  }

  Future<void> updateInvestment(Investment investment) async {
    final index = _investments.indexWhere((inv) => inv.id == investment.id);
    if (index != -1) {
      _investments[index] = investment;
      await _saveInvestments();
    }
  }

  PortfolioSummary get portfolioSummary {
    return PortfolioSummary.fromInvestments(_investments);
  }

  void _startPriceUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateAllPrices();
    });
    _updateAllPrices();
  }

  Future<void> _updateAllPrices() async {
    if (_investments.isEmpty) return;
    bool hasChanges = false;
    
    final symbols = _investments.map((e) => e.symbol).toSet().toList();
    final quotes = await _yahooService.fetchMultipleQuotes(symbols);

    for (int i = 0; i < _investments.length; i++) {
      final symbol = _investments[i].symbol;
      final stock = quotes[symbol];
      
      if (stock != null && stock.price != 0 && stock.price != _investments[i].currentPrice) {
        _investments[i] = _investments[i].copyWith(currentPrice: stock.price);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _investmentsController.add(_investments);
      notifyListeners();
    }
  }

  Future<void> refreshPrices() async {
    await _updateAllPrices();
  }

  void stopUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _investmentsController.close();
    super.dispose();
  }
}
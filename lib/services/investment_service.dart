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

  // --- Encryption (Kept same) ---
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
      debugPrint('Encryption failed: $e');
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
      debugPrint('Decryption failed: $e');
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
  Future<Investment?> addInvestment({
    required String symbol,
    required String name,
    required double quantity,
    required DateTime purchaseDate,
  }) async {
    double? purchasePrice = await _yahooService.fetchPriceAtDate(symbol, purchaseDate);
    
    // Fetch CURRENT stock data to fallback or get current price
    final stock = await _yahooService.fetchQuote(symbol);
    
    if (purchasePrice == null) {
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

  Future<Investment?> addInvestmentWithPrice({
    required String symbol,
    required String name,
    required double quantity,
    required DateTime purchaseDate,
    required double purchasePrice,
  }) async {
    double currentPrice = purchasePrice;
    
    if (GoldService.isGoldSymbol(symbol)) {
      currentPrice = _goldService.getPriceBySymbol(symbol) ?? purchasePrice;
    } else {
      final stock = await _yahooService.fetchQuote(symbol);
      currentPrice = stock?.price ?? purchasePrice;
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
    final regularSymbols = <String>{};
    
    for (final inv in _investments) {
      if (!GoldService.isGoldSymbol(inv.symbol)) {
        regularSymbols.add(inv.symbol);
      }
    }
    
    final quotes = await _yahooService.fetchMultipleQuotes(regularSymbols.toList());

    for (int i = 0; i < _investments.length; i++) {
      final symbol = _investments[i].symbol;
      double? newPrice;
      
      if (GoldService.isGoldSymbol(symbol)) {
        newPrice = _goldService.getPriceBySymbol(symbol);
      } else {
        newPrice = quotes[symbol]?.price;
      }
      
      if (newPrice != null && newPrice != 0 && newPrice != _investments[i].currentPrice) {
        _investments[i] = _investments[i].copyWith(currentPrice: newPrice);
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
    stopUpdates();
    _investmentsController.close();
    super.dispose();
  }
}
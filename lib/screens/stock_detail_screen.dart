import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/investment.dart';
import '../models/market_data.dart';
import '../services/yahoo_finance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_logo.dart';
import '../widgets/price_chart.dart'; 

class StockDetailScreen extends StatefulWidget {
  final Investment investment;

  const StockDetailScreen({
    super.key,
    required this.investment,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final YahooFinanceService _yahooService = YahooFinanceService();
  bool _isLoading = true;
  QuoteData? _quoteData;
  IntradayData? _intradayData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        _yahooService.fetchIntradayData(widget.investment.symbol),
        _yahooService.fetchFullQuote(widget.investment.symbol),
      ]);

      if (mounted) {
        setState(() {
          _intradayData = futures[0] as IntradayData?;
          _quoteData = futures[1] as QuoteData?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inv = widget.investment;
    
    final bool isGold = inv.symbol == 'GC=F' || inv.symbol.contains('GOLD');
    final Color accentColor = isGold 
        ? AppTheme.goldPrimary 
        : (inv.totalGain >= 0 ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        title: Row(
          children: [
            // Fix: 'name' is optional in StockLogo, passing it is fine
            StockLogo(symbol: inv.symbol, size: 32, name: inv.name),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.symbol, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  isGold ? 'Commodity' : 'Stock',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, inv, accentColor),
                const SizedBox(height: 24),
                if (_intradayData != null && _intradayData!.points.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: PriceChart(
                      data: _intradayData!.points, // Fix: Ensure this matches PriceChart param
                      previousClose: _intradayData!.previousClose,
                      isPositive: (_quoteData?.changePercent ?? 0) >= 0,
                    ),
                  ),
                const SizedBox(height: 24),
                _buildStatsCard(context, isDark),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context, Investment inv, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$${inv.currentPrice.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Icon(
              inv.totalGain >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              color: accent,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${inv.totalGain >= 0 ? '+' : ''}${inv.totalGainPercent.toStringAsFixed(2)}%',
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text('Today', style: TextStyle(color: Theme.of(context).hintColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildStatRow('Open', _quoteData?.open.toStringAsFixed(2) ?? '-'),
          const Divider(),
          _buildStatRow('High', _quoteData?.dayHigh.toStringAsFixed(2) ?? '-'),
          const Divider(),
          _buildStatRow('Low', _quoteData?.dayLow.toStringAsFixed(2) ?? '-'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
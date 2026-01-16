import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/investment.dart';
import '../models/market_data.dart';
import '../services/yahoo_finance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_logo.dart';
import '../widgets/price_chart.dart'; 
import '../widgets/news_feed_section.dart';

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
    
    // Performance Logic: Green if Gain > 0, Red if Gain < 0
    final bool isPositive = inv.totalGain >= 0;
    final Color accentColor = isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        title: Row(
          children: [
            StockLogo(symbol: inv.symbol, size: 32, name: inv.name),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.symbol, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  inv.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Layer 1: Content
          _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 180), // Padding for bottom glass widget
                  children: [
                    // Header & Chart (Full Page feel)
                    _buildHeader(context, inv, accentColor),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: PriceChart(
                        data: _intradayData?.points ?? [],
                        previousClose: _intradayData?.previousClose ?? 0,
                        isPositive: isPositive,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // News Section
                    Text(
                      "Latest News",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    NewsFeedSection(query: inv.name), // Pass stock name for relevant news
                  ],
                ),

          // Glass Widget at Bottom
          if (!_isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildGlassStatsPanel(context, isDark, inv, accentColor),
            ),
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
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Icon(
              inv.totalGain >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${inv.totalGain >= 0 ? '+' : ''}${inv.totalGain.toStringAsFixed(2)} (${inv.totalGainPercent.toStringAsFixed(2)}%)',
              style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text('All Time', style: TextStyle(color: Theme.of(context).hintColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassStatsPanel(BuildContext context, bool isDark, Investment inv, Color accent) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.8),
            border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(context, 'Open', _quoteData?.open.toStringAsFixed(2) ?? '-'),
                  _buildStatItem(context, 'High', _quoteData?.dayHigh.toStringAsFixed(2) ?? '-'),
                  _buildStatItem(context, 'Low', _quoteData?.dayLow.toStringAsFixed(2) ?? '-'),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(context, 'Avg Cost', inv.purchasePrice.toStringAsFixed(2)),
                  _buildStatItem(context, 'Holdings', '${inv.quantity.toStringAsFixed(0)} sh'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Market Value', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                      Text(
                        (inv.currentPrice * inv.quantity).toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}
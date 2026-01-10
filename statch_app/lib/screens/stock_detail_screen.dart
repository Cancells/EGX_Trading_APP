import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../services/yahoo_finance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/price_chart.dart';
import '../widgets/edit_investment_sheet.dart';

/// Stock Detail Screen with real-time graph and investment info
class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final String name;
  final Investment? investment;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.name,
    this.investment,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  final YahooFinanceService _yahooService = YahooFinanceService();
  
  late TabController _tabController;
  Timer? _updateTimer;
  
  IntradayData? _intradayData;
  QuoteData? _quoteData;
  bool _isLoading = true;
  String? _error;
  String _selectedRange = '1D';
  
  final ValueNotifier<double?> _selectedPrice = ValueNotifier(null);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchData();
    _startPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _updateTimer?.cancel();
    _selectedPrice.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  void _startPolling() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    try {
      final futures = await Future.wait([
        _yahooService.fetchIntradayData(widget.symbol),
        _yahooService.fetchQuote(widget.symbol),
      ]);

      if (mounted) {
        setState(() {
          _intradayData = futures[0] as IntradayData?;
          _quoteData = futures[1] as QuoteData?;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch data';
          _isLoading = false;
        });
      }
    }
  }

  void _openEditSheet() {
    if (widget.investment == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditInvestmentSheet(
        investment: widget.investment!,
        currentPrice: _quoteData?.price ?? widget.investment!.currentPrice,
        onSave: (updated) {
          Navigator.pop(context);
          Navigator.pop(context, updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.name,
              style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.investment != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: _openEditSheet,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildPriceHeader(formatter),
                      ),

                      // Chart
                      _buildChart(isDark),

                      // Time Range Selector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildRangeSelector(),
                      ),

                      const SizedBox(height: 24),

                      // Investment Details (if exists)
                      if (widget.investment != null)
                        _buildInvestmentCard(context, formatter, isDark),

                      // Stats Grid
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildStatsGrid(context, isDark),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPriceHeader(NumberFormat formatter) {
    final price = _quoteData?.price ?? 0;
    final change = _quoteData?.change ?? 0;
    final changePercent = _quoteData?.changePercent ?? 0;
    final isPositive = change >= 0;

    return ValueListenableBuilder<double?>(
      valueListenable: _selectedPrice,
      builder: (context, selectedPrice, _) {
        final displayPrice = selectedPrice ?? price;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '${formatter.format(displayPrice)} EGP',
                key: ValueKey(displayPrice),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPositive
                    ? AppTheme.robinhoodGreen.withValues(alpha: 0.1)
                    : AppTheme.robinhoodRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                    color: isPositive
                        ? AppTheme.robinhoodGreen
                        : AppTheme.robinhoodRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: isPositive
                          ? AppTheme.robinhoodGreen
                          : AppTheme.robinhoodRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Today',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChart(bool isDark) {
    final prices = _intradayData?.prices ?? [];
    if (prices.isEmpty) {
      return const SizedBox(height: 250);
    }

    final isPositive = (_quoteData?.change ?? 0) >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PriceChart(
        priceHistory: prices,
        isPositive: isPositive,
        selectedPriceNotifier: _selectedPrice,
        selectedIndexNotifier: _selectedIndex,
        height: 220,
      ),
    );
  }

  Widget _buildRangeSelector() {
    final ranges = ['1D', '1W', '1M', '3M'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ranges.map((range) {
        final isSelected = range == _selectedRange;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedRange = range);
            // TODO: Fetch data for selected range
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.robinhoodGreen.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.robinhoodGreen
                    : AppTheme.mutedText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvestmentCard(
    BuildContext context,
    NumberFormat formatter,
    bool isDark,
  ) {
    final inv = widget.investment!;
    final currentPrice = _quoteData?.price ?? inv.currentPrice;
    final currentValue = currentPrice * inv.quantity;
    final profitLoss = (currentPrice - inv.purchasePrice) * inv.quantity;
    final profitLossPercent = inv.purchasePrice > 0
        ? ((currentPrice - inv.purchasePrice) / inv.purchasePrice) * 100
        : 0.0;
    final isProfit = profitLoss >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isProfit
                ? AppTheme.robinhoodGreen.withValues(alpha: 0.15)
                : AppTheme.robinhoodRed.withValues(alpha: 0.15),
            isProfit
                ? AppTheme.robinhoodGreen.withValues(alpha: 0.05)
                : AppTheme.robinhoodRed.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProfit
              ? AppTheme.robinhoodGreen.withValues(alpha: 0.2)
              : AppTheme.robinhoodRed.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Position',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isProfit
                      ? AppTheme.robinhoodGreen.withValues(alpha: 0.2)
                      : AppTheme.robinhoodRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isProfit
                        ? AppTheme.robinhoodGreen
                        : AppTheme.robinhoodRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPositionStat(
                context,
                'Shares',
                inv.quantity.toStringAsFixed(2),
              ),
              _buildPositionStat(
                context,
                'Avg Cost',
                '${formatter.format(inv.purchasePrice)} EGP',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPositionStat(
                context,
                'Market Value',
                '${formatter.format(currentValue)} EGP',
              ),
              _buildPositionStat(
                context,
                'Total P/L',
                '${isProfit ? '+' : ''}${formatter.format(profitLoss)} EGP',
                valueColor: isProfit
                    ? AppTheme.robinhoodGreen
                    : AppTheme.robinhoodRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionStat(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildStatRow('Open', _quoteData?.previousClose.toStringAsFixed(2) ?? '-'),
              const Divider(height: 24),
              _buildStatRow('Previous Close', _quoteData?.previousClose.toStringAsFixed(2) ?? '-'),
              const Divider(height: 24),
              _buildStatRow('Day Range', '${(_quoteData?.previousClose ?? 0 * 0.98).toStringAsFixed(2)} - ${(_quoteData?.price ?? 0 * 1.02).toStringAsFixed(2)}'),
              const Divider(height: 24),
              _buildStatRow('Currency', _quoteData?.currency ?? 'EGP'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.mutedText),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

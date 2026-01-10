import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';
import '../services/gold_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_logo.dart';
import 'add_investment_screen.dart';
import 'stock_detail_screen.dart';

/// Portfolio Screen showing all investments with live P/L
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final InvestmentService _investmentService = InvestmentService();
  StreamSubscription<List<Investment>>? _subscription;
  List<Investment> _investments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await _investmentService.init();
    
    _subscription = _investmentService.investmentsStream.listen((investments) {
      if (mounted) {
        setState(() {
          _investments = investments;
          _isLoading = false;
        });
      }
    });

    setState(() {
      _investments = _investmentService.investments;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _addInvestment() async {
    final result = await Navigator.push<Investment>(
      context,
      MaterialPageRoute(builder: (context) => const AddInvestmentScreen()),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('${result.symbol} added to portfolio'),
            ],
          ),
          backgroundColor: AppTheme.robinhoodGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _deleteInvestment(Investment investment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Investment'),
        content: Text('Remove ${investment.symbol} from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.robinhoodRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _investmentService.removeInvestment(investment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = PortfolioSummary.fromInvestments(_investments);
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _investmentService.refreshPrices(),
            tooltip: 'Refresh Prices',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Portfolio Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildSummaryCard(context, summary, currencyFormat, isDark),
                  ),
                ),

                // Gold Investments Section
                if (_investments.any((inv) => GoldService.isGoldSymbol(inv.symbol)))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Gold Holdings',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_investments.where((inv) => GoldService.isGoldSymbol(inv.symbol)).length} positions',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                // Gold Investments List
                if (_investments.any((inv) => GoldService.isGoldSymbol(inv.symbol)))
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goldInvestments = _investments
                              .where((inv) => GoldService.isGoldSymbol(inv.symbol))
                              .toList();
                          final investment = goldInvestments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildInvestmentCard(
                              context, 
                              investment, 
                              currencyFormat, 
                              isDark,
                            ),
                          )
                              .animate(delay: Duration(milliseconds: 50 * index))
                              .fadeIn(duration: const Duration(milliseconds: 300))
                              .slideX(begin: 0.1, end: 0, duration: const Duration(milliseconds: 300));
                        },
                        childCount: _investments.where((inv) => GoldService.isGoldSymbol(inv.symbol)).length,
                      ),
                    ),
                  ),

                if (_investments.any((inv) => GoldService.isGoldSymbol(inv.symbol)))
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),

                // Stock Investments List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock Investments',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_investments.where((inv) => !GoldService.isGoldSymbol(inv.symbol)).length} positions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stock Investments List (non-gold)
                if (_investments.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(context),
                  )
                else if (_investments.where((inv) => !GoldService.isGoldSymbol(inv.symbol)).isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'No stock investments yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final stockInvestments = _investments
                              .where((inv) => !GoldService.isGoldSymbol(inv.symbol))
                              .toList();
                          final investment = stockInvestments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildInvestmentCard(
                              context, 
                              investment, 
                              currencyFormat, 
                              isDark,
                            ),
                          )
                              .animate(delay: Duration(milliseconds: 50 * index))
                              .fadeIn(duration: const Duration(milliseconds: 300))
                              .slideX(begin: 0.1, end: 0, duration: const Duration(milliseconds: 300));
                        },
                        childCount: _investments.where((inv) => !GoldService.isGoldSymbol(inv.symbol)).length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addInvestment,
        backgroundColor: AppTheme.robinhoodGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Investment'),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    PortfolioSummary summary,
    NumberFormat format,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0D1F0D),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF0FFF0),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.robinhoodGreen.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.robinhoodGreen.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${format.format(summary.currentValue)} EGP',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryMetric(
                context,
                'Invested',
                '${format.format(summary.totalInvested)} EGP',
                null,
              ),
              const SizedBox(width: 24),
              _buildSummaryMetric(
                context,
                'Profit/Loss',
                '${summary.isProfit ? '+' : ''}${format.format(summary.totalProfitLoss)} EGP',
                summary.isProfit ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
              ),
              const SizedBox(width: 24),
              _buildSummaryMetric(
                context,
                'Return',
                '${summary.isProfit ? '+' : ''}${summary.totalProfitLossPercent.toStringAsFixed(2)}%',
                summary.isProfit ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context,
    String label,
    String value,
    Color? valueColor,
  ) {
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
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.robinhoodGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppTheme.robinhoodGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No investments yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first investment to start tracking',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(
    BuildContext context,
    Investment investment,
    NumberFormat format,
    bool isDark,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isGold = GoldService.isGoldSymbol(investment.symbol);

    return Dismissible(
      key: Key(investment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.robinhoodRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteInvestment(investment);
        return false; // We handle deletion manually
      },
      child: GestureDetector(
        onTap: () => _openStockDetail(investment),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isGold
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF2D2408), const Color(0xFF1A1505)]
                      : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
                )
              : null,
          color: isGold ? null : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGold 
                ? AppTheme.goldPrimary.withValues(alpha: isDark ? 0.3 : 0.5)
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Symbol Badge / Logo
                if (isGold)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  )
                else
                  StockLogo(
                    symbol: investment.symbol,
                    name: investment.name,
                    size: 48,
                    isPositive: investment.isProfit,
                  ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              investment.symbol.replaceAll('.CA', ''),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isGold 
                                    ? (isDark ? AppTheme.goldPrimary : const Color(0xFF8B6914))
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isGold) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'GOLD',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.goldPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        investment.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // P/L
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${investment.isProfit ? '+' : ''}${format.format(investment.profitLoss)}',
                      style: TextStyle(
                        color: investment.isProfit
                            ? AppTheme.robinhoodGreen
                            : AppTheme.robinhoodRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${investment.isProfit ? '+' : ''}${investment.profitLossPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: investment.isProfit
                            ? AppTheme.robinhoodGreen
                            : AppTheme.robinhoodRed,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isGold 
                  ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInvestmentDetail(
                  context,
                  isGold ? 'Weight' : 'Quantity',
                  isGold 
                      ? '${investment.quantity.toStringAsFixed(2)}g'
                      : investment.quantity.toStringAsFixed(2),
                ),
                _buildInvestmentDetail(
                  context,
                  isGold ? 'Buy Price' : 'Avg Cost',
                  '${format.format(investment.purchasePrice)} EGP',
                ),
                _buildInvestmentDetail(
                  context,
                  'Current',
                  '${format.format(investment.currentPrice)} EGP',
                ),
                _buildInvestmentDetail(
                  context,
                  'Purchased',
                  dateFormat.format(investment.purchaseDate),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _openStockDetail(Investment investment) async {
    final result = await Navigator.push<Investment>(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailScreen(
          symbol: investment.symbol,
          name: investment.name,
          investment: investment,
        ),
      ),
    );

    // If investment was updated, refresh
    if (result != null && mounted) {
      setState(() {});
    }
  }

  Widget _buildInvestmentDetail(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedText,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

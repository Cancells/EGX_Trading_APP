import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../models/market_data.dart';
import '../services/investment_service.dart';
import '../repositories/market_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/portfolio_composition_chart.dart'; // Import the new chart
import 'add_investment_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  Widget build(BuildContext context) {
    final investmentService = context.watch<InvestmentService>();
    final investments = investmentService.investments;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portfolio', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
              );
            },
          ),
        ],
      ),
      body: investments.isEmpty
          ? _buildEmptyState(context)
          : StreamBuilder<MarketData>(
              stream: context.read<MarketRepository>().marketStream,
              builder: (context, snapshot) {
                final marketData = snapshot.data;
                // Calculate total based on what we have (simplified)
                final totalValue = _calculateTotal(investments, marketData);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Allocation Chart
                        Text(
                          'Allocation',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: PortfolioCompositionChart(
                            investments: investments,
                            totalValue: totalValue,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 2. Holdings List
                        Text(
                          'Holdings',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: investments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = investments[index];
                            // Find real price if available
                            final livePrice = _getLivePrice(item.symbol, marketData);
                            return _buildHoldingCard(context, item, livePrice);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHoldingCard(BuildContext context, Investment investment, double currentPrice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
    
    final totalValue = investment.shares * currentPrice;
    final costBasis = investment.shares * investment.averagePrice;
    final gainLoss = totalValue - costBasis;
    final gainLossPercent = (gainLoss / costBasis) * 100;
    final isPositive = gainLoss >= 0;

    return Dismissible(
      key: Key(investment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        context.read<InvestmentService>().removeInvestment(investment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sold ${investment.symbol}')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo / Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  investment.symbol.substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Symbol & Shares
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investment.symbol,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${investment.shares.toStringAsFixed(0)} shares',
                    style: const TextStyle(color: AppTheme.mutedText, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Value & Gain/Loss
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(totalValue),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${gainLossPercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 80, color: AppTheme.mutedText.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No investments yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.mutedText),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvestmentScreen()));
            },
            icon: const Icon(Icons.add),
            label: const Text('Add your first stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.robinhoodGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          )
        ],
      ),
    );
  }

  double _calculateTotal(List<Investment> investments, MarketData? data) {
    double total = 0;
    for (var inv in investments) {
      final price = _getLivePrice(inv.symbol, data);
      total += (inv.shares * price);
    }
    return total;
  }

  double _getLivePrice(String symbol, MarketData? data) {
    if (data == null) return 0.0;
    // Try to find in live stocks
    try {
      final stock = data.stocks.firstWhere((s) => s.symbol == symbol);
      return stock.price;
    } catch (_) {
      // Fallback: This is where you'd query a cache or return last known price
      // For now, return a dummy multiplier of the investment avg price to simulate movement
      // In production: Investment model should store 'currentPrice' updated by Repo
      return 0.0; // Or inv.averagePrice
    }
  }
}
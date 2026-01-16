import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/investment_service.dart';
import '../services/currency_service.dart';
import '../services/preferences_service.dart';
import '../widgets/portfolio_summary_card.dart';
import '../widgets/modern_stock_card.dart';
import '../widgets/market_switcher.dart';
import 'add_investment_screen.dart';
import 'stock_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final investmentService = Provider.of<InvestmentService>(context);
    final prefs = Provider.of<PreferencesService>(context);
    final currencyService = Provider.of<CurrencyService>(context);

    // Filter logic can be added here based on MarketSwitcher if needed
    final investments = investmentService.investments;
    
    // Simulate loading if list is empty but we expect data (simplified)
    // In a real app, InvestmentService would have an 'isLoading' flag
    final bool isLoading = investments.isEmpty && investmentService.investmentsStream == null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact(); // Haptic Feedback
          await currencyService.fetchExchangeRates();
          await investmentService.refreshPrices();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: PortfolioSummaryCard(
                  summary: investmentService.portfolioSummary,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: MarketSwitcher(),
            ),
            const SliverPadding(padding: EdgeInsets.symmetric(vertical: 8)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (isLoading) {
                      // Show 3 skeleton loaders
                      if (index < 3) {
                        return const ModernStockCard(investment: null);
                      }
                      return null;
                    }
                    
                    if (index >= investments.length) return null;
                    
                    final investment = investments[index];
                    return ModernStockCard(
                      investment: investment,
                      isPrivacyMode: prefs.isPrivacyModeEnabled,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockDetailScreen(investment: investment),
                        ),
                      ),
                    );
                  },
                  childCount: isLoading ? 3 : investments.length,
                ),
              ),
            ),
            // Bottom padding for FAB
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.selectionClick();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
          );
        },
        label: const Text('Add Asset'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
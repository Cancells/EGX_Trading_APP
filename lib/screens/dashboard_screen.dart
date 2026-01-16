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
import 'settings_screen.dart'; // Ensure you have this import
import 'profile_screen.dart'; // Ensure you have this import

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

    final investments = investmentService.investments;
    final bool isEmpty = investments.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await currencyService.fetchExchangeRates();
          await investmentService.refreshPrices();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. HEADER (Profile & Settings) - FIXED
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  Text(
                    prefs.userName.isNotEmpty ? prefs.userName : 'Investor',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // 2. Portfolio Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: PortfolioSummaryCard(
                  summary: investmentService.portfolioSummary,
                ),
              ),
            ),

            // 3. Market Switcher
            const SliverToBoxAdapter(
              child: MarketSwitcher(selectedIndex: 0),
            ),
            
            const SliverPadding(padding: EdgeInsets.symmetric(vertical: 12)),

            // 4. Investment List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (isEmpty) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.add_chart, size: 48, color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "No assets yet",
                                  style: TextStyle(color: Colors.grey.withOpacity(0.8)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
                                  ),
                                  child: const Text("Add your first investment"),
                                )
                              ],
                            ),
                          ),
                        );
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
                  childCount: isEmpty ? 1 : investments.length,
                ),
              ),
            ),
            
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}
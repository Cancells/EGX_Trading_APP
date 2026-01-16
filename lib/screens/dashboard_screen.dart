import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/investment_service.dart';
import '../services/currency_service.dart';
import '../services/preferences_service.dart';
import '../widgets/modern_stock_card.dart';
import '../widgets/market_switcher.dart';
import 'add_investment_screen.dart';
import 'stock_detail_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State for the pinned glass header tabs
  String _selectedPeriod = '1D';

  @override
  Widget build(BuildContext context) {
    final investmentService = Provider.of<InvestmentService>(context);
    final prefs = Provider.of<PreferencesService>(context);
    final currencyService = Provider.of<CurrencyService>(context);

    final investments = investmentService.investments;
    final bool isEmpty = investments.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 5. Floating Action Button on Bottom Left
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await currencyService.fetchExchangeRates();
          await investmentService.refreshPrices();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1, 3, 4. Header with Swapped Icons
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              // 4. Settings on Left
              leading: IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
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
              // 3. Profile on Right (with shape)
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Pinned Glass Widget (Daily/Weekly/Monthly/YTD)
            SliverPersistentHeader(
              pinned: true,
              delegate: _GlassPortfolioHeaderDelegate(
                topPadding: MediaQuery.of(context).padding.top,
                summary: investmentService.portfolioSummary,
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (period) {
                  setState(() => _selectedPeriod = period);
                },
                isPrivacyMode: prefs.isPrivacyModeEnabled,
                togglePrivacy: prefs.togglePrivacyMode,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

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
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
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

// 2. The Glass Header Delegate
class _GlassPortfolioHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final PortfolioSummary summary;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool isPrivacyMode;
  final VoidCallback togglePrivacy;

  _GlassPortfolioHeaderDelegate({
    required this.topPadding,
    required this.summary,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isPrivacyMode,
    required this.togglePrivacy,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Logic to switch displayed gain based on selected tab
    // Note: In a real app, you would fetch different historical data.
    // Here we simulate or map available fields.
    double displayGain = summary.totalGain;
    double displayGainPercent = summary.totalGainPercent;
    String periodLabel = "Total Return";

    if (selectedPeriod == '1D') {
      displayGain = summary.dayGain;
      displayGainPercent = summary.dayGainPercent;
      periodLabel = "Today's Return";
    } else if (selectedPeriod == '1W') {
      // Simulate/Placeholder for 1W
      periodLabel = "Weekly Return";
    } 
    // ... extend for 1M, YTD

    final isPositive = displayGain >= 0;
    final color = isPositive ? const Color(0xFF00C805) : const Color(0xFFFF5000);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Total Balance
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portfolio Value',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPrivacyMode ? '****' : 'EGP ${summary.totalValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                     IconButton(
                        icon: Icon(
                          isPrivacyMode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: togglePrivacy,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['1D', '1W', '1M', 'YTD'].map((period) {
                    final isSelected = selectedPeriod == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onPeriodChanged(period),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (isDark ? Colors.white : Colors.black) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? Colors.transparent 
                                  : (isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                          child: Text(
                            period,
                            style: TextStyle(
                              color: isSelected 
                                  ? (isDark ? Colors.black : Colors.white) 
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),
              
              // Selected Period Gain
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      periodLabel,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    const Spacer(),
                    Text(
                      isPrivacyMode 
                          ? '***' 
                          : '${isPositive ? '+' : ''}${displayGain.toStringAsFixed(2)} (${displayGainPercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 180;

  @override
  double get minExtent => 180;

  @override
  bool shouldRebuild(covariant _GlassPortfolioHeaderDelegate oldDelegate) {
    return oldDelegate.selectedPeriod != selectedPeriod || 
           oldDelegate.summary != summary ||
           oldDelegate.isPrivacyMode != isPrivacyMode;
  }
}
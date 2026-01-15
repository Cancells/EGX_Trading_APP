import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/market_data.dart';
import '../repositories/market_repository.dart';
import '../services/preferences_service.dart';
import '../services/investment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/statch_logo.dart';
import '../widgets/portfolio_summary_card.dart';
import '../widgets/gold_calculator_sheet.dart';
import '../widgets/index_carousel.dart'; // NEW
import '../widgets/modern_stock_card.dart'; // NEW
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'portfolio_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const DashboardScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PreferencesService _prefsService = PreferencesService();
  late MarketRepository _marketRepo;

  @override
  void initState() {
    super.initState();
    _marketRepo = context.read<MarketRepository>();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await _marketRepo.refresh();
  }

  // Calculate real user balance
  double _calculateTotalBalance(InvestmentService investmentService, MarketData marketData) {
    double total = 0;
    if (investmentService.investments.isEmpty) {
      return 0.0; // Clean start
    }
    for (var investment in investmentService.investments) {
      final stock = marketData.stocks.firstWhere(
        (s) => s.symbol == investment.symbol, 
        orElse: () => Stock(symbol: '', name: '', price: 0, change: 0, changePercent: 0, priceHistory: [], lastUpdated: DateTime.now())
      );
      
      double price = stock.symbol.isNotEmpty ? stock.price : investment.averagePrice;
      total += (investment.shares * price);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<MarketData>(
        stream: _marketRepo.marketStream,
        builder: (context, snapshot) {
          final isLoading = !snapshot.hasData;
          final data = snapshot.data;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.robinhoodGreen,
            backgroundColor: Theme.of(context).cardColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: isLoading || data == null
                          ? _buildSkeletonLoader(context)
                          : _buildModernContent(context, data),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: const Padding(
        padding: EdgeInsets.only(left: 20),
        child: StatchLogo(size: 28),
      ),
      leadingWidth: 50,
      title: Text(
        'Statch',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {}, // TODO: Notifications
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20, left: 8),
          child: GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.robinhoodGreen.withOpacity(0.15),
              child: Text(
                _prefsService.userName.isNotEmpty ? _prefsService.userName[0].toUpperCase() : 'I',
                style: const TextStyle(
                  color: AppTheme.robinhoodGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernContent(BuildContext context, MarketData data) {
    // ... inside _buildModernContent(BuildContext context, MarketData data) {

// ... Portfolio Summary Card code ...

            const SizedBox(height: 32),
            
            // 3. Market Indices Carousel
            Text('Indices', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // UPDATE THIS WIDGET
            IndexCarousel(
              egxValue: data.egx30.value,
              egxChange: data.egx30.changePercent,
              goldValue: data.gold21k.pricePerGram,
              goldChange: data.gold21k.changePercent,
              silverValue: data.silver?.pricePerGram, // <--- Passing Silver Price
              silverChange: data.silver?.changePercent, // <--- Passing Silver Change
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 32),

// ... rest of the code
    return Consumer<InvestmentService>(
      builder: (context, investmentService, _) {
        final balance = _calculateTotalBalance(investmentService, data);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // 1. Portfolio Card
            PortfolioSummaryCard(
              balance: balance,
              dayChange: data.egx30.change, // Simplified for demo
              dayChangePercent: data.egx30.changePercent,
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            // 2. Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(context, Icons.add, 'Add Asset', () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioScreen()));
                }),
                _buildQuickAction(context, Icons.calculate_outlined, 'Gold Calc', () {
                  _showGoldCalculator(context, data);
                }),
                _buildQuickAction(context, Icons.newspaper_outlined, 'News', () {}),
                _buildQuickAction(context, Icons.more_horiz, 'More', () {}),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 3. Market Indices Carousel
            Text('Indices', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Pass negative value for Gold to simulate realistic mixed market
            IndexCarousel(
              egxValue: data.egx30.value,
              egxChange: data.egx30.changePercent,
              goldValue: data.gold24k.pricePerGram,
              goldChange: data.gold24k.changePercent,
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 32),
            
            // 4. Watchlist / Stocks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Movers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('See All', style: TextStyle(color: AppTheme.robinhoodGreen, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...data.stocks.map((stock) => ModernStockCard(stock: stock).animate().fadeIn().slideX()),
            
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Icon(icon, color: AppTheme.robinhoodGreen, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    // Keep your existing skeleton loader or use a simplified one
    return Container(); 
  }

  void _showGoldCalculator(BuildContext context, MarketData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GoldCalculatorSheet(
          price24k: data.gold24k.pricePerGram,
          price21k: data.gold21k.pricePerGram,
          price18k: data.gold18k?.pricePerGram ?? 0,
        ),
      ),
    );
  }

  // Keep _showProfileMenu and _buildProfileMenu from previous code
  void _showProfileMenu(BuildContext context) {
     Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/market_data.dart';
import '../repositories/market_repository.dart'; // Import Repository
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/stock_card.dart';
import '../widgets/statch_logo.dart';
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
  late MarketRepository _marketRepo; // Use Repository

  final ValueNotifier<double?> _selectedPrice = ValueNotifier(null);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    // Get the repository
    _marketRepo = context.read<MarketRepository>();
    // Note: init() is already called in main.dart, but we can trigger a refresh if needed
  }

  @override
  void dispose() {
    _selectedPrice.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await _marketRepo.refresh(); // Calls the improved repository refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<MarketData>(
        stream: _marketRepo.marketStream, // Listen to Repository Stream
        builder: (context, snapshot) {
          final isLoading = !snapshot.hasData;
          final data = snapshot.data;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            edgeOffset: 100,
            color: AppTheme.robinhoodGreen,
            backgroundColor: Theme.of(context).cardColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildSliverAppBar(context),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: isLoading || data == null
                          ? _buildSkeletonLoader(context)
                          : _buildDashboardContent(context, data),
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
    // Keep your existing App Bar code...
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      elevation: 0,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: StatchLogo(size: 32),
      ),
      title: Text(
        'Statch',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: Hero(
              tag: 'profile_menu_avatar',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.robinhoodGreen.withOpacity(0.2),
                child: Text(
                  _prefsService.userName.isNotEmpty 
                      ? _prefsService.userName[0].toUpperCase() 
                      : 'I',
                  style: const TextStyle(
                    color: AppTheme.robinhoodGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ... Include _buildSkeletonLoader, _buildDashboardContent, PortfolioHeader ...
  // (Paste the implementation from the previous DashboardScreen code block here)
  
  Widget _buildSkeletonLoader(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(width: 100, height: 14, color: color).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
        const SizedBox(height: 8),
        Container(width: 180, height: 36, color: color).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, delay: 100.ms),
        const SizedBox(height: 24),
        Container(height: 220, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20))).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, MarketData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        PortfolioHeader(data: data, selectedPriceNotifier: _selectedPrice),
        const SizedBox(height: 24),
        _buildMainChartContainer(context, data),
        const SizedBox(height: 32),
        Text('Gold Prices', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GoldCard(goldPrice: data.gold24k),
        const SizedBox(height: 12),
        GoldCard(goldPrice: data.gold21k),
        const SizedBox(height: 32),
        Text('Egyptian Stocks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...data.stocks.map((stock) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StockCard(stock: stock),
        )),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMainChartContainer(BuildContext context, MarketData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PriceChart(
              priceHistory: data.egx30.priceHistory,
              isPositive: data.egx30.isPositive,
              selectedPriceNotifier: _selectedPrice,
              selectedIndexNotifier: _selectedIndex,
              height: 220,
            ),
          ),
        ],
      ),
    );
  }

  // Keep _showProfileMenu, _buildProfileMenu, PortfolioHeader same as before
  void _showProfileMenu(BuildContext context) {
    // ... existing implementation
  }
}

// Ensure PortfolioHeader class is present at bottom of file as defined in previous answers
class PortfolioHeader extends StatelessWidget {
  final MarketData data;
  final ValueNotifier<double?> selectedPriceNotifier;
  const PortfolioHeader({super.key, required this.data, required this.selectedPriceNotifier});
  
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
    return ValueListenableBuilder<double?>(
      valueListenable: selectedPriceNotifier,
      builder: (context, selectedPrice, _) {
        final displayValue = selectedPrice ?? data.egx30.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EGX 30 Index', style: Theme.of(context).textTheme.bodyMedium),
            Text(formatter.format(displayValue), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }
}
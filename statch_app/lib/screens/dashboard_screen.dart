import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/market_data.dart';
import '../repositories/market_repository.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/stock_card.dart';
import '../widgets/statch_logo.dart';
import '../widgets/portfolio_summary_card.dart'; // NEW
import '../widgets/gold_calculator_sheet.dart';  // NEW
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

  final ValueNotifier<double?> _selectedPrice = ValueNotifier(null);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _marketRepo = context.read<MarketRepository>();
  }

  @override
  void dispose() {
    _selectedPrice.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await _marketRepo.refresh();
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

  Widget _buildSkeletonLoader(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(width: double.infinity, height: 160, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24))).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
        const SizedBox(height: 24),
        Container(height: 220, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20))).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, delay: 200.ms),
        const SizedBox(height: 32),
        Container(width: 120, height: 24, color: color),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, MarketData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        // 1. Personal Wealth (Privacy-First Card)
        // Note: Using simulated balance logic for demo. Hook this to InvestmentService in future.
        PortfolioSummaryCard(
          balance: data.egx30.value * 75.5, 
          dayChange: data.egx30.change * 75.5,
          dayChangePercent: data.egx30.changePercent,
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 32),
        
        // 2. Market Index Chart
        Text(
          'Market Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildMainChartContainer(context, data).animate().fadeIn(delay: 100.ms),
        
        const SizedBox(height: 32),
        
        // 3. Gold Section with Calculator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gold Prices',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _showGoldCalculator(context, data),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Calculator'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.goldPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: AppTheme.goldPrimary.withOpacity(0.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GoldCard(goldPrice: data.gold24k),
        const SizedBox(height: 12),
        GoldCard(goldPrice: data.gold21k),
        
        const SizedBox(height: 32),
        
        // 4. Stocks
        Text(
          'Egyptian Stocks', 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Index Header integrated inside chart container for better UX
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PortfolioHeader(
              data: data, 
              selectedPriceNotifier: _selectedPrice,
            ),
          ),
          const SizedBox(height: 16),
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

  void _showGoldCalculator(BuildContext context, MarketData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GoldCalculatorSheet(
          price24k: data.gold24k.pricePerGram,
          price21k: data.gold21k.pricePerGram,
          price18k: data.gold18k?.pricePerGram ?? 0,
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildProfileMenu(context),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.robinhoodGreen,
              child: Text(
                _prefsService.userName.isNotEmpty ? _prefsService.userName[0].toUpperCase() : 'I',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(_prefsService.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Egyptian Investor'),
          ),
          const Divider(),
          _buildMenuItem(context, Icons.pie_chart_outline, 'Portfolio', () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioScreen()));
          }),
          _buildMenuItem(context, Icons.person_outline, 'Profile', () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          _buildMenuItem(context, Icons.settings_outlined, 'Settings', () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(onThemeToggle: widget.onThemeToggle)));
          }),
           _buildMenuItem(context, Icons.info_outline, 'About', () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}

// PortfolioHeader for the Market Index (Chart Header)
class PortfolioHeader extends StatelessWidget {
  final MarketData data;
  final ValueNotifier<double?> selectedPriceNotifier;
  
  const PortfolioHeader({
    super.key, 
    required this.data, 
    required this.selectedPriceNotifier
  });
  
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
    
    return ValueListenableBuilder<double?>(
      valueListenable: selectedPriceNotifier,
      builder: (context, selectedPrice, _) {
        final displayValue = selectedPrice ?? data.egx30.value;
        final isScrubbing = selectedPrice != null;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isScrubbing ? 'Selected Value' : 'EGX 30 Index', 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatter.format(displayValue), 
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ],
        );
      },
    );
  }
}
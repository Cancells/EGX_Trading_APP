import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/market_data.dart';
import '../services/market_data_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/stock_card.dart';
import '../widgets/statch_logo.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

/// Main Dashboard Screen - Robinhood Style
class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const DashboardScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final MarketDataService _marketService = MarketDataService();
  final PreferencesService _prefsService = PreferencesService();
  
  final ValueNotifier<double?> _selectedPrice = ValueNotifier(null);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  
  MarketData? _marketData;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _marketService.startStreaming();
    _marketService.marketDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _marketData = data;
        });
        if (!_fadeController.isCompleted) {
          _fadeController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _marketService.stopStreaming();
    _selectedPrice.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // User Info Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Hero(
                  tag: 'profile_avatar',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.robinhoodGreen,
                    child: Text(
                      _prefsService.userName.isNotEmpty 
                          ? _prefsService.userName[0].toUpperCase()
                          : 'I',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _prefsService.userName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Egyptian Investor',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(height: 1),
          
          // Menu Items
          _buildMenuItem(
            context,
            icon: Icons.account_circle_outlined,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onThemeToggle: widget.onThemeToggle,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outlined,
            title: 'About',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 24,
        weight: 300,
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _marketData == null
              ? _buildLoadingState()
              : _buildDashboard(context, isDark),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AnimatedStatchLogo(size: 80),
          const SizedBox(height: 24),
          Text(
            'Loading Market Data...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, bool isDark) {
    final data = _marketData!;
    
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          pinned: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: StatchLogo(size: 32),
          ),
          title: Text(
            'Statch',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Profile Button (Top-Right)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _showProfileMenu(context),
                child: Hero(
                  tag: 'profile_menu_avatar',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.robinhoodGreen,
                    child: Text(
                      _prefsService.userName.isNotEmpty 
                          ? _prefsService.userName[0].toUpperCase()
                          : 'I',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Main Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Portfolio Value Header
                _buildPortfolioHeader(context, data),
                
                const SizedBox(height: 24),
                
                // Main Chart
                _buildMainChart(context, data),
                
                const SizedBox(height: 32),
                
                // Gold Section
                Text(
                  'Gold Prices',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GoldCard(goldPrice: data.gold24k),
                const SizedBox(height: 12),
                GoldCard(goldPrice: data.gold21k),
                
                const SizedBox(height: 32),
                
                // Stocks Section
                Text(
                  'Egyptian Stocks',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...data.stocks.map((stock) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StockCard(stock: stock),
                )),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioHeader(BuildContext context, MarketData data) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    
    return ValueListenableBuilder<double?>(
      valueListenable: _selectedPrice,
      builder: (context, selectedPrice, child) {
        final displayValue = selectedPrice ?? data.egx30.value;
        final isSelected = selectedPrice != null;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSelected ? 'EGX 30 Value' : 'EGX 30 Index',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '${formatter.format(displayValue)} EGP',
                key: ValueKey(displayValue),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: data.egx30.isPositive
                    ? AppTheme.robinhoodGreen.withOpacity(0.1)
                    : AppTheme.robinhoodRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    data.egx30.isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                    color: data.egx30.isPositive
                        ? AppTheme.robinhoodGreen
                        : AppTheme.robinhoodRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data.egx30.change >= 0 ? '+' : ''}${data.egx30.change.toStringAsFixed(2)} (${data.egx30.changePercent >= 0 ? '+' : ''}${data.egx30.changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: data.egx30.isPositive
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

  Widget _buildMainChart(BuildContext context, MarketData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          PriceChart(
            priceHistory: data.egx30.priceHistory,
            isPositive: data.egx30.isPositive,
            selectedPriceNotifier: _selectedPrice,
            selectedIndexNotifier: _selectedIndex,
            height: 220,
          ),
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];
    const selectedIndex = 0; // Default to 1D
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ranges.asMap().entries.map((entry) {
        final isSelected = entry.key == selectedIndex;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.robinhoodGreen.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.value,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.robinhoodGreen
                  : AppTheme.mutedText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }
}

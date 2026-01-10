import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/market_data.dart';
import '../services/market_data_service.dart';
import '../services/preferences_service.dart';
import '../services/gold_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/stock_card.dart';
import '../widgets/statch_logo.dart';
import '../widgets/market_switcher.dart';
import '../widgets/stock_chip.dart';
import 'profile_screen.dart';
import 'about_screen.dart';

/// Home Screen (Dashboard) - Robinhood Style with Market Switcher
class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final MarketDataService _marketService = MarketDataService();
  final PreferencesService _prefsService = PreferencesService();
  final GoldService _goldService = GoldService();
  
  final ValueNotifier<double?> _selectedPrice = ValueNotifier(null);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  
  MarketData? _marketData;
  MarketType _selectedMarket = MarketType.egx30;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // US Market stocks
  final List<StockChipData> _usStocks = [
    StockChipData(symbol: 'AAPL', name: 'Apple Inc.', price: 178.50, changePercent: 1.24),
    StockChipData(symbol: 'GOOGL', name: 'Alphabet Inc.', price: 141.80, changePercent: -0.56),
    StockChipData(symbol: 'MSFT', name: 'Microsoft Corp.', price: 378.90, changePercent: 0.89),
    StockChipData(symbol: 'AMZN', name: 'Amazon.com Inc.', price: 178.25, changePercent: 1.67),
    StockChipData(symbol: 'TSLA', name: 'Tesla Inc.', price: 248.50, changePercent: -2.34),
  ];

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

    // Initialize gold service
    _goldService.init();
    _goldService.addListener(_onGoldServiceUpdate);
  }

  void _onGoldServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _marketService.stopStreaming();
    _goldService.removeListener(_onGoldServiceUpdate);
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
              color: Colors.grey.withValues(alpha: 0.3),
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
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText))
          : null,
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
                
                // Market Switcher
                MarketSwitcher(
                  selected: _selectedMarket,
                  onChanged: (market) {
                    setState(() => _selectedMarket = market);
                  },
                ),
                
                const SizedBox(height: 24),

                // US Market Ticker Strip (when US selected)
                if (_selectedMarket == MarketType.us) ...[
                  Text(
                    'Trending',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StockChipList(
                    stocks: _usStocks,
                    onStockTap: (stock) {
                      // Navigate to stock detail
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Precious Metals Section (at top when EGX selected)
                if (_selectedMarket == MarketType.egx30) ...[
                  _buildPreciousMetalsSection(context, isDark),
                  const SizedBox(height: 32),
                ],
                
                // Portfolio Value Header
                _buildPortfolioHeader(context, data),
                
                const SizedBox(height: 24),
                
                // Main Chart
                _buildMainChart(context, data),
                
                const SizedBox(height: 32),
                
                // Legacy Gold Section (when US selected or as backup)
                if (_selectedMarket == MarketType.us) ...[
                  _buildGoldSection(context),
                  const SizedBox(height: 32),
                ],
                
                // Stocks Section
                Text(
                  _selectedMarket == MarketType.us 
                      ? 'US Stocks' 
                      : 'Egyptian Stocks',
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

  Widget _buildPreciousMetalsSection(BuildContext context, bool isDark) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Workmanship Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Precious Metals',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Per Gram Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Live',
                style: TextStyle(
                  color: AppTheme.goldPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Workmanship Toggle
        _buildWorkmanshipToggle(context, isDark),
        
        const SizedBox(height: 16),
        
        // Gold Price Cards
        ListenableBuilder(
          listenable: _goldService,
          builder: (context, _) {
            if (_goldService.isLoading && _goldService.prices.isEmpty) {
              return _buildGoldLoadingState();
            }
            
            if (_goldService.prices.isEmpty) {
              // Fallback to mock data
              return Column(
                children: [
                  GoldCard(goldPrice: _marketData!.gold24k),
                  const SizedBox(height: 12),
                  GoldCard(goldPrice: _marketData!.gold21k),
                ],
              );
            }
            
            return Column(
              children: [
                // 24K Gold
                _buildPreciousMetalCard(
                  context,
                  isDark,
                  title: 'Gold 24K',
                  subtitle: 'Pure Gold',
                  price: _goldService.getDisplayPrice(GoldKarat.k24),
                  rawPrice: _goldService.prices[GoldKarat.k24]?.pricePerGram ?? 0,
                  changePercent: _goldService.prices[GoldKarat.k24]?.changePercent ?? 0,
                  isPositive: _goldService.prices[GoldKarat.k24]?.isPositive ?? true,
                  formatter: formatter,
                ),
                const SizedBox(height: 12),
                
                // 21K Gold
                _buildPreciousMetalCard(
                  context,
                  isDark,
                  title: 'Gold 21K',
                  subtitle: 'Egyptian Standard',
                  price: _goldService.getDisplayPrice(GoldKarat.k21),
                  rawPrice: _goldService.prices[GoldKarat.k21]?.pricePerGram ?? 0,
                  changePercent: _goldService.prices[GoldKarat.k21]?.changePercent ?? 0,
                  isPositive: _goldService.prices[GoldKarat.k21]?.isPositive ?? true,
                  formatter: formatter,
                ),
                const SizedBox(height: 12),
                
                // 18K Gold
                _buildPreciousMetalCard(
                  context,
                  isDark,
                  title: 'Gold 18K',
                  subtitle: 'Jewelry Gold',
                  price: _goldService.getDisplayPrice(GoldKarat.k18),
                  rawPrice: _goldService.prices[GoldKarat.k18]?.pricePerGram ?? 0,
                  changePercent: _goldService.prices[GoldKarat.k18]?.changePercent ?? 0,
                  isPositive: _goldService.prices[GoldKarat.k18]?.isPositive ?? true,
                  formatter: formatter,
                ),
                const SizedBox(height: 12),
                
                // Gold Pound (Geneh)
                if (_goldService.goldPoundPrice != null)
                  _buildGoldPoundCard(context, isDark, formatter),
              ],
            );
          },
        ),
        
        // Exchange Rate Info
        ListenableBuilder(
          listenable: _goldService,
          builder: (context, _) {
            if (_goldService.usdToEgp > 0 && _goldService.goldSpotUsd > 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.mutedText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gold Spot: \$${_goldService.goldSpotUsd.toStringAsFixed(2)}/oz • USD/EGP: ${_goldService.usdToEgp.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildWorkmanshipToggle(BuildContext context, bool isDark) {
    return ListenableBuilder(
      listenable: _goldService,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: _goldService.includeWorkmanship
                ? Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.construction_rounded,
                size: 20,
                color: _goldService.includeWorkmanship 
                    ? AppTheme.goldPrimary 
                    : AppTheme.mutedText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workmanship',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _goldService.includeWorkmanship 
                            ? AppTheme.goldPrimary 
                            : null,
                      ),
                    ),
                    Text(
                      _goldService.includeWorkmanship
                          ? 'Shop Buying Price (+${_goldService.workmanshipFee.toStringAsFixed(0)} EGP/g)'
                          : 'Raw Market Price',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _goldService.includeWorkmanship,
                onChanged: (value) => _goldService.setWorkmanship(value),
                activeColor: AppTheme.goldPrimary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreciousMetalCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
    required double price,
    required double rawPrice,
    required double changePercent,
    required bool isPositive,
    required NumberFormat formatter,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D2408), const Color(0xFF1A1505)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppTheme.goldPrimary : const Color(0xFF8B6914),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(price)} EGP',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_goldService.includeWorkmanship && rawPrice > 0)
                Text(
                  'Raw: ${formatter.format(rawPrice)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontSize: 10,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: isPositive
                        ? AppTheme.robinhoodGreen
                        : AppTheme.robinhoodRed,
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive
                          ? AppTheme.robinhoodGreen
                          : AppTheme.robinhoodRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoldPoundCard(BuildContext context, bool isDark, NumberFormat formatter) {
    final poundPrice = _goldService.goldPoundPrice!;
    final displayPrice = _goldService.getGoldPoundDisplayPrice();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D2408), const Color(0xFF1A1505), const Color(0xFF0D0A02)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3), const Color(0xFFFFE082)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFDAA520)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gold Pound (Geneh)',
                  style: TextStyle(
                    color: isDark ? AppTheme.goldPrimary : const Color(0xFF8B6914),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '8 grams of 21K gold',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(displayPrice)} EGP',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_goldService.includeWorkmanship)
                Text(
                  'Raw: ${formatter.format(poundPrice.price)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontSize: 10,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    poundPrice.isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: poundPrice.isPositive
                        ? AppTheme.robinhoodGreen
                        : AppTheme.robinhoodRed,
                  ),
                  Text(
                    '${poundPrice.isPositive ? '+' : ''}${poundPrice.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: poundPrice.isPositive
                          ? AppTheme.robinhoodGreen
                          : AppTheme.robinhoodRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoldLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.goldPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.goldPrimary),
            ),
            SizedBox(height: 12),
            Text(
              'Loading gold prices...',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
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
                    ? AppTheme.robinhoodGreen.withValues(alpha: 0.1)
                    : AppTheme.robinhoodRed.withValues(alpha: 0.1),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildGoldSection(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Egyptian Gold',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Per Gram',
                style: TextStyle(
                  color: AppTheme.goldPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Gold cards for each karat
        ListenableBuilder(
          listenable: _goldService,
          builder: (context, _) {
            if (_goldService.prices.isEmpty) {
              // Use mock data
              return Column(
                children: [
                  GoldCard(goldPrice: _marketData!.gold24k),
                  const SizedBox(height: 12),
                  GoldCard(goldPrice: _marketData!.gold21k),
                ],
              );
            }
            
            return Column(
              children: GoldKarat.values.map((karat) {
                final price = _goldService.getPrice(karat);
                if (price == null) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEgyptianGoldCard(context, price, formatter),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEgyptianGoldCard(
    BuildContext context,
    EgyptianGoldPrice price,
    NumberFormat formatter,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D2408), const Color(0xFF1A1505)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gold ${price.karat.label}',
                  style: TextStyle(
                    color: isDark ? AppTheme.goldPrimary : const Color(0xFF8B6914),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  price.karat.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(price.pricePerGram)} EGP',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    price.isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: price.isPositive
                        ? AppTheme.robinhoodGreen
                        : AppTheme.robinhoodRed,
                  ),
                  Text(
                    '${price.isPositive ? '+' : ''}${price.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: price.isPositive
                          ? AppTheme.robinhoodGreen
                          : AppTheme.robinhoodRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];
    const selectedIndex = 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ranges.asMap().entries.map((entry) {
        final isSelected = entry.key == selectedIndex;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.robinhoodGreen.withValues(alpha: 0.2)
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

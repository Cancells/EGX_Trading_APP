import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/market_data.dart';
import '../services/market_data_service.dart';
import '../services/preferences_service.dart';
import '../services/gold_service.dart';
import '../services/realtime_stock_service.dart';
import '../services/multi_market_service.dart';
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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final MarketDataService _marketService = MarketDataService();
  final PreferencesService _prefsService = PreferencesService();
  final GoldService _goldService = GoldService();
  final RealTimeStockService _realTimeService = RealTimeStockService();
  final MultiMarketService _multiMarketService = MultiMarketService();
  
  final ValueNotifier<double?> _selectedPrice = ValueNotifier(null);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  
  MarketData? _marketData;
  MarketType _selectedMarket = MarketType.egx;
  List<Stock> _currentStocks = [];
  bool _isLoadingMarket = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    // Initialize multi-market service
    _multiMarketService.init().then((_) {
      _multiMarketService.addListener(_onMultiMarketUpdate);
      _loadMarketData();
    });
    
    _marketService.startStreaming();
    _marketService.marketDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _marketData = data;
        });
        if (!_fadeController.isCompleted) {
          _fadeController.forward();
        }
        // Start tracking visible stocks for real-time updates if on EGX
        if (_selectedMarket == MarketType.egx) {
          _startRealTimeTracking(data);
        }
      }
    });

    // Initialize gold service
    _goldService.init();
    _goldService.addListener(_onGoldServiceUpdate);
  }

  void _onMultiMarketUpdate() {
    if (mounted) {
      setState(() {
        _isLoadingMarket = _multiMarketService.isLoading;
      });
    }
  }

  Future<void> _loadMarketData() async {
    setState(() => _isLoadingMarket = true);
    
    await _multiMarketService.fetchQuotes();
    
    if (mounted) {
      _updateCurrentStocks();
      setState(() => _isLoadingMarket = false);
    }
  }

  void _updateCurrentStocks() {
    final tickers = _multiMarketService.getTickers(_selectedMarket);
    final stocks = <Stock>[];
    
    for (final ticker in tickers) {
      final quote = _multiMarketService.getQuote(ticker.symbol);
      stocks.add(Stock(
        symbol: ticker.symbol,
        name: ticker.name,
        price: quote?.price ?? 0,
        change: quote?.change ?? 0,
        changePercent: quote?.changePercent ?? 0,
        priceHistory: quote?.priceHistory ?? [],
        lastUpdated: DateTime.now(),
        sector: ticker.sector,
        currencySymbol: _selectedMarket.currencySymbol,
        decimals: ticker.decimals,
        marketType: _selectedMarket.name,
      ));
    }
    
    setState(() {
      _currentStocks = stocks;
    });
    
    // Start real-time tracking for current stocks
    _startRealTimeTracking(null);
  }

  Future<void> _onMarketChanged(MarketType market) async {
    if (market == _selectedMarket) return;
    
    setState(() {
      _selectedMarket = market;
      _isLoadingMarket = true;
    });
    
    await _multiMarketService.switchMarket(market);
    _updateCurrentStocks();
    
    setState(() => _isLoadingMarket = false);
  }

  void _startRealTimeTracking(MarketData? data) {
    // Get all stock symbols to track
    List<String> symbols;
    if (_selectedMarket == MarketType.egx && data != null) {
      symbols = data.stocks.map((s) => s.symbol).toList();
    } else {
      symbols = _currentStocks.map((s) => s.symbol).toList();
    }
    _realTimeService.startTracking(symbols);
  }

  void _onGoldServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _marketService.stopStreaming();
    _goldService.removeListener(_onGoldServiceUpdate);
    _multiMarketService.removeListener(_onMultiMarketUpdate);
    _realTimeService.stopTrackingAll();
    _selectedPrice.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // RealTimeStockService handles this internally via WidgetsBindingObserver
    super.didChangeAppLifecycleState(state);
  }

  /// Build profile avatar - shows icon if no custom name/photo set
  Widget _buildProfileAvatar(double radius) {
    final hasCustomName = _prefsService.userName.isNotEmpty && 
                          _prefsService.userName != 'Investor';
    final hasCustomPhoto = _prefsService.customAvatarPath != null;
    
    if (hasCustomPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.robinhoodGreen,
        child: Text(
          _prefsService.userName[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (hasCustomName) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.robinhoodGreen,
        child: Text(
          _prefsService.userName[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      // Show icon for default user
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.robinhoodGreen.withValues(alpha: 0.2),
        child: Icon(
          Icons.person_rounded,
          color: AppTheme.robinhoodGreen,
          size: radius * 1.2,
        ),
      );
    }
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
                  child: _buildProfileAvatar(28),
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
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _showProfileMenu(context),
                child: Hero(
                  tag: 'profile_menu_avatar',
                  child: _buildProfileAvatar(20),
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
                  onChanged: _onMarketChanged,
                ),
                
                const SizedBox(height: 24),

                // US Market Ticker Strip
                if (_selectedMarket == MarketType.us) ...[
                  Text(
                    'Trending',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StockChipList(
                    // FIXED: Mapping List<Stock> to List<StockChipData>
                    stocks: _currentStocks.map((s) => StockChipData(
                      symbol: s.symbol,
                      name: s.name,
                      price: s.price,
                      changePercent: s.changePercent,
                    )).toList(),
                    onStockTap: (stockData) {
                      // Navigate to details
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Precious Metals Section
                if (_selectedMarket == MarketType.egx) ...[
                  _buildPreciousMetalsSection(context, isDark),
                  const SizedBox(height: 32),
                ],
                
                // Portfolio Value Header (High Performance)
                _buildPortfolioHeader(context, data),
                
                const SizedBox(height: 24),
                
                // Main Chart
                _buildMainChart(context, data),
                
                const SizedBox(height: 32),
                
                // Legacy Gold Section
                if (_selectedMarket == MarketType.us) ...[
                  _buildGoldSection(context),
                  const SizedBox(height: 32),
                ],
                
                // Stocks Section
                _buildStocksSection(context, data),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStocksSection(BuildContext context, MarketData data) {
    List<Stock> stocksToShow;
    String sectionTitle;
    
    switch (_selectedMarket) {
      case MarketType.egx:
        stocksToShow = data.stocks;
        sectionTitle = 'Egyptian Stocks';
        break;
      case MarketType.us:
        stocksToShow = _currentStocks;
        sectionTitle = 'US Stocks';
        break;
      case MarketType.crypto:
        stocksToShow = _currentStocks;
        sectionTitle = 'Cryptocurrencies';
        break;
    }
    
    final marketHours = _multiMarketService.getMarketHours(_selectedMarket);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _selectedMarket.icon,
                  size: 24,
                  color: AppTheme.robinhoodGreen,
                ),
                const SizedBox(width: 12),
                Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: marketHours.isOpen
                    ? AppTheme.robinhoodGreen.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: marketHours.isOpen
                          ? AppTheme.robinhoodGreen
                          : AppTheme.mutedText,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    marketHours.status,
                    style: TextStyle(
                      color: marketHours.isOpen
                          ? AppTheme.robinhoodGreen
                          : AppTheme.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingMarket)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (stocksToShow.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    _selectedMarket.icon,
                    size: 48,
                    color: AppTheme.mutedText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...stocksToShow.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StockCard(stock: entry.value)
                .animate(delay: Duration(milliseconds: 50 * entry.key))
                .fadeIn(duration: const Duration(milliseconds: 300))
                .slideX(begin: 0.1, end: 0, duration: const Duration(milliseconds: 300)),
          )),
      ],
    );
  }

  Widget _buildPreciousMetalsSection(BuildContext context, bool isDark) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _buildWorkmanshipToggle(context, isDark),
        const SizedBox(height: 16),
        
        ListenableBuilder(
          listenable: _goldService,
          builder: (context, _) {
            if (_goldService.isLoading && _goldService.prices.isEmpty) {
              return _buildGoldLoadingState();
            }
            
            if (_goldService.prices.isEmpty) {
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
                if (_goldService.goldPoundPrice != null)
                  _buildGoldPoundCard(context, isDark, formatter),
              ],
            );
          },
        ),
        
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
    
    // Performance: Uses ValueListenableBuilder to rebuild only this widget on scrub
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
        ListenableBuilder(
          listenable: _goldService,
          builder: (context, _) {
            if (_goldService.prices.isEmpty) {
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
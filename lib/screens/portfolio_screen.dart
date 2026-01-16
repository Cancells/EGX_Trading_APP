import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';
import 'add_investment_screen.dart';
import 'stock_detail_screen.dart'; // New file

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  // 0=Day, 1=Week, 2=Month, 3=YTD
  int _selectedTimeRange = 0; 

  @override
  Widget build(BuildContext context) {
    final investmentService = context.watch<InvestmentService>();
    final investments = investmentService.investments;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double totalValue = investments.fold(0, (sum, item) => sum + item.currentValue);
    
    // Mocking historical gain logic for the selector since we lack real history DB
    double displayGain = 0;
    double displayGainPercent = 0;
    
    // In a real app, calculate this based on _selectedTimeRange history
    double totalGainAllTime = investments.fold(0, (sum, item) => sum + item.totalGain);
    
    switch (_selectedTimeRange) {
      case 0: // Daily (simulated 1/30th of total for demo)
        displayGain = totalGainAllTime * 0.05; 
        break;
      case 1: // Weekly
        displayGain = totalGainAllTime * 0.15;
        break;
      case 2: // Monthly
        displayGain = totalGainAllTime * 0.4;
        break;
      case 3: // YTD
        displayGain = totalGainAllTime;
        break;
    }
    
    // Avoid division by zero
    double costBasis = totalValue - totalGainAllTime;
    displayGainPercent = costBasis == 0 ? 0 : (displayGain / costBasis) * 100;

    return Scaffold(
      extendBodyBehindAppBar: true,
      // 4. Settings Icon (Top Left) & 3. Profile Icon (Top Right)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () { /* Navigate to settings */ },
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
            onPressed: () { /* Navigate to profile */ },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // 5. Floating Action Button (Bottom Left)
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvestmentScreen())),
        label: const Text("Add Asset"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF0F172A), const Color(0xFF000000)] 
                    : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 2. Pinned Glass Widget for Gains (Always visible)
                SliverPersistentHeader(
                  delegate: _GlassHeaderDelegate(
                    totalValue: totalValue,
                    gain: displayGain,
                    gainPercent: displayGainPercent,
                    selectedIndex: _selectedTimeRange,
                    onRangeSelected: (i) => setState(() => _selectedTimeRange = i),
                  ),
                  pinned: true,
                ),

                // Holdings List
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final inv = investments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GlassStockCard(
                            investment: inv,
                            // 6. Navigate to Full Page Detail
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StockDetailScreen(investment: inv),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: investments.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pinned Glass Header Delegate
// -----------------------------------------------------------------------------
class _GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double totalValue;
  final double gain;
  final double gainPercent;
  final int selectedIndex;
  final ValueChanged<int> onRangeSelected;

  _GlassHeaderDelegate({
    required this.totalValue,
    required this.gain,
    required this.gainPercent,
    required this.selectedIndex,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isPositive = gain >= 0;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Total Balance", style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(symbol: 'EGP ').format(totalValue),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 12),
              // Range Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['1D', '1W', '1M', 'YTD'].asMap().entries.map((e) {
                    final isSelected = e.key == selectedIndex;
                    return GestureDetector(
                      onTap: () => onRangeSelected(e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                        ),
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.black : Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Gain Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${isPositive ? '+' : ''}${NumberFormat.currency(symbol: 'EGP ').format(gain)} (${gainPercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 220;
  @override
  double get minExtent => 220;
  @override
  bool shouldRebuild(covariant _GlassHeaderDelegate oldDelegate) => 
      oldDelegate.selectedIndex != selectedIndex || oldDelegate.totalValue != totalValue;
}

class _GlassStockCard extends StatelessWidget {
  final Investment investment;
  final VoidCallback onTap;

  const _GlassStockCard({required this.investment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = investment.totalGain >= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    investment.symbol.isNotEmpty ? investment.symbol[0] : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(investment.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${investment.quantity.toStringAsFixed(0)} shares', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(NumberFormat.compactCurrency(symbol: 'EGP ').format(investment.currentValue), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${isPositive ? '+' : ''}${investment.totalGainPercent.toStringAsFixed(2)}%',
                      style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
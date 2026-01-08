import 'package:flutter/material.dart';
import '../models/market_data.dart';
import '../theme/app_theme.dart';
import 'mini_chart.dart';

/// Stock Card Widget with mini chart
class StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;

  const StockCard({
    super.key,
    required this.stock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Hero(
      tag: 'stock_${stock.symbol}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                // Stock Symbol Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: stock.isPositive 
                        ? AppTheme.robinhoodGreen.withOpacity(0.1)
                        : AppTheme.robinhoodRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      stock.symbol.substring(0, 2),
                      style: TextStyle(
                        color: stock.isPositive 
                            ? AppTheme.robinhoodGreen 
                            : AppTheme.robinhoodRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Stock Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.symbol,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stock.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Mini Chart
                SizedBox(
                  width: 60,
                  height: 32,
                  child: MiniChart(
                    data: stock.priceHistory,
                    isPositive: stock.isPositive,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Price and Change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '${stock.price.toStringAsFixed(2)} EGP',
                        key: ValueKey(stock.price),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildChangeIndicator(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChangeIndicator(BuildContext context) {
    final color = stock.isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed;
    
    return Text(
      '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

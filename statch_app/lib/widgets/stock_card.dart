import 'package:flutter/material.dart';
import '../models/market_data.dart';
import '../theme/app_theme.dart';
import 'mini_chart.dart';
import 'stock_logo.dart';

/// Stock Card Widget with logo, mini chart, and optional NEW badge
class StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;
  final bool showNewBadge;

  const StockCard({
    super.key,
    required this.stock,
    this.onTap,
    this.showNewBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNew = showNewBadge && stock.isNew;
    
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
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                // Stock Logo with optional NEW badge
                StockLogoWithBadge(
                  symbol: stock.symbol,
                  name: stock.name,
                  size: 48,
                  isPositive: stock.isPositive,
                  isNew: isNew,
                ),
                const SizedBox(width: 12),
                
                // Stock Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              stock.symbol.replaceAll('.CA', ''),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (stock.sector != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stock.sector!,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.mutedText,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
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
    final icon = stock.isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Compact Stock Card for smaller lists
class StockCardCompact extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;
  final bool showNewBadge;

  const StockCardCompact({
    super.key,
    required this.stock,
    this.onTap,
    this.showNewBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNew = showNewBadge && stock.isNew;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Logo
            Stack(
              clipBehavior: Clip.none,
              children: [
                StockLogoCompact(
                  symbol: stock.symbol,
                  name: stock.name,
                  size: 40,
                  isPositive: stock.isPositive,
                ),
                if (isNew)
                  const Positioned(
                    top: -3,
                    right: -6,
                    child: NewBadge(fontSize: 7),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol.replaceAll('.CA', ''),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stock.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stock.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: stock.isPositive 
                        ? AppTheme.robinhoodGreen 
                        : AppTheme.robinhoodRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

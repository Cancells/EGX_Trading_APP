import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Market type enumeration
enum MarketType {
  egx30('EGX 30', 'Egyptian Index'),
  egx100('EGX 100', 'Extended Egyptian'),
  us('US', 'NYSE/NASDAQ');

  final String label;
  final String description;

  const MarketType(this.label, this.description);
}

/// Market Switcher Widget - Segmented Button Style
class MarketSwitcher extends StatelessWidget {
  final MarketType selected;
  final ValueChanged<MarketType> onChanged;

  const MarketSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: MarketType.values.map((market) {
          final isSelected = market == selected;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(market),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppTheme.robinhoodGreen.withValues(alpha: 0.2) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      market.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.robinhoodGreen
                            : AppTheme.mutedText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 2),
                      Text(
                        market.description,
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Market Switcher with TabBar style
class MarketTabBar extends StatelessWidget {
  final MarketType selected;
  final ValueChanged<MarketType> onChanged;

  const MarketTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MarketType.values.map((market) {
        final isSelected = market == selected;
        
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(market),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getMarketIcon(market),
                        size: 18,
                        color: isSelected
                            ? AppTheme.robinhoodGreen
                            : AppTheme.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        market.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.robinhoodGreen
                              : AppTheme.mutedText,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.robinhoodGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getMarketIcon(MarketType market) {
    switch (market) {
      case MarketType.egx30:
        return Icons.show_chart_rounded;
      case MarketType.egx100:
        return Icons.trending_up_rounded;
      case MarketType.us:
        return Icons.language_rounded;
    }
  }
}

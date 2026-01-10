import 'package:flutter/material.dart';
import '../services/multi_market_service.dart';
import '../theme/app_theme.dart';

// Re-export MarketType for backwards compatibility
export '../services/multi_market_service.dart' show MarketType, MarketTypeConfig;

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          market.icon,
                          size: 16,
                          color: isSelected
                              ? AppTheme.robinhoodGreen
                              : AppTheme.mutedText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          market.displayName,
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
                    if (isSelected) ...[
                      const SizedBox(height: 2),
                      Text(
                        market.fullName,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final multiMarketService = MultiMarketService();

    return Row(
      children: MarketType.values.map((market) {
        final isSelected = market == selected;
        final marketHours = multiMarketService.getMarketHours(market);
        
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(market),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            market.icon,
                            size: 18,
                            color: isSelected
                                ? AppTheme.robinhoodGreen
                                : AppTheme.mutedText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            market.displayName,
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
                      const SizedBox(height: 4),
                      // Market status indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          const SizedBox(width: 4),
                          Text(
                            marketHours.status,
                            style: TextStyle(
                              color: marketHours.isOpen
                                  ? AppTheme.robinhoodGreen
                                  : AppTheme.mutedText,
                              fontSize: 9,
                            ),
                          ),
                        ],
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
}

/// Compact market selector (for app bar)
class CompactMarketSelector extends StatelessWidget {
  final MarketType selected;
  final ValueChanged<MarketType> onChanged;

  const CompactMarketSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MarketType>(
      initialValue: selected,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.robinhoodGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected.icon,
              size: 16,
              color: AppTheme.robinhoodGreen,
            ),
            const SizedBox(width: 6),
            Text(
              selected.displayName,
              style: const TextStyle(
                color: AppTheme.robinhoodGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppTheme.robinhoodGreen,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => MarketType.values.map((market) {
        return PopupMenuItem<MarketType>(
          value: market,
          child: Row(
            children: [
              Icon(
                market.icon,
                size: 18,
                color: market == selected
                    ? AppTheme.robinhoodGreen
                    : AppTheme.mutedText,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    market.displayName,
                    style: TextStyle(
                      fontWeight: market == selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    market.fullName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

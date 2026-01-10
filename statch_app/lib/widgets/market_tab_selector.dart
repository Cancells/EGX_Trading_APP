import 'package:flutter/material.dart';
import '../services/multi_market_service.dart';
import '../theme/app_theme.dart';

/// Market tab selector for switching between EGX, US, and Crypto
class MarketTabSelector extends StatelessWidget {
  final MarketType selectedMarket;
  final ValueChanged<MarketType> onMarketChanged;
  final bool showIcons;

  const MarketTabSelector({
    super.key,
    required this.selectedMarket,
    required this.onMarketChanged,
    this.showIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: MarketType.values.map((market) {
          final isSelected = market == selectedMarket;
          return _MarketTab(
            market: market,
            isSelected: isSelected,
            showIcon: showIcons,
            onTap: () => onMarketChanged(market),
          );
        }).toList(),
      ),
    );
  }
}

class _MarketTab extends StatelessWidget {
  final MarketType market;
  final bool isSelected;
  final bool showIcon;
  final VoidCallback onTap;

  const _MarketTab({
    required this.market,
    required this.isSelected,
    required this.showIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.robinhoodGreen : AppTheme.robinhoodGreen)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.robinhoodGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                market.icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AppTheme.mutedText,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              market.displayName,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.mutedText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width market tab bar
class MarketTabBar extends StatelessWidget implements PreferredSizeWidget {
  final MarketType selectedMarket;
  final ValueChanged<MarketType> onMarketChanged;

  const MarketTabBar({
    super.key,
    required this.selectedMarket,
    required this.onMarketChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: MarketType.values.map((market) {
          final isSelected = market == selectedMarket;
          return Expanded(
            child: GestureDetector(
              onTap: () => onMarketChanged(market),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.robinhoodGreen.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: AppTheme.robinhoodGreen,
                          width: 1.5,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      market.icon,
                      size: 20,
                      color: isSelected
                          ? AppTheme.robinhoodGreen
                          : AppTheme.mutedText,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      market.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.robinhoodGreen
                            : AppTheme.mutedText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

/// Market status indicator (Open/Closed/24/7)
class MarketStatusIndicator extends StatelessWidget {
  final MarketType market;

  const MarketStatusIndicator({
    super.key,
    required this.market,
  });

  @override
  Widget build(BuildContext context) {
    final marketService = MultiMarketService();
    final hours = marketService.getMarketHours(market);

    Color statusColor;
    IconData statusIcon;

    if (market.is24Hours) {
      statusColor = AppTheme.robinhoodGreen;
      statusIcon = Icons.all_inclusive_rounded;
    } else if (hours.isOpen) {
      statusColor = AppTheme.robinhoodGreen;
      statusIcon = Icons.fiber_manual_record;
    } else {
      statusColor = AppTheme.mutedText;
      statusIcon = Icons.fiber_manual_record_outlined;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, size: 8, color: statusColor),
        const SizedBox(width: 4),
        Text(
          hours.status,
          style: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

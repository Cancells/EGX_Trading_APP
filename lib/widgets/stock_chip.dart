import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Stock Chip Widget with logo and price info
class StockChip extends StatelessWidget {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final String? logoUrl;
  final VoidCallback? onTap;
  final bool compact;

  const StockChip({
    super.key,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    this.logoUrl,
    this.onTap,
    this.compact = false,
  });

  bool get isPositive => changePercent >= 0;

  /// Get company logo URL from Clearbit
  String? get _logoUrl {
    if (logoUrl != null) return logoUrl;
    
    // Map common symbols to domains
    final domainMap = {
      'AAPL': 'apple.com',
      'GOOGL': 'google.com',
      'GOOG': 'google.com',
      'MSFT': 'microsoft.com',
      'AMZN': 'amazon.com',
      'TSLA': 'tesla.com',
      'META': 'meta.com',
      'NVDA': 'nvidia.com',
      'NFLX': 'netflix.com',
    };

    final domain = domainMap[symbol];
    if (domain != null) {
      return 'https://logo.clearbit.com/$domain';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return _buildCompactChip(context, isDark);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              // Logo
              _buildLogo(isDark, size: 44),
              const SizedBox(width: 12),
              
              // Symbol & Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Price & Change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                      const SizedBox(width: 2),
                      Text(
                        '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive
                              ? AppTheme.robinhoodGreen
                              : AppTheme.robinhoodRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark 
                ? AppTheme.darkCard 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(isDark, size: 28),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        price.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppTheme.robinhoodGreen.withValues(alpha: 0.15)
                              : AppTheme.robinhoodRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isPositive
                                ? AppTheme.robinhoodGreen
                                : AppTheme.robinhoodRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark, {required double size}) {
    final url = _logoUrl;
    
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size / 4),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => _buildInitialsLogo(isDark, size),
        errorWidget: (context, url, error) => _buildInitialsLogo(isDark, size),
      );
    }
    
    return _buildInitialsLogo(isDark, size);
  }

  Widget _buildInitialsLogo(bool isDark, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isPositive
            ? AppTheme.robinhoodGreen.withValues(alpha: 0.1)
            : AppTheme.robinhoodRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
          style: TextStyle(
            color: isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrollable list of stock chips
class StockChipList extends StatelessWidget {
  final List<StockChipData> stocks;
  final Function(StockChipData)? onStockTap;

  const StockChipList({
    super.key,
    required this.stocks,
    this.onStockTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stocks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final stock = stocks[index];
          return StockChip(
            symbol: stock.symbol,
            name: stock.name,
            price: stock.price,
            changePercent: stock.changePercent,
            logoUrl: stock.logoUrl,
            compact: true,
            onTap: () => onStockTap?.call(stock),
          );
        },
      ),
    );
  }
}

/// Data class for stock chip
class StockChipData {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final String? logoUrl;

  StockChipData({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    this.logoUrl,
  });
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/stock_logo_service.dart';
import '../theme/app_theme.dart';

/// Stock Logo Widget
/// Displays company logo using Clearbit API with fallback to initials
class StockLogo extends StatelessWidget {
  final String symbol;
  final String name;
  final double size;
  final bool isPositive;
  final bool showBorder;

  const StockLogo({
    super.key,
    required this.symbol,
    required this.name,
    this.size = 48,
    this.isPositive = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoService = StockLogoService();
    final logoUrl = logoService.getLogoUrl(symbol);

    // If we have a logo URL, try to load it
    if (logoUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(size * 0.25),
          border: showBorder
              ? Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25 - 1),
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholder: (context, url) => _buildFallback(isDark),
            errorWidget: (context, url, error) => _buildFallback(isDark),
          ),
        ),
      );
    }

    // No logo URL available, show fallback
    return _buildFallback(isDark);
  }

  Widget _buildFallback(bool isDark) {
    final color = StockLogoService.getColorForSymbol(symbol);
    final initials = StockLogoService.getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

/// Compact Stock Logo for list items
class StockLogoCompact extends StatelessWidget {
  final String symbol;
  final String name;
  final double size;
  final bool isPositive;

  const StockLogoCompact({
    super.key,
    required this.symbol,
    required this.name,
    this.size = 40,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoService = StockLogoService();
    final logoUrl = logoService.getLogoUrl(symbol);

    if (logoUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholder: (context, url) => _buildColoredFallback(),
            errorWidget: (context, url, error) => _buildColoredFallback(),
          ),
        ),
      );
    }

    return _buildColoredFallback();
  }

  Widget _buildColoredFallback() {
    // Use performance-based color for fallback
    final bgColor = isPositive
        ? AppTheme.robinhoodGreen.withValues(alpha: 0.1)
        : AppTheme.robinhoodRed.withValues(alpha: 0.1);
    final textColor = isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

/// NEW Badge for recently listed stocks
class NewBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsets padding;

  const NewBadge({
    super.key,
    this.fontSize = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1), // Indigo
            Color(0xFF8B5CF6), // Purple
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Stock Logo with optional NEW badge
class StockLogoWithBadge extends StatelessWidget {
  final String symbol;
  final String name;
  final double size;
  final bool isPositive;
  final bool isNew;

  const StockLogoWithBadge({
    super.key,
    required this.symbol,
    required this.name,
    this.size = 48,
    this.isPositive = true,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        StockLogo(
          symbol: symbol,
          name: name,
          size: size,
          isPositive: isPositive,
        ),
        if (isNew)
          Positioned(
            top: -4,
            right: -8,
            child: NewBadge(
              fontSize: size * 0.15,
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.1,
                vertical: size * 0.04,
              ),
            ),
          ),
      ],
    );
  }
}

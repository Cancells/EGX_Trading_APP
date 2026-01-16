import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../models/investment.dart';
import '../theme/app_theme.dart';
import 'mini_chart.dart';
import 'stock_logo.dart';

class ModernStockCard extends StatelessWidget {
  final Investment? investment;
  final VoidCallback? onTap;
  final bool isPrivacyMode;

  const ModernStockCard({
    super.key,
    this.investment,
    this.onTap,
    this.isPrivacyMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (investment == null) {
      return _buildShimmerLoading(context);
    }

    final inv = investment!;
    final isPositive = inv.totalGain >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1E1E1E).withOpacity(0.6) 
                    : Colors.white.withOpacity(0.7),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  StockLogo(symbol: inv.symbol, size: 48, name: inv.name),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPrivacyMode 
                              ? '${inv.quantity.toStringAsFixed(0)} shares'
                              : '${inv.quantity.toStringAsFixed(2)} shares',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 30,
                    // Ensure MiniChart accepts these params
                    child: MiniChart(
                      data: const [10, 15, 13, 20, 18, 25, 22], 
                      color: isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isPrivacyMode 
                            ? '****' 
                            : '\$${inv.currentValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPrivacyMode 
                              ? '***%'
                              : '${isPositive ? '+' : ''}${inv.totalGainPercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 60, height: 16, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 40, height: 12, color: Colors.white),
                  ],
                ),
              ),
              Container(width: 50, height: 30, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 80, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 50, height: 12, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
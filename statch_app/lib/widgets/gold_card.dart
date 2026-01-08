import 'package:flutter/material.dart';
import '../models/market_data.dart';
import '../theme/app_theme.dart';

/// High-fidelity Gold Price Card with gradient background
class GoldCard extends StatelessWidget {
  final GoldPrice goldPrice;
  final VoidCallback? onTap;

  const GoldCard({
    super.key,
    required this.goldPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Hero(
      tag: 'gold_${goldPrice.karat}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF2D2408),
                        const Color(0xFF1A1505),
                        const Color(0xFF0D0A02),
                      ]
                    : [
                        const Color(0xFFFFF8E1),
                        const Color(0xFFFFECB3),
                        const Color(0xFFFFE082),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.goldPrimary.withOpacity(isDark ? 0.3 : 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Gold Ingot Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                          Color(0xFFDAA520),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Gold Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gold ${goldPrice.karat}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDark ? AppTheme.goldPrimary : const Color(0xFF8B6914),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Per Gram',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: (isDark ? Colors.white : Colors.black87).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Price and Change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          '${goldPrice.pricePerGram.toStringAsFixed(2)} EGP',
                          key: ValueKey(goldPrice.pricePerGram),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
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
      ),
    );
  }

  Widget _buildChangeIndicator(BuildContext context) {
    final color = goldPrice.isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed;
    final icon = goldPrice.isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${goldPrice.changePercent >= 0 ? '+' : ''}${goldPrice.changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

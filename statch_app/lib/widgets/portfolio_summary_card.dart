import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class PortfolioSummaryCard extends StatefulWidget {
  final double balance;
  final double dayChange;
  final double dayChangePercent;

  const PortfolioSummaryCard({
    super.key,
    required this.balance,
    required this.dayChange,
    required this.dayChangePercent,
  });

  @override
  State<PortfolioSummaryCard> createState() => _PortfolioSummaryCardState();
}

class _PortfolioSummaryCardState extends State<PortfolioSummaryCard> {
  bool _isObscured = false;

  void _togglePrivacy() {
    HapticFeedback.selectionClick();
    setState(() => _isObscured = !_isObscured);
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.dayChange >= 0;
    final formatter = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.robinhoodGreen.withOpacity(0.15),
                  Theme.of(context).cardColor,
                ]
              : [
                  AppTheme.robinhoodGreen.withOpacity(0.05),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.robinhoodGreen.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Investing',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                onPressed: _togglePrivacy,
                icon: Icon(
                  _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: AppTheme.mutedText,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Balance with Blur Effect
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isObscured
                ? _buildBlurredBalance(context)
                : Text(
                    formatter.format(widget.balance),
                    key: const ValueKey('visible'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          fontSize: 28, // Adjusted for safe fit
                        ),
                  ),
          ),
          
          const SizedBox(height: 12),
          
          // Gain/Loss Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 16,
                  color: isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
                ),
                const SizedBox(width: 6),
                Text(
                  '${isPositive ? '+' : ''}${formatter.format(widget.dayChange)} (${widget.dayChangePercent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredBalance(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Text(
        'EGP 8,888,888.88', // Dummy text to maintain layout size
        key: const ValueKey('hidden'),
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              fontSize: 28,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
            ),
      ),
    );
  }
}
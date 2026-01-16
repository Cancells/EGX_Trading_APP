import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/currency_service.dart';
import '../models/investment.dart';

class PortfolioSummaryCard extends StatelessWidget {
  final PortfolioSummary summary;

  const PortfolioSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final currencyService = Provider.of<CurrencyService>(context);
    
    final isPrivacyOn = prefs.isPrivacyModeEnabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Currency Formatting Helpers
    final currencySymbol = currencyService.baseCurrency.symbol;
    final rate = currencyService.baseCurrency == Currency.usd 
        ? 1.0 / currencyService.usdToEgp 
        : 1.0; // Assuming summary is in EGP, convert if base is different (simplified logic)
        
    // Simplified: Assume summary values are already normalized or we just display raw for now
    // Ideally, PortfolioSummary should handle currency conversion, but for display:
    
    String formatMoney(double value) {
      if (isPrivacyOn) return '****';
      return '$currencySymbol${(value * rate).toStringAsFixed(2)}';
    }

    String formatPercent(double value) {
      if (isPrivacyOn) return '***';
      return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        primaryColor.withOpacity(0.15),
                        primaryColor.withOpacity(0.05),
                      ]
                    : [
                        primaryColor.withOpacity(0.1),
                        Colors.white.withOpacity(0.4),
                      ],
              ),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isPrivacyOn ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          prefs.togglePrivacyMode();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatMoney(summary.totalValue),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildSummaryChip(
                        context,
                        label: 'Total Gain',
                        value: formatMoney(summary.totalGain),
                        percent: formatPercent(summary.totalGainPercent),
                        isPositive: summary.totalGain >= 0,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryChip(
                        context,
                        label: 'Day Gain',
                        value: formatMoney(summary.dayGain),
                        percent: formatPercent(summary.dayGainPercent),
                        isPositive: summary.dayGain >= 0,
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

  Widget _buildSummaryChip(
    BuildContext context, {
    required String label,
    required String value,
    required String percent,
    required bool isPositive,
  }) {
    final color = isPositive ? const Color(0xFF00C805) : const Color(0xFFFF5000);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              percent,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
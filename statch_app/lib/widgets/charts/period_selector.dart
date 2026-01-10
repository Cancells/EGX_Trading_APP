import 'package:flutter/material.dart';
import '../../services/sparkline_service.dart';
import '../../theme/app_theme.dart';

/// Period selector for chart timeframes
class PeriodSelector extends StatelessWidget {
  final SparklinePeriod selectedPeriod;
  final ValueChanged<SparklinePeriod> onPeriodChanged;
  final bool isLoading;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SparklinePeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return _PeriodButton(
            period: period,
            isSelected: isSelected,
            isLoading: isLoading && isSelected,
            onTap: () => onPeriodChanged(period),
          );
        }).toList(),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final SparklinePeriod period;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.period,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.robinhoodGreen
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                period.displayName,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white
                      : AppTheme.mutedText,
                  fontWeight: isSelected 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

/// Compact period selector for smaller spaces
class CompactPeriodSelector extends StatelessWidget {
  final SparklinePeriod selectedPeriod;
  final ValueChanged<SparklinePeriod> onPeriodChanged;

  const CompactPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: SparklinePeriod.values.map((period) {
        final isSelected = period == selectedPeriod;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onPeriodChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.robinhoodGreen.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: AppTheme.robinhoodGreen, width: 1)
                    : null,
              ),
              child: Text(
                period.displayName,
                style: TextStyle(
                  color: isSelected 
                      ? AppTheme.robinhoodGreen
                      : AppTheme.mutedText,
                  fontWeight: isSelected 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

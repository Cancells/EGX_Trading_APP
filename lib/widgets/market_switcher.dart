import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class MarketSwitcher extends StatefulWidget {
  final int selectedIndex;
  final Function(int)? onTabChanged;

  const MarketSwitcher({
    super.key, 
    this.selectedIndex = 0, 
    this.onTabChanged,
  });

  @override
  State<MarketSwitcher> createState() => _MarketSwitcherState();
}

class _MarketSwitcherState extends State<MarketSwitcher> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('Stocks', 0),
          _buildTab('Gold', 1),
          _buildTab('Crypto', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
            widget.onTabChanged?.call(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? const Color(0xFF333333) : Colors.white) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected 
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class GoldCalculatorSheet extends StatefulWidget {
  final double price24k;
  final double price21k;
  final double price18k;

  const GoldCalculatorSheet({
    super.key,
    required this.price24k,
    required this.price21k,
    required this.price18k,
  });

  @override
  State<GoldCalculatorSheet> createState() => _GoldCalculatorSheetState();
}

class _GoldCalculatorSheetState extends State<GoldCalculatorSheet> {
  final TextEditingController _gramsController = TextEditingController(text: '10');
  int _selectedKarat = 21;
  bool _includeWorkmanship = true;
  double _workmanshipFee = 60.0; // EGP per gram default

  double get _currentPricePerGram {
    switch (_selectedKarat) {
      case 24: return widget.price24k;
      case 21: return widget.price21k;
      case 18: return widget.price18k;
      default: return 0;
    }
  }

  double get _totalPrice {
    final grams = double.tryParse(_gramsController.text) ?? 0;
    final base = grams * _currentPricePerGram;
    final fees = _includeWorkmanship ? (grams * _workmanshipFee) : 0;
    return base + fees;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Gold Calculator',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          
          // Weight Input
          Text('Weight (Grams)', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _gramsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixText: 'g',
            ),
            onChanged: (_) => setState(() {}),
          ),
          
          const SizedBox(height: 24),
          
          // Karat Selector
          Row(
            children: [24, 21, 18].map((karat) {
              final isSelected = _selectedKarat == karat;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedKarat = karat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.goldPrimary 
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? null : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          '${karat}K',
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppTheme.mutedText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Workmanship Toggle
          SwitchListTile(
            title: const Text('Add Workmanship (Mosna3eya)'),
            subtitle: Text('Est. ${_workmanshipFee.toStringAsFixed(0)} EGP/g'),
            value: _includeWorkmanship,
            activeColor: AppTheme.goldPrimary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _includeWorkmanship = val),
          ),
          
          const Divider(height: 32),
          
          // Total Result
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Price',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                formatter.format(_totalPrice),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.goldPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 32), // Bottom padding
        ],
      ),
    );
  }
}
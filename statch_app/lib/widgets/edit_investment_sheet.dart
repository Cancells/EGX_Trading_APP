import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';
import '../theme/app_theme.dart';

/// Edit Investment Bottom Sheet with manual override capability
class EditInvestmentSheet extends StatefulWidget {
  final Investment investment;
  final double currentPrice;
  final Function(Investment) onSave;

  const EditInvestmentSheet({
    super.key,
    required this.investment,
    required this.currentPrice,
    required this.onSave,
  });

  @override
  State<EditInvestmentSheet> createState() => _EditInvestmentSheetState();
}

class _EditInvestmentSheetState extends State<EditInvestmentSheet> {
  final InvestmentService _investmentService = InvestmentService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _totalController;
  
  bool _isEditingTotal = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.investment.quantity.toStringAsFixed(2),
    );
    _priceController = TextEditingController(
      text: widget.investment.purchasePrice.toStringAsFixed(2),
    );
    _totalController = TextEditingController(
      text: widget.investment.totalInvested.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _onQuantityChanged(String value) {
    if (_isEditingTotal) return;
    
    final quantity = double.tryParse(value) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final total = quantity * price;
    
    _totalController.text = total.toStringAsFixed(2);
  }

  void _onPriceChanged(String value) {
    if (_isEditingTotal) return;
    
    final price = double.tryParse(value) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final total = quantity * price;
    
    _totalController.text = total.toStringAsFixed(2);
  }

  void _onTotalChanged(String value) {
    _isEditingTotal = true;
    
    final total = double.tryParse(value) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    
    if (price > 0) {
      // Auto-calculate units: Units = Total / Price
      final quantity = total / price;
      _quantityController.text = quantity.toStringAsFixed(4);
    }
    
    _isEditingTotal = false;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final purchasePrice = double.parse(_priceController.text);

      final updated = widget.investment.copyWith(
        quantity: quantity,
        purchasePrice: purchasePrice,
        currentPrice: widget.currentPrice,
      );

      await _investmentService.updateInvestment(updated);
      widget.onSave(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.robinhoodRed,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteInvestment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: Text(
          'Are you sure you want to delete ${widget.investment.symbol}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.robinhoodRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _investmentService.removeInvestment(widget.investment.id);
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Calculate current P/L
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final purchasePrice = double.tryParse(_priceController.text) ?? 0;
    final currentValue = widget.currentPrice * quantity;
    final totalInvested = purchasePrice * quantity;
    final profitLoss = currentValue - totalInvested;
    final isProfit = profitLoss >= 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Investment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.investment.symbol} • ${widget.investment.name}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _deleteInvestment,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppTheme.robinhoodRed,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Live P/L Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isProfit
                      ? AppTheme.robinhoodGreen.withValues(alpha: 0.1)
                      : AppTheme.robinhoodRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isProfit
                        ? AppTheme.robinhoodGreen.withValues(alpha: 0.2)
                        : AppTheme.robinhoodRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live P/L',
                          style: TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${isProfit ? '+' : ''}${formatter.format(profitLoss)} EGP',
                          style: TextStyle(
                            color: isProfit
                                ? AppTheme.robinhoodGreen
                                : AppTheme.robinhoodRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Current Price',
                          style: TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${formatter.format(widget.currentPrice)} EGP',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quantity Field
              Text(
                'Quantity (Shares)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.numbers_rounded),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onQuantityChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Purchase Price Field
              Text(
                'Average Purchase Price (EGP)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onPriceChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Total Investment Field (with auto-calculate)
              Row(
                children: [
                  Text(
                    'Total Investment (EGP)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.robinhoodGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Auto-calculates units',
                      style: TextStyle(
                        color: AppTheme.robinhoodGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _totalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onTotalChanged,
              ),

              const SizedBox(height: 8),
              Text(
                'Purchase Date: ${dateFormat.format(widget.investment.purchaseDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.robinhoodGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

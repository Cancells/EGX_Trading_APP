import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/investment_service.dart';
import '../theme/app_theme.dart';

/// Screen for adding a new investment
class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _investmentService = InvestmentService();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _selectedSymbol;
  String? _selectedName;
  bool _showSymbolSuggestions = false;

  // Available symbols for Egyptian market
  final Map<String, String> _availableSymbols = {
    'COMI.CA': 'Commercial International Bank',
    'TMGH.CA': 'Talaat Mostafa Group Holding',
    'ETEL.CA': 'Telecom Egypt',
    'FWRY.CA': 'Fawry for Banking Technology',
    'HRHO.CA': 'Hermes Holding',
    'EAST.CA': 'Eastern Company',
    'SWDY.CA': 'Elsewedy Electric',
    'PHDC.CA': 'Palm Hills Development',
    'MNHD.CA': 'Madinet Nasr Housing',
    'EKHO.CA': 'Edita Food Industries',
    // Gold options
    'GC=F': 'Gold Futures (USD)',
    'XAUUSD=X': 'Gold Spot (USD)',
  };

  List<MapEntry<String, String>> get _filteredSymbols {
    final query = _symbolController.text.toLowerCase();
    if (query.isEmpty) return _availableSymbols.entries.toList();
    
    return _availableSymbols.entries.where((entry) {
      return entry.key.toLowerCase().contains(query) ||
             entry.value.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.robinhoodGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectSymbol(String symbol, String name) {
    setState(() {
      _selectedSymbol = symbol;
      _selectedName = name;
      _symbolController.text = symbol;
      _showSymbolSuggestions = false;
    });
  }

  Future<void> _addInvestment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSymbol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid symbol')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text);
      
      final investment = await _investmentService.addInvestment(
        symbol: _selectedSymbol!,
        name: _selectedName ?? _selectedSymbol!,
        quantity: quantity,
        purchaseDate: _selectedDate,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (investment != null) {
          Navigator.pop(context, investment);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch price data. Please try again.'),
              backgroundColor: AppTheme.robinhoodRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.robinhoodRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Investment'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _showSymbolSuggestions = false);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.robinhoodGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.robinhoodGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.robinhoodGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Track your Egyptian stocks and gold investments with real-time profit/loss calculations.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.robinhoodGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Symbol Field
                Text(
                  'Ticker Symbol',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    TextFormField(
                      controller: _symbolController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Search symbol (e.g., COMI.CA)',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _selectedSymbol != null
                            ? const Icon(Icons.check_circle_rounded, 
                                   color: AppTheme.robinhoodGreen)
                            : null,
                        filled: true,
                        fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.robinhoodGreen,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _showSymbolSuggestions = value.isNotEmpty;
                          _selectedSymbol = null;
                          _selectedName = null;
                        });
                      },
                      validator: (value) {
                        if (_selectedSymbol == null) {
                          return 'Please select a valid symbol';
                        }
                        return null;
                      },
                    ),
                    if (_showSymbolSuggestions && _filteredSymbols.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredSymbols.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredSymbols[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              onTap: () => _selectSymbol(entry.key, entry.value),
                            );
                          },
                        ),
                      ),
                  ],
                ),

                if (_selectedName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _selectedName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Quantity Field
                Text(
                  'Quantity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    hintText: 'Number of shares',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.robinhoodGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final qty = double.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Date Field
                Text(
                  'Purchase Date',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            DateFormat('MMMM dd, yyyy').format(_selectedDate),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'The historical price for this date will be fetched automatically.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),

                const SizedBox(height: 48),

                // Add Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addInvestment,
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded),
                              SizedBox(width: 8),
                              Text(
                                'Add Investment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

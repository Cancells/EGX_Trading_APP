import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/market_data.dart';
import '../services/investment_service.dart';
import '../services/gold_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_logo.dart';

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
  final _priceController = TextEditingController();
  final _investmentService = InvestmentService();
  final _goldService = GoldService();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _selectedSymbol;
  String? _selectedName;
  String? _selectedSector;
  bool _showSymbolSuggestions = false;
  bool _isGoldInvestment = false;
  bool _useManualPrice = false;

  // Get all available symbols from EgyptianStocks
  Map<String, Map<String, String>> get _availableSymbols {
    final result = <String, Map<String, String>>{};
    for (final stock in EgyptianStocks.all) {
      result[stock.symbol] = {
        'name': stock.name,
        'sector': stock.sector,
      };
    }
    return result;
  }

  List<MapEntry<String, Map<String, String>>> get _filteredSymbols {
    final query = _symbolController.text.toLowerCase();
    if (query.isEmpty) return _availableSymbols.entries.toList();
    
    return _availableSymbols.entries.where((entry) {
      return entry.key.toLowerCase().contains(query) ||
             entry.value['name']!.toLowerCase().contains(query) ||
             entry.value['sector']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
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
              primary: _isGoldInvestment ? AppTheme.goldPrimary : AppTheme.robinhoodGreen,
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

  void _selectSymbol(String symbol, String name, String sector) {
    setState(() {
      _selectedSymbol = symbol;
      _selectedName = name;
      _selectedSector = sector;
      _symbolController.text = symbol;
      _showSymbolSuggestions = false;
      _isGoldInvestment = GoldService.isGoldSymbol(symbol);
      
      // For gold investments, pre-fill current price
      if (_isGoldInvestment) {
        final goldPrice = _goldService.getPriceBySymbol(symbol);
        if (goldPrice != null) {
          _priceController.text = goldPrice.toStringAsFixed(2);
        }
      }
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
      
      if (_isGoldInvestment) {
        // For gold investments, use the entered price
        final purchasePrice = double.parse(_priceController.text);
        final currentPrice = _goldService.getPriceBySymbol(_selectedSymbol!) ?? purchasePrice;
        
        final investment = await _investmentService.addGoldInvestment(
          symbol: _selectedSymbol!,
          name: _selectedName ?? _selectedSymbol!,
          quantity: quantity,
          purchaseDate: _selectedDate,
          purchasePrice: purchasePrice,
          currentPrice: currentPrice,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          
          if (investment != null) {
            Navigator.pop(context, investment);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not add gold investment. Please try again.'),
                backgroundColor: AppTheme.robinhoodRed,
              ),
            );
          }
        }
      } else if (_useManualPrice) {
        // Use manually entered price
        final purchasePrice = double.parse(_priceController.text);
        
        final investment = await _investmentService.addInvestmentWithPrice(
          symbol: _selectedSymbol!,
          name: _selectedName ?? _selectedSymbol!,
          quantity: quantity,
          purchaseDate: _selectedDate,
          purchasePrice: purchasePrice,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          
          if (investment != null) {
            Navigator.pop(context, investment);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not add investment. Please try again.'),
                backgroundColor: AppTheme.robinhoodRed,
              ),
            );
          }
        }
      } else {
        // Standard investment - fetch historical price
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
            // Offer manual price entry as fallback
            _showManualPriceDialog();
          }
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

  void _showManualPriceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Price Not Found'),
        content: const Text(
          'Could not fetch historical price for this date. '
          'Would you like to enter the purchase price manually?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _useManualPrice = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.robinhoodGreen,
            ),
            child: const Text('Enter Manually'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _isGoldInvestment ? AppTheme.goldPrimary : AppTheme.robinhoodGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGoldInvestment ? 'Add Gold Investment' : 'Add Investment'),
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
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isGoldInvestment 
                            ? Icons.workspace_premium_rounded 
                            : Icons.info_outline_rounded,
                        color: accentColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isGoldInvestment
                              ? 'Track your physical gold holdings with real-time Egyptian gold prices.'
                              : 'Track your Egyptian stocks and gold investments with real-time profit/loss calculations.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: accentColor,
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
                        hintText: 'Search symbol (e.g., COMI.CA or GOLD_24K)',
                        prefixIcon: Icon(
                          _isGoldInvestment 
                              ? Icons.workspace_premium_rounded 
                              : Icons.search_rounded,
                          color: _isGoldInvestment ? AppTheme.goldPrimary : null,
                        ),
                        suffixIcon: _selectedSymbol != null
                            ? Icon(Icons.check_circle_rounded, 
                                   color: accentColor)
                            : null,
                        filled: true,
                        fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: accentColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _showSymbolSuggestions = value.isNotEmpty;
                          _selectedSymbol = null;
                          _selectedName = null;
                          _selectedSector = null;
                          _isGoldInvestment = false;
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
                        constraints: const BoxConstraints(maxHeight: 250),
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
                            final isGold = GoldService.isGoldSymbol(entry.key);
                            final stockInfo = EgyptianStocks.all.firstWhere(
                              (s) => s.symbol == entry.key,
                              orElse: () => EgyptianStock(
                                symbol: entry.key,
                                name: entry.value['name']!,
                                sector: entry.value['sector']!,
                              ),
                            );
                            final isNew = stockInfo.isNew;
                            
                            return ListTile(
                              dense: true,
                              leading: isGold
                                  ? Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        StockLogoCompact(
                                          symbol: entry.key,
                                          name: entry.value['name']!,
                                          size: 36,
                                          isPositive: true,
                                        ),
                                        if (isNew)
                                          const Positioned(
                                            top: -3,
                                            right: -6,
                                            child: NewBadge(fontSize: 7),
                                          ),
                                      ],
                                    ),
                              title: Row(
                                children: [
                                  Text(
                                    entry.key.replaceAll('.CA', ''),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isGold ? AppTheme.goldPrimary : null,
                                    ),
                                  ),
                                  if (isNew && isGold) ...[
                                    const SizedBox(width: 6),
                                    const NewBadge(fontSize: 8),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value['name']!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    entry.value['sector']!,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isGold 
                                          ? AppTheme.goldPrimary.withValues(alpha: 0.7)
                                          : AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _selectSymbol(
                                entry.key, 
                                entry.value['name']!, 
                                entry.value['sector']!,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),

                if (_selectedName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_isGoldInvestment)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'GOLD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _selectedName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _isGoldInvestment ? AppTheme.goldPrimary : AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedSector != null)
                    Text(
                      _selectedSector!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                // Quantity Field
                Text(
                  _isGoldInvestment ? 'Weight (Grams)' : 'Quantity',
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
                    hintText: _isGoldInvestment ? 'Number of grams' : 'Number of shares',
                    prefixIcon: Icon(
                      _isGoldInvestment ? Icons.scale_rounded : Icons.numbers_rounded,
                    ),
                    suffixText: _isGoldInvestment ? 'g' : null,
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isGoldInvestment ? 'Please enter weight in grams' : 'Please enter quantity';
                    }
                    final qty = double.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),

                // Price Field (for gold or manual entry)
                if (_isGoldInvestment || _useManualPrice) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Purchase Price (per ${_isGoldInvestment ? 'gram' : 'share'})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      hintText: 'Price in EGP',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      suffixText: 'EGP',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: accentColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter purchase price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ],

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
                  _isGoldInvestment
                      ? 'Enter the price you paid per gram at the time of purchase.'
                      : _useManualPrice
                          ? 'Enter the price you paid per share manually.'
                          : 'The historical price for this date will be fetched automatically.',
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
                      backgroundColor: accentColor,
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isGoldInvestment 
                                  ? Icons.workspace_premium_rounded 
                                  : Icons.add_rounded),
                              const SizedBox(width: 8),
                              Text(
                                _isGoldInvestment 
                                    ? 'Add Gold Investment' 
                                    : 'Add Investment',
                                style: const TextStyle(
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

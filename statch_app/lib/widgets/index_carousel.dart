import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Inside lib/widgets/index_carousel.dart

// ... imports

class IndexCarousel extends StatelessWidget {
  final double egxValue;
  final double egxChange;
  final double goldValue;
  final double goldChange;
  final double? silverValue; // Add optional silver
  final double? silverChange;

  const IndexCarousel({
    super.key,
    required this.egxValue,
    required this.egxChange,
    required this.goldValue,
    required this.goldChange,
    this.silverValue,
    this.silverChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildCard(context, 'EGX 30', egxValue, egxChange, isCurrency: false),
          const SizedBox(width: 12),
          // Show 21K as it's the standard in Egypt
          _buildCard(context, 'Gold 21K', goldValue, goldChange, isCurrency: true),
          const SizedBox(width: 12),
          // Show Real Silver if available
          if (silverValue != null) ...[
             _buildCard(context, 'Silver 999', silverValue!, silverChange ?? 0, isCurrency: true),
             const SizedBox(width: 12),
          ],
          _buildCard(context, 'USD/EGP', 50.60, 0.00, isCurrency: true, isStable: true), 
        ],
      ),
    );
  }
  
  // ... existing _buildCard implementation ...
}

class IndexCarousel extends StatelessWidget {
  final double egxValue;
  final double egxChange;
  final double goldValue;
  final double goldChange;

  const IndexCarousel({
    super.key,
    required this.egxValue,
    required this.egxChange,
    required this.goldValue,
    required this.goldChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildCard(context, 'EGX 30', egxValue, egxChange, isCurrency: false),
          const SizedBox(width: 12),
          _buildCard(context, 'Gold 21K', goldValue, goldChange, isCurrency: true),
          const SizedBox(width: 12),
          _buildCard(context, 'USD/EGP', 50.60, 0.05, isCurrency: true, isStable: true), // Mock USD
          const SizedBox(width: 12),
          _buildCard(context, 'Silver', 45.0, -1.2, isCurrency: true),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, double value, double changePct, {bool isCurrency = false, bool isStable = false}) {
    final isPositive = changePct >= 0;
    final color = isStable ? Colors.grey : (isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed);
    final bg = Theme.of(context).cardColor;
    
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(isCurrency ? 0 : 0)}${isCurrency ? '' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isStable ? Icons.remove : (isPositive ? Icons.arrow_upward : Icons.arrow_downward),
                size: 12, 
                color: color
              ),
              const SizedBox(width: 4),
              Text(
                '${changePct.abs().toStringAsFixed(2)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }
}
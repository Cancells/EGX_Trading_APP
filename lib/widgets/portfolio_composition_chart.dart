import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/investment.dart';

class PortfolioCompositionChart extends StatefulWidget {
  final List<Investment> investments;
  final double totalValue;

  const PortfolioCompositionChart({
    super.key,
    required this.investments,
    required this.totalValue,
  });

  @override
  State<PortfolioCompositionChart> createState() => _PortfolioCompositionChartState();
}

class _PortfolioCompositionChartState extends State<PortfolioCompositionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.investments.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _showingSections(),
              ),
            ),
          ),
        ),
        // Legend
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.investments.take(5).map((inv) {
            final color = _getColorForIndex(widget.investments.indexOf(inv));
            // Fixed: Use inv.quantity instead of inv.shares
            // Fixed: Use inv.purchasePrice instead of inv.averagePrice
            // Better yet, use the getter .currentValue for accurate percentage
            final percent = (inv.currentValue / widget.totalValue * 100);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    inv.symbol,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(widget.investments.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 18.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final inv = widget.investments[i];
      
      // Fixed: Use currentValue getter
      final value = inv.currentValue;

      return PieChartSectionData(
        color: _getColorForIndex(i),
        value: value,
        title: isTouched ? inv.symbol : '', // Only show title when touched to avoid clutter
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Color _getColorForIndex(int index) {
    // Generate distinct colors
    const colors = [
      Color(0xFF00C805), // Robinhood Green
      Color(0xFF2196F3), // Blue
      Color(0xFFFFC107), // Amber
      Color(0xFF9C27B0), // Purple
      Color(0xFFFF5722), // Deep Orange
      Color(0xFF00BCD4), // Cyan
    ];
    return colors[index % colors.length];
  }
}
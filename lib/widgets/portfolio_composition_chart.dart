import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../theme/app_theme.dart';

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
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.investments.isEmpty) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
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
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2, // Gap between sections
                  centerSpaceRadius: 40,
                  sections: _generateSections(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.investments.take(5).map((inv) {
                final index = widget.investments.indexOf(inv);
                final value = inv.shares * inv.averagePrice; // Use current price in real app
                final percent = (value / widget.totalValue) * 100;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getColor(index),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          inv.symbol,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _touchedIndex == index ? null : AppTheme.mutedText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    return List.generate(widget.investments.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 0.0; // Hide text when not touched
      final radius = isTouched ? 60.0 : 50.0;
      final investment = widget.investments[i];
      final value = investment.shares * investment.averagePrice;

      return PieChartSectionData(
        color: _getColor(i),
        value: value,
        title: '${(value / widget.totalValue * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Color _getColor(int index) {
    const colors = [
      AppTheme.robinhoodGreen,
      Color(0xFF2196F3), // Blue
      Color(0xFFFFC107), // Amber (Gold)
      Color(0xFF9C27B0), // Purple
      Color(0xFFFF5722), // Orange
      Colors.grey,
    ];
    return colors[index % colors.length];
  }
}
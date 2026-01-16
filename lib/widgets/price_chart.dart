import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/market_data.dart';
import '../theme/app_theme.dart';

class PriceChart extends StatelessWidget {
  final List<ChartPoint> data;
  final double previousClose;
  final bool isPositive;

  const PriceChart({
    super.key,
    required this.data,
    required this.previousClose,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final spots = data.map((p) {
      return FlSpot(p.time.millisecondsSinceEpoch.toDouble(), p.price);
    }).toList();

    double minY = data.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    double maxY = data.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    
    // Add 10% padding
    final range = maxY - minY;
    if (range == 0) {
      minY = minY * 0.99;
      maxY = maxY * 1.01;
    } else {
      minY -= range * 0.1;
      maxY += range * 0.1;
    }

    final color = isPositive ? AppTheme.chartGreen : AppTheme.chartRed;
    final tooltipColor = Theme.of(context).cardColor;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // Fix: Use getTooltipColor instead of tooltipBgColor
            getTooltipColor: (touchedSpot) => tooltipColor,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                return LineTooltipItem(
                  '${DateFormat('HH:mm').format(date)}\n',
                  TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  children: [
                    TextSpan(
                      text: spot.y.toStringAsFixed(2),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          // Previous close line (Dashed)
          LineChartBarData(
            spots: [
              FlSpot(spots.first.x, previousClose),
              FlSpot(spots.last.x, previousClose),
            ],
            color: Colors.grey.withOpacity(0.5),
            barWidth: 1,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
          // Price line
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
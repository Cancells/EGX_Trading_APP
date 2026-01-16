import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/sparkline_service.dart';
import '../../theme/app_theme.dart';

/// Minimalist sparkline chart widget using fl_chart
class SparklineWidget extends StatelessWidget {
  final List<double> data;
  final bool? isPositive;
  final double lineWidth;
  final bool showGradient;
  final double? height;
  final double? width;

  const SparklineWidget({
    super.key,
    required this.data,
    this.isPositive,
    this.lineWidth = 2.0,
    this.showGradient = true,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty or invalid data
    if (data.isEmpty || data.length < 2) {
      return _buildFlatLine();
    }

    // Determine color based on price movement
    final positive = isPositive ?? (data.last >= data.first);
    final lineColor = positive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed;

    // Create spots for the line chart
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    // Calculate min/max for proper scaling
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    
    // Add padding to prevent line from touching edges
    final padding = range == 0 ? 1.0 : range * 0.1;

    return SizedBox(
      height: height,
      width: width,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          clipData: const FlClipData.all(),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: lineWidth,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: showGradient
                  ? BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.3),
                          lineColor.withValues(alpha: 0.0),
                        ],
                      ),
                    )
                  : BarAreaData(show: false),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Build a flat grey line for error/empty state
  Widget _buildFlatLine() {
    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: _FlatLinePainter(),
        size: Size.infinite,
      ),
    );
  }
}

/// Painter for flat grey line (error state)
class _FlatLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.mutedText.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sparkline widget that fetches its own data
class AsyncSparklineWidget extends StatefulWidget {
  final String symbol;
  final SparklinePeriod period;
  final double? height;
  final double? width;
  final double lineWidth;
  final bool showGradient;

  const AsyncSparklineWidget({
    super.key,
    required this.symbol,
    this.period = SparklinePeriod.day,
    this.height,
    this.width,
    this.lineWidth = 2.0,
    this.showGradient = true,
  });

  @override
  State<AsyncSparklineWidget> createState() => _AsyncSparklineWidgetState();
}

class _AsyncSparklineWidgetState extends State<AsyncSparklineWidget> {
  final SparklineService _sparklineService = SparklineService();
  SparklineData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(AsyncSparklineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol || oldWidget.period != widget.period) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    final data = await _sparklineService.fetchSparklineData(
      widget.symbol,
      widget.period,
    );

    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    }

    return SparklineWidget(
      data: _data?.prices ?? [],
      isPositive: _data?.isPositive,
      height: widget.height,
      width: widget.width,
      lineWidth: widget.lineWidth,
      showGradient: widget.showGradient,
    );
  }
}

/// Mini sparkline for stock cards (compact version)
class MiniSparkline extends StatelessWidget {
  final List<double> data;
  final bool isPositive;

  const MiniSparkline({
    super.key,
    required this.data,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return SparklineWidget(
      data: data,
      isPositive: isPositive,
      lineWidth: 1.5,
      showGradient: false,
      height: 32,
      width: 60,
    );
  }
}

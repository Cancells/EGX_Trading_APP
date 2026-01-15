import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for HapticFeedback
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class PriceChart extends StatefulWidget {
  final List<double> priceHistory;
  final bool isPositive;
  final ValueNotifier<double?>? selectedPriceNotifier;
  final ValueNotifier<int?>? selectedIndexNotifier;
  final double height;

  const PriceChart({
    super.key,
    required this.priceHistory,
    required this.isPositive,
    this.selectedPriceNotifier,
    this.selectedIndexNotifier,
    this.height = 200,
  });

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;
  double? _touchedX;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.priceHistory != widget.priceHistory) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  Color get _chartColor => widget.isPositive ? AppTheme.chartGreen : AppTheme.chartRed;

  List<FlSpot> get _spots {
    return widget.priceHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  double get _minY {
    if (widget.priceHistory.isEmpty) return 0;
    final min = widget.priceHistory.reduce((a, b) => a < b ? a : b);
    final range = _maxY - min;
    return min - (range * 0.1);
  }

  double get _maxY {
    if (widget.priceHistory.isEmpty) return 100;
    return widget.priceHistory.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          onLongPressStart: (details) => _handleTouch(details.localPosition),
          onLongPressMoveUpdate: (details) => _handleTouch(details.localPosition),
          onLongPressEnd: (_) => _clearTouch(),
          onHorizontalDragStart: (details) => _handleTouch(details.localPosition),
          onHorizontalDragUpdate: (details) => _handleTouch(details.localPosition),
          onHorizontalDragEnd: (_) => _clearTouch(),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (widget.priceHistory.length - 1).toDouble(),
                    minY: _minY,
                    maxY: _maxY,
                    lineTouchData: const LineTouchData(enabled: false),
                    clipData: const FlClipData.all(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getAnimatedSpots(),
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: _chartColor,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _chartColor.withValues(alpha: 0.25),
                              _chartColor.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.8],
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: Duration.zero,
                ),
                if (_touchedX != null)
                  Positioned(
                    left: _touchedX,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                if (_touchedIndex != null && _touchedX != null)
                  Positioned(
                    left: _touchedX! - 8,
                    top: _getYPosition(_touchedIndex!) - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _chartColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<FlSpot> _getAnimatedSpots() {
    final animatedCount = (_spots.length * _animation.value).ceil();
    if (animatedCount <= 0) return [];
    return _spots.sublist(0, animatedCount.clamp(0, _spots.length));
  }

  void _handleTouch(Offset localPosition) {
    final chartWidth = context.size?.width ?? 0;
    if (chartWidth == 0) return;

    final x = localPosition.dx.clamp(0.0, chartWidth);
    final index = ((x / chartWidth) * (widget.priceHistory.length - 1)).round();
    final clampedIndex = index.clamp(0, widget.priceHistory.length - 1);

    if (_touchedIndex != clampedIndex) {
      // HAPTIC FEEDBACK ADDED HERE
      HapticFeedback.selectionClick();
      
      setState(() {
        _touchedX = x;
        _touchedIndex = clampedIndex;
      });

      widget.selectedPriceNotifier?.value = widget.priceHistory[clampedIndex];
      widget.selectedIndexNotifier?.value = clampedIndex;
    }
  }

  void _clearTouch() {
    setState(() {
      _touchedX = null;
      _touchedIndex = null;
    });
    widget.selectedPriceNotifier?.value = null;
    widget.selectedIndexNotifier?.value = null;
  }

  double _getYPosition(int index) {
    final chartHeight = widget.height;
    final value = widget.priceHistory[index];
    final range = _maxY - _minY;
    if (range == 0) return chartHeight / 2;
    
    final normalizedValue = (value - _minY) / range;
    return chartHeight - (normalizedValue * chartHeight);
  }
}
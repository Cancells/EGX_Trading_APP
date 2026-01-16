import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mini sparkline chart for stock cards
class MiniChart extends StatelessWidget {
  final List<double> data;
  final bool isPositive;

  const MiniChart({
    super.key,
    required this.data,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniChartPainter(
        data: data,
        color: isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed,
      ),
      size: Size.infinite,
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniChartPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) {
      // Draw a horizontal line if all values are the same
      final y = size.height / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
      return;
    }

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Use quadratic bezier for smoother curves
        final prevX = (i - 1) * stepX;
        final prevNormalized = (data[i - 1] - minValue) / range;
        final prevY = size.height - (prevNormalized * size.height);
        
        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, prevY, x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom Statch Logo using CustomPainter
class StatchLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const StatchLogo({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StatchLogoPainter(
        color: color ?? AppTheme.robinhoodGreen,
      ),
    );
  }
}

class _StatchLogoPainter extends CustomPainter {
  final Color color;

  _StatchLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw the "S" styled as a stock chart going up
    final path = Path();
    
    // Starting point (bottom left)
    path.moveTo(centerX * 0.4, centerY * 1.5);
    
    // First curve up
    path.cubicTo(
      centerX * 0.3, centerY * 1.2,
      centerX * 0.5, centerY * 1.0,
      centerX, centerY,
    );
    
    // Second curve up (to top right)
    path.cubicTo(
      centerX * 1.5, centerY,
      centerX * 1.7, centerY * 0.8,
      centerX * 1.6, centerY * 0.5,
    );

    canvas.drawPath(path, paint);

    // Draw upward arrow at the end
    final arrowPath = Path();
    final arrowX = centerX * 1.6;
    final arrowY = centerY * 0.5;
    final arrowSize = size.width * 0.12;
    
    arrowPath.moveTo(arrowX, arrowY - arrowSize);
    arrowPath.lineTo(arrowX - arrowSize * 0.7, arrowY);
    arrowPath.lineTo(arrowX, arrowY - arrowSize);
    arrowPath.lineTo(arrowX + arrowSize * 0.7, arrowY);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, fillPaint);

    // Draw small dot at start
    canvas.drawCircle(
      Offset(centerX * 0.4, centerY * 1.5),
      size.width * 0.04,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated Statch Logo with pulse effect
class AnimatedStatchLogo extends StatefulWidget {
  final double size;
  final Color? color;

  const AnimatedStatchLogo({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  State<AnimatedStatchLogo> createState() => _AnimatedStatchLogoState();
}

class _AnimatedStatchLogoState extends State<AnimatedStatchLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: StatchLogo(
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

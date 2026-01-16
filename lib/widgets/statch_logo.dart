import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom Statch Logo using CustomPainter - "Financial Growth" Theme
/// Colors: Emerald Green and Deep Charcoal with gradient effects
class StatchLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showGlow;

  const StatchLogo({
    super.key,
    this.size = 48,
    this.color,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: size,
      height: size,
      decoration: showGlow ? BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (color ?? AppTheme.robinhoodGreen).withValues(alpha: 0.4),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.1,
          ),
        ],
      ) : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: StatchLogoPainter(
          primaryColor: color ?? AppTheme.robinhoodGreen,
          secondaryColor: isDark 
              ? const Color(0xFF1F2937) // Deep Charcoal
              : const Color(0xFF374151),
          isDark: isDark,
        ),
      ),
    );
  }
}

class StatchLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  StatchLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    // Background circle with subtle gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                secondaryColor.withValues(alpha: 0.3),
                secondaryColor.withValues(alpha: 0.1),
              ]
            : [
                primaryColor.withValues(alpha: 0.1),
                primaryColor.withValues(alpha: 0.05),
              ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
    
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.95, bgPaint);

    // Create gradient paint for the chart line
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          primaryColor.withValues(alpha: 0.6),
          primaryColor,
          const Color(0xFF10B981), // Emerald accent
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the growth chart "S" curve
    final chartPath = Path();
    
    // Start from bottom-left
    final startX = centerX * 0.35;
    final startY = centerY * 1.55;
    
    chartPath.moveTo(startX, startY);
    
    // First curve going up-right
    chartPath.cubicTo(
      centerX * 0.25, centerY * 1.2,  // Control point 1
      centerX * 0.6, centerY * 0.95,   // Control point 2
      centerX, centerY * 0.95,          // End point
    );
    
    // Second curve continuing up-right
    chartPath.cubicTo(
      centerX * 1.4, centerY * 0.95,   // Control point 1
      centerX * 1.6, centerY * 0.7,    // Control point 2
      centerX * 1.55, centerY * 0.45,  // End point (top)
    );

    canvas.drawPath(chartPath, gradientPaint);

    // Draw upward arrow at the end (growth indicator)
    final arrowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          primaryColor,
          const Color(0xFF10B981),
        ],
      ).createShader(Rect.fromLTWH(centerX * 1.3, centerY * 0.2, size.width * 0.3, size.height * 0.3))
      ..style = PaintingStyle.fill;

    final arrowX = centerX * 1.55;
    final arrowY = centerY * 0.45;
    final arrowSize = size.width * 0.15;
    
    final arrowPath = Path();
    arrowPath.moveTo(arrowX, arrowY - arrowSize);
    arrowPath.lineTo(arrowX - arrowSize * 0.6, arrowY);
    arrowPath.lineTo(arrowX - arrowSize * 0.2, arrowY);
    arrowPath.lineTo(arrowX - arrowSize * 0.2, arrowY + arrowSize * 0.4);
    arrowPath.lineTo(arrowX + arrowSize * 0.2, arrowY + arrowSize * 0.4);
    arrowPath.lineTo(arrowX + arrowSize * 0.2, arrowY);
    arrowPath.lineTo(arrowX + arrowSize * 0.6, arrowY);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, arrowPaint);

    // Draw starting dot with glow effect
    final dotGlowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.04);
    
    canvas.drawCircle(
      Offset(startX, startY),
      size.width * 0.06,
      dotGlowPaint,
    );

    final dotPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor,
          primaryColor.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromCircle(center: Offset(startX, startY), radius: size.width * 0.04))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(startX, startY),
      size.width * 0.045,
      dotPaint,
    );

    // Add subtle data points along the curve
    final dataPointPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Draw small dots at key positions
    final dots = [
      Offset(centerX * 0.55, centerY * 1.1),
      Offset(centerX * 0.85, centerY * 0.98),
      Offset(centerX * 1.25, centerY * 0.85),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, size.width * 0.02, dataPointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StatchLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor ||
           oldDelegate.isDark != isDark;
  }
}

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
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
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
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (widget.color ?? AppTheme.robinhoodGreen)
                    .withValues(alpha: _glowAnimation.value),
                blurRadius: widget.size * 0.3,
                spreadRadius: widget.size * 0.05,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: StatchLogo(
              size: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class DrawAnimatedStatchLogo extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;

  const DrawAnimatedStatchLogo({
    super.key,
    this.size = 48,
    this.color,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<DrawAnimatedStatchLogo> createState() => _DrawAnimatedStatchLogoState();
}

class _DrawAnimatedStatchLogoState extends State<DrawAnimatedStatchLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DrawAnimatedLogoPainter(
            progress: _controller.value,
            primaryColor: widget.color ?? AppTheme.robinhoodGreen,
            secondaryColor: isDark 
                ? const Color(0xFF1F2937)
                : const Color(0xFF374151),
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _DrawAnimatedLogoPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _DrawAnimatedLogoPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    // Background circle (fade in)
    final bgOpacity = (progress * 2).clamp(0.0, 1.0);
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                secondaryColor.withValues(alpha: 0.3 * bgOpacity),
                secondaryColor.withValues(alpha: 0.1 * bgOpacity),
              ]
            : [
                primaryColor.withValues(alpha: 0.1 * bgOpacity),
                primaryColor.withValues(alpha: 0.05 * bgOpacity),
              ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
    
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.95, bgPaint);

    if (progress > 0.1) {
      final lineProgress = ((progress - 0.1) / 0.6).clamp(0.0, 1.0);
      
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            primaryColor.withValues(alpha: 0.6),
            primaryColor,
            const Color(0xFF10B981),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.065
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final chartPath = Path();
      final startX = centerX * 0.35;
      final startY = centerY * 1.55;
      
      chartPath.moveTo(startX, startY);
      chartPath.cubicTo(
        centerX * 0.25, centerY * 1.2,
        centerX * 0.6, centerY * 0.95,
        centerX, centerY * 0.95,
      );
      chartPath.cubicTo(
        centerX * 1.4, centerY * 0.95,
        centerX * 1.6, centerY * 0.7,
        centerX * 1.55, centerY * 0.45,
      );

      final pathMetrics = chartPath.computeMetrics().first;
      final animatedPath = pathMetrics.extractPath(
        0,
        pathMetrics.length * lineProgress,
      );

      canvas.drawPath(animatedPath, gradientPaint);

      final dotPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(startX, startY), size.width * 0.045, dotPaint);
    }

    if (progress > 0.7) {
      final arrowProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      
      final arrowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            primaryColor.withValues(alpha: arrowProgress),
            const Color(0xFF10B981).withValues(alpha: arrowProgress),
          ],
        ).createShader(Rect.fromLTWH(centerX * 1.3, centerY * 0.2, size.width * 0.3, size.height * 0.3))
        ..style = PaintingStyle.fill;

      final arrowX = centerX * 1.55;
      final arrowY = centerY * 0.45;
      final arrowSize = size.width * 0.15 * arrowProgress;
      
      final arrowPath = Path();
      arrowPath.moveTo(arrowX, arrowY - arrowSize);
      arrowPath.lineTo(arrowX - arrowSize * 0.6, arrowY);
      arrowPath.lineTo(arrowX - arrowSize * 0.2, arrowY);
      arrowPath.lineTo(arrowX - arrowSize * 0.2, arrowY + arrowSize * 0.4);
      arrowPath.lineTo(arrowX + arrowSize * 0.2, arrowY + arrowSize * 0.4);
      arrowPath.lineTo(arrowX + arrowSize * 0.2, arrowY);
      arrowPath.lineTo(arrowX + arrowSize * 0.6, arrowY);
      arrowPath.close();
      
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawAnimatedLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
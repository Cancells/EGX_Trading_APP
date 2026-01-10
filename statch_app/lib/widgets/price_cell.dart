import 'dart:async';
import 'package:flutter/material.dart';
import '../services/realtime_stock_service.dart';
import '../theme/app_theme.dart';

/// Animated price cell with tick animation and arrow indicator
class PriceCell extends StatefulWidget {
  final String symbol;
  final double price;
  final double changePercent;
  final bool isPositive;
  final TextStyle? priceStyle;
  final TextStyle? changeStyle;
  final bool showArrow;
  final bool enableTickAnimation;
  final CrossAxisAlignment alignment;

  const PriceCell({
    super.key,
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.isPositive,
    this.priceStyle,
    this.changeStyle,
    this.showArrow = true,
    this.enableTickAnimation = true,
    this.alignment = CrossAxisAlignment.end,
  });

  @override
  State<PriceCell> createState() => _PriceCellState();
}

class _PriceCellState extends State<PriceCell> with SingleTickerProviderStateMixin {
  final RealTimeStockService _realTimeService = RealTimeStockService();
  StreamSubscription<Map<String, RealTimePrice>>? _subscription;
  
  late double _currentPrice;
  late double _currentChangePercent;
  late bool _currentIsPositive;
  
  Color _flashColor = Colors.transparent;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.price;
    _currentChangePercent = widget.changePercent;
    _currentIsPositive = widget.isPositive;

    // Setup flash animation controller
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _flashAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _flashController.addListener(() {
      setState(() {});
    });

    // Subscribe to real-time updates
    if (widget.enableTickAnimation) {
      _subscription = _realTimeService.priceStream.listen(_onPriceUpdate);
    }
  }

  @override
  void didUpdateWidget(PriceCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update from parent if real-time is not providing updates
    if (oldWidget.price != widget.price) {
      _handlePriceChange(widget.price, widget.changePercent, widget.isPositive);
    }
  }

  void _onPriceUpdate(Map<String, RealTimePrice> prices) {
    final priceData = prices[widget.symbol];
    if (priceData != null && priceData.price != _currentPrice) {
      _handlePriceChange(
        priceData.price,
        priceData.changePercent,
        priceData.isPositive,
        direction: priceData.direction,
      );
    }
  }

  void _handlePriceChange(
    double newPrice,
    double newChangePercent,
    bool newIsPositive, {
    PriceDirection? direction,
  }) {
    if (!mounted) return;

    // Determine direction if not provided
    final priceDirection = direction ?? (
      newPrice > _currentPrice 
          ? PriceDirection.up 
          : newPrice < _currentPrice 
              ? PriceDirection.down 
              : PriceDirection.unchanged
    );

    setState(() {
      _currentPrice = newPrice;
      _currentChangePercent = newChangePercent;
      _currentIsPositive = newIsPositive;

      // Trigger flash animation
      if (widget.enableTickAnimation && priceDirection != PriceDirection.unchanged) {
        _flashColor = priceDirection == PriceDirection.up
            ? AppTheme.robinhoodGreen
            : AppTheme.robinhoodRed;
        _flashController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _flashColor.withValues(alpha: _flashAnimation.value),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: widget.alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${_currentPrice.toStringAsFixed(2)} EGP',
              key: ValueKey(_currentPrice),
              style: widget.priceStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Change with Arrow
          _buildChangeIndicator(context),
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(BuildContext context) {
    final color = _currentIsPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showArrow) ...[
          PriceArrowIndicator(
            changePercent: _currentChangePercent,
            size: 12,
          ),
          const SizedBox(width: 2),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            '${_currentChangePercent >= 0 ? '+' : ''}${_currentChangePercent.toStringAsFixed(2)}%',
            key: ValueKey(_currentChangePercent),
            style: widget.changeStyle ?? TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Arrow indicator for price direction
class PriceArrowIndicator extends StatelessWidget {
  final double changePercent;
  final double size;

  const PriceArrowIndicator({
    super.key,
    required this.changePercent,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if (changePercent > 0) {
      icon = Icons.arrow_upward_rounded;
      color = AppTheme.robinhoodGreen;
    } else if (changePercent < 0) {
      icon = Icons.arrow_downward_rounded;
      color = AppTheme.robinhoodRed;
    } else {
      icon = Icons.remove_rounded;
      color = AppTheme.mutedText;
    }

    return Icon(icon, size: size, color: color);
  }
}

/// Standalone tick animation wrapper
class TickAnimationWrapper extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Color? flashColor;

  const TickAnimationWrapper({
    super.key,
    required this.child,
    this.animate = false,
    this.flashColor,
  });

  @override
  State<TickAnimationWrapper> createState() => _TickAnimationWrapperState();
}

class _TickAnimationWrapperState extends State<TickAnimationWrapper> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(TickAnimationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
    }
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
        return Container(
          decoration: BoxDecoration(
            color: (widget.flashColor ?? Colors.transparent)
                .withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Compact price display for stock cards
class CompactPriceCell extends StatelessWidget {
  final double price;
  final double changePercent;
  final bool isPositive;
  final bool showArrow;

  const CompactPriceCell({
    super.key,
    required this.price,
    required this.changePercent,
    required this.isPositive,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppTheme.robinhoodGreen : AppTheme.robinhoodRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${price.toStringAsFixed(2)} EGP',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showArrow) ...[
              PriceArrowIndicator(changePercent: changePercent, size: 12),
              const SizedBox(width: 2),
            ],
            Text(
              '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

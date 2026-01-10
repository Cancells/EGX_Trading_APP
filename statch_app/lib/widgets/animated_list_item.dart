import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated list item wrapper with fadeIn + slideX effect
/// Duration: 300ms for snappy feel
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay * index)
        .fadeIn(duration: duration)
        .slideX(
          begin: 0.1,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Extension for easy animation of any widget in a list
extension AnimatedListExtension on Widget {
  Widget animateListItem(int index) {
    return AnimatedListItem(index: index, child: this);
  }
}

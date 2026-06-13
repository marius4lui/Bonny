import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.38, end: 0.78),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Column(
          children: [
            _bar(context, double.infinity, 210, value, radius: 28),
            const SizedBox(height: 18),
            _bar(context, double.infinity, 92, value),
            const SizedBox(height: 12),
            _bar(context, double.infinity, 92, value),
            const SizedBox(height: 12),
            _bar(context, double.infinity, 92, value),
          ],
        );
      },
      onEnd: () {},
    );
  }

  Widget _bar(
    BuildContext context,
    double width,
    double height,
    double opacity, {
    double radius = 22,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.secondarySurface.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SuccessBurst extends StatefulWidget {
  const SuccessBurst({super.key});

  @override
  State<SuccessBurst> createState() => _SuccessBurstState();
}

class _SuccessBurstState extends State<SuccessBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (MediaQuery.disableAnimationsOf(context)) {
      return _Check(colors: colors, scale: 1);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = Curves.easeOutCubic.transform(_controller.value);
        return SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final angle in [0.0, .8, 1.6, 2.4, 3.2, 4.0])
                Transform.translate(
                  offset: Offset.fromDirection(angle, value * 52),
                  child: Opacity(
                    opacity: (1 - value).clamp(0, 1),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.secondaryAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              _Check(colors: colors, scale: value),
            ],
          ),
        );
      },
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.colors, required this.scale});

  final BonnyColors colors;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.75 + scale * 0.25,
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: colors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.success.withValues(alpha: 0.28),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Icon(Icons.check_rounded, color: colors.inverseText, size: 58),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    this.footer,
    this.background,
  });

  final Widget child;
  final Widget? footer;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(child: background ?? const _SoftBlobBackground()),
          Positioned.fill(child: child),
        ],
      ),
      bottomNavigationBar: footer,
    );
  }
}

class _SoftBlobBackground extends StatefulWidget {
  const _SoftBlobBackground();

  @override
  State<_SoftBlobBackground> createState() => _SoftBlobBackgroundState();
}

class _SoftBlobBackgroundState extends State<_SoftBlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
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
      return ColoredBox(color: colors.background);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = Curves.easeInOut.transform(_controller.value);
        return Stack(
          children: [
            Positioned(
              top: 52 + value * 18,
              left: -80,
              child: _Blob(
                color: colors.primaryAccent.withValues(alpha: 0.13),
                size: 210,
              ),
            ),
            Positioned(
              top: 190 - value * 22,
              right: -92,
              child: _Blob(
                color: colors.secondaryAccent.withValues(alpha: 0.12),
                size: 240,
              ),
            ),
            Positioned(
              bottom: 130 + value * 16,
              left: 70,
              child: _Blob(
                color: colors.supportAccent.withValues(alpha: 0.10),
                size: 170,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 70, spreadRadius: 18)],
      ),
    );
  }
}

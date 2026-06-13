import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/animated_receipt_card.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key, required this.onThemeToggle});

  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 160),
        children: [
          Row(
            children: [
              Text('Bonny', style: context.text.headlineMedium),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onThemeToggle,
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                tooltip: 'Toggle theme',
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const AnimatedReceiptCard(),
                const _FloatingChip(
                  label: 'Scan',
                  alignment: Alignment(-0.95, -0.55),
                  delay: 0,
                ),
                const _FloatingChip(
                  label: 'Review',
                  alignment: Alignment(0.95, -0.18),
                  delay: 120,
                ),
                const _FloatingChip(
                  label: 'Save',
                  alignment: Alignment(-0.82, 0.58),
                  delay: 240,
                ),
                const _FloatingChip(
                  label: 'Report',
                  alignment: Alignment(0.82, 0.62),
                  delay: 360,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'PRIVATE RECEIPT HELPER',
            style: context.text.labelSmall?.copyWith(
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Turn receipts into monthly summaries.',
            style: context.text.displayLarge?.copyWith(fontSize: 38),
          ),
          const SizedBox(height: 14),
          Text(
            'Scan receipts, review the items, exclude private purchases, and create a clean monthly overview.',
            style: context.text.bodyLarge?.copyWith(
              color: colors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.label,
    required this.alignment,
    required this.delay,
  });

  final String label;
  final Alignment alignment;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Duration(milliseconds: 520 + delay),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + value * 0.2, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(label, style: context.text.labelMedium),
        ),
      ),
    );
  }
}

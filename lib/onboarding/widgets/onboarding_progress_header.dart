import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.trailing,
  });

  final int step;
  final int total;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = step / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton.filledTonal(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.secondarySurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'Step $step of $total',
                  style: context.text.labelMedium,
                ),
              ),
              const Spacer(),
              trailing ?? const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: colors.secondarySurface,
              valueColor: AlwaysStoppedAnimation(colors.primaryAccent),
            ),
          ),
          const SizedBox(height: 22),
          Text(title, style: context.text.displayLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

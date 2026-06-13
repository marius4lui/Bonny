import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/onboarding_hero_card.dart';
import '../widgets/onboarding_progress_header.dart';

class OnboardingReviewRetryScreen extends StatelessWidget {
  const OnboardingReviewRetryScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: [
          OnboardingProgressHeader(
            step: 4,
            total: 8,
            title: 'You stay in control',
            subtitle: 'Bonny never saves AI results without your confirmation.',
            onBack: onBack,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _Field(label: 'Merchant', value: 'Lidl'),
                  const SizedBox(height: 10),
                  _Field(label: 'Total', value: '€11.84', highlighted: true),
                  const SizedBox(height: 14),
                  _Item(name: 'Fanta Orange', price: '€1.49', excluded: true),
                  _Item(name: 'Bread', price: '€2.49', excluded: false),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Analysis'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OnboardingHeroCard(
              icon: Icons.verified_user_rounded,
              title: 'AI is helpful, not final',
              body: 'Edit anything before it becomes part of your month.',
              color: colors.secondaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.warning.withValues(alpha: 0.10)
            : colors.cardTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? colors.warning.withValues(alpha: 0.35)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          Text(label, style: context.text.labelMedium),
          const Spacer(),
          Text(value, style: context.text.bodyLarge),
          const SizedBox(width: 8),
          Icon(Icons.edit_rounded, size: 18, color: colors.mutedText),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.name,
    required this.price,
    required this.excluded,
  });

  final String name;
  final String price;
  final bool excluded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = excluded ? colors.warning : colors.secondaryAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            excluded ? Icons.block_rounded : Icons.check_circle_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: context.text.bodyLarge)),
          Text(price, style: context.text.bodyLarge),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              excluded ? 'Excluded' : 'Included',
              style: context.text.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

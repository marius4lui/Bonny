import 'package:flutter/material.dart';

import '../widgets/feature_card.dart';
import '../widgets/onboarding_progress_header.dart';

class OnboardingFeaturesScreen extends StatelessWidget {
  const OnboardingFeaturesScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: [
          OnboardingProgressHeader(
            step: 2,
            total: 8,
            title: 'What Bonny does',
            subtitle: 'Simple receipt tracking without finance clutter.',
            onBack: onBack,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
              children: const [
                FeatureCard(
                  icon: Icons.document_scanner_rounded,
                  title: 'Scan receipts',
                  body: 'Camera or gallery. One receipt or many.',
                ),
                FeatureCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Review before saving',
                  body: 'AI creates a draft. You confirm what is correct.',
                  delay: 80,
                ),
                FeatureCard(
                  icon: Icons.filter_alt_rounded,
                  title: 'Exclude items',
                  body:
                      'Automatically exclude items like Fanta, Cola or Chips.',
                  delay: 160,
                ),
                FeatureCard(
                  icon: Icons.pie_chart_rounded,
                  title: 'Monthly report',
                  body:
                      'See what counted, what was excluded, and what changed your month.',
                  delay: 240,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

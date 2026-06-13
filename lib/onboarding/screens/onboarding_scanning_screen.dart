import 'package:flutter/material.dart';

import '../widgets/onboarding_hero_card.dart';
import '../widgets/onboarding_progress_header.dart';
import '../widgets/scanner_beam_demo.dart';

class OnboardingScanningScreen extends StatelessWidget {
  const OnboardingScanningScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: [
          OnboardingProgressHeader(
            step: 3,
            total: 8,
            title: 'Scan, review, save',
            subtitle: 'Every receipt goes through a review step.',
            onBack: onBack,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ScannerBeamDemo(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: const [
                OnboardingHeroCard(
                  icon: Icons.looks_one_rounded,
                  title: 'Scan or import',
                  body: 'Bonny sends one receipt image at a time to the AI.',
                ),
                SizedBox(height: 10),
                OnboardingHeroCard(
                  icon: Icons.queue_rounded,
                  title: 'Multiple images',
                  body: 'Multiple receipts are processed one by one.',
                ),
                SizedBox(height: 10),
                OnboardingHeroCard(
                  icon: Icons.refresh_rounded,
                  title: 'Bad scan?',
                  body: 'Retry Analysis creates a fresh result.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

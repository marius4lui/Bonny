import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/onboarding_progress_header.dart';
import '../widgets/privacy_flow_card.dart';

class OnboardingPrivacyScreen extends StatelessWidget {
  const OnboardingPrivacyScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final rows = [
      'Receipts are saved locally.',
      'API key is stored securely.',
      'AI output is never saved without review.',
      'Debug exports redact secrets.',
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: [
          OnboardingProgressHeader(
            step: 7,
            total: 8,
            title: 'Private by default',
            subtitle: 'Bonny is built for personal local use.',
            onBack: onBack,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: PrivacyFlowCard(),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.secondaryAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(row, style: context.text.bodyLarge),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Text(
              'Images are sent to OpenRouter only when you analyze them. Debug exports redact secrets, but may contain receipt data.',
              style: context.text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

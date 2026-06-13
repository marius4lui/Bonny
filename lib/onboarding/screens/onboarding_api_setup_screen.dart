import 'package:flutter/material.dart';

import '../widgets/api_key_setup_card.dart';
import '../widgets/onboarding_hero_card.dart';
import '../widgets/onboarding_progress_header.dart';

class OnboardingApiSetupScreen extends StatelessWidget {
  const OnboardingApiSetupScreen({
    super.key,
    required this.onBack,
    required this.controller,
    required this.status,
    required this.obscureText,
    required this.onToggleObscure,
    required this.onSave,
    required this.onTest,
    required this.maskedKey,
    this.errorText,
    this.warningText,
  });

  final VoidCallback onBack;
  final TextEditingController controller;
  final ApiSetupStatus status;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final VoidCallback onSave;
  final VoidCallback onTest;
  final String maskedKey;
  final String? errorText;
  final String? warningText;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 180),
        children: [
          OnboardingProgressHeader(
            step: 6,
            total: 8,
            title: 'Connect OpenRouter',
            subtitle: 'Required for AI receipt extraction.',
            onBack: onBack,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ApiKeySetupCard(
              controller: controller,
              status: status,
              obscureText: obscureText,
              onToggleObscure: onToggleObscure,
              onSave: onSave,
              onTest: onTest,
              maskedKey: maskedKey,
              errorText: errorText,
              warningText: warningText,
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: OnboardingHeroCard(
              icon: Icons.privacy_tip_rounded,
              title: 'Stored locally and securely',
              body:
                  'Bonny never hardcodes your key and never shows it in full after saving.',
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/exclusion_chip_editor.dart';
import '../widgets/onboarding_hero_card.dart';
import '../widgets/onboarding_progress_header.dart';
import '../widgets/rule_test_card.dart';

class OnboardingExclusionRulesScreen extends StatelessWidget {
  const OnboardingExclusionRulesScreen({
    super.key,
    required this.onBack,
    required this.keywords,
    required this.onKeywordsChanged,
  });

  final VoidCallback onBack;
  final List<String> keywords;
  final ValueChanged<List<String>> onKeywordsChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: [
          OnboardingProgressHeader(
            step: 5,
            total: 8,
            title: 'Set your exclusions',
            subtitle: 'Bonny can automatically mark private items as excluded.',
            onBack: onBack,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ExclusionChipEditor(
              keywords: keywords,
              onChanged: onKeywordsChanged,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: RuleTestCard(keywords: keywords),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OnboardingHeroCard(
              icon: Icons.tune_rounded,
              title: 'Rules are suggestions',
              body: 'You can override every item before saving.',
              color: context.colors.secondaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

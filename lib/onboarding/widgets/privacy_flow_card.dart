import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PrivacyFlowCard extends StatelessWidget {
  const PrivacyFlowCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: _PrivacyNode(
                  icon: Icons.phone_iphone_rounded,
                  label: 'Your device',
                ),
              ),
              _FlowArrow(label: 'Analyze'),
              Expanded(
                child: _PrivacyNode(
                  icon: Icons.auto_awesome_rounded,
                  label: 'OpenRouter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _PrivacyNode(
                  icon: Icons.fact_check_rounded,
                  label: 'You review',
                ),
              ),
              _FlowArrow(label: 'Save'),
              Expanded(
                child: _PrivacyNode(
                  icon: Icons.lock_rounded,
                  label: 'Local data',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacyNode extends StatelessWidget {
  const _PrivacyNode({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: colors.cardTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primaryAccent),
          const SizedBox(height: 8),
          Text(
            label,
            style: context.text.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Icon(Icons.arrow_forward_rounded, color: context.colors.mutedText),
          Text(
            label,
            style: context.text.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/demo_receipt_preview.dart';
import '../widgets/setup_checklist.dart';
import '../widgets/success_burst.dart';

class OnboardingReadyScreen extends StatelessWidget {
  const OnboardingReadyScreen({
    super.key,
    required this.apiConfigured,
    required this.onDemo,
  });

  final bool apiConfigured;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 180),
        children: [
          const Center(child: SuccessBurst()),
          const SizedBox(height: 12),
          Text(
            'Bonny is ready.',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Scan your first receipt or import photos from your gallery.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SetupChecklist(
            rows: [
              const SetupChecklistRow(label: 'Receipt review explained'),
              const SetupChecklistRow(label: 'Exclusion rules configured'),
              const SetupChecklistRow(label: 'Monthly reports ready'),
              SetupChecklistRow(
                label: apiConfigured
                    ? 'OpenRouter connected'
                    : 'OpenRouter can be added later',
                complete: apiConfigured,
                optional: !apiConfigured,
              ),
              const SetupChecklistRow(label: 'Debug tools available'),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onDemo,
            child: const DemoReceiptPreview(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
    this.primaryEnabled = true,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (secondaryLabel != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(secondaryLabel!),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      child: FilledButton(
                        onPressed: primaryEnabled ? onPrimary : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.hero,
                          foregroundColor: colors.inverseText,
                          disabledBackgroundColor: colors.mutedText.withValues(
                            alpha: 0.18,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(primaryLabel),
                      ),
                    ),
                  ),
                ],
              ),
              if (tertiaryLabel != null) ...[
                const SizedBox(height: 4),
                TextButton(onPressed: onTertiary, child: Text(tertiaryLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

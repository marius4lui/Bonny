import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.dark = false,
  });

  final String label;
  final String value;
  final Color? accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = dark ? colors.inverseText : colors.primaryText;
    final labelColor = dark ? colors.mutedText : colors.secondaryText;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? colors.heroSecondary : colors.secondarySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? colors.heroSecondary : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.labelMedium?.copyWith(color: labelColor),
          ),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.text.headlineMedium?.copyWith(
                color: accent ?? textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightPill extends StatelessWidget {
  const InsightPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.secondarySurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color ?? context.colors.primaryAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                color: context.colors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

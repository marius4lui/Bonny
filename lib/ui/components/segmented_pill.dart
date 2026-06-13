import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.values,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> values;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.colors.secondarySurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? context.colors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    values[i].toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      color: i == selectedIndex
                          ? context.colors.primaryText
                          : context.colors.secondaryText,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

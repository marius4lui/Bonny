import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SetupChecklist extends StatelessWidget {
  const SetupChecklist({super.key, required this.rows});

  final List<SetupChecklistRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Duration(milliseconds: 380 + index * 90),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 12),
                  child: child,
                ),
              );
            },
            child: _ChecklistTile(row: rows[index]),
          ),
      ],
    );
  }
}

class SetupChecklistRow {
  const SetupChecklistRow({
    required this.label,
    this.complete = true,
    this.optional = false,
  });

  final String label;
  final bool complete;
  final bool optional;
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.row});

  final SetupChecklistRow row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = row.complete ? colors.success : colors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            row.complete ? Icons.check_circle_rounded : Icons.info_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(row.label, style: context.text.bodyLarge)),
          if (row.optional) Text('Optional', style: context.text.labelMedium),
        ],
      ),
    );
  }
}

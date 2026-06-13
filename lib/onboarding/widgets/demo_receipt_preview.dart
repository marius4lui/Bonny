import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DemoReceiptPreview extends StatelessWidget {
  const DemoReceiptPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = [
      'Latte Macch. Vanille',
      'Maracuja Nektar',
      'Fanta Orange',
      'Pfand 0,25',
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, color: colors.primaryAccent),
              const SizedBox(width: 10),
              Text('Demo receipt', style: context.text.titleLarge),
              const Spacer(),
              Text('Not saved', style: context.text.labelMedium),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Lidl', style: context.text.headlineMedium),
              const Spacer(),
              Text('€11.84', style: context.text.headlineMedium),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    item.startsWith('Fanta')
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    size: 18,
                    color: item.startsWith('Fanta')
                        ? colors.warning
                        : colors.secondaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: context.text.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/receipt_import_queue.dart';
import '../../theme/app_theme.dart';

class ImportCompleteSheet extends StatelessWidget {
  const ImportCompleteSheet({
    super.key,
    required this.queue,
    required this.onViewReceipts,
    required this.onOpenMonthlyReport,
  });

  final ReceiptImportQueue queue;
  final VoidCallback onViewReceipts;
  final VoidCallback onOpenMonthlyReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 68,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.mutedText.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.colors.secondaryAccent.withValues(
                      alpha: 0.14,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: context.colors.secondaryAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import complete',
                        style: context.text.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${queue.processedReceiptIds.length} receipts processed',
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SummaryRow(
              label: 'Processed',
              value: '${queue.processedReceiptIds.length}',
            ),
            _SummaryRow(
              label: 'Skipped',
              value: '${queue.skippedImagePaths.length}',
            ),
            _SummaryRow(
              label: 'Failed',
              value: '${queue.failedImagePaths.length}',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onViewReceipts,
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('View Receipts'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenMonthlyReport,
                icon: const Icon(Icons.pie_chart_rounded),
                label: const Text('Open Monthly Report'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.text.bodyMedium)),
          Text(value, style: context.text.bodyLarge),
        ],
      ),
    );
  }
}

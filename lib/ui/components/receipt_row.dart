import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/receipt.dart';
import '../../theme/app_theme.dart';
import 'formatters.dart';

class ReceiptRow extends StatelessWidget {
  const ReceiptRow({
    super.key,
    required this.receipt,
    this.onTap,
    this.onDelete,
  });

  final Receipt receipt;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.secondarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: context.colors.primaryAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.merchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('d MMM').format(receipt.purchaseDate)} · ${receipt.items.length} items · ${money(receipt.excludedTotal, receipt.currency)} excluded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(receipt.receiptTotal, receipt.currency),
                  style: context.text.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  money(receipt.reimbursableTotal, receipt.currency),
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.secondaryAccent,
                  ),
                ),
              ],
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: context.colors.mutedText,
                ),
                tooltip: 'Delete receipt',
              ),
          ],
        ),
      ),
    );
  }
}

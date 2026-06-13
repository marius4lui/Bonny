import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/bonny_app.dart';
import '../../models/receipt.dart';
import '../../services/retry_analysis_service.dart';
import '../../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bonny_card.dart';
import '../components/formatters.dart';
import '../components/receipt_row.dart';
import 'receipt_review_screen.dart';

class ReceiptDetailScreen extends StatefulWidget {
  const ReceiptDetailScreen({super.key, required this.receipt});

  final Receipt receipt;

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  bool _reanalyzing = false;

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final receipt = app.receipts.firstWhere(
      (entry) => entry.id == widget.receipt.id,
      orElse: () => widget.receipt,
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            AppHeader(
              title: receipt.merchant,
              subtitle: DateFormat.yMMMd().format(receipt.purchaseDate),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (value) {
                  if (value == 'reanalyze') _reanalyze(receipt);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'reanalyze',
                    child: Text('Re-analyze Receipt'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  if (_reanalyzing)
                    BonnyCard(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Re-analyzing receipt...',
                            style: context.text.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  if (_reanalyzing) const SizedBox(height: 18),
                  if (receipt.imagePath.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        color: context.colors.secondarySurface,
                        child: Image.file(
                          File(receipt.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.receipt_long_rounded,
                            size: 56,
                            color: context.colors.mutedText,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  BonnyCard(child: ReceiptRow(receipt: receipt)),
                  const SizedBox(height: 18),
                  BonnyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items', style: context.text.titleLarge),
                        const SizedBox(height: 10),
                        for (final item in receipt.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: context.text.bodyLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(money(item.totalPrice, receipt.currency)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reanalyze(Receipt receipt) async {
    final app = AppStateScope.of(context);
    final image = File(receipt.imagePath);
    if (!await image.exists()) {
      await app.logError(
        StateError(
          'Original image not found. This receipt cannot be re-analyzed.',
        ),
        StackTrace.current,
        context: 'Saved receipt re-analysis image missing',
        data: {'receiptId': receipt.id, 'imagePath': receipt.imagePath},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Original image not found. This receipt cannot be re-analyzed.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-analyze receipt?'),
        content: const Text(
          'This will analyze the original image again and create a new draft. Your saved receipt will not be changed until you confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Re-analyze'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _reanalyzing = true);
    final draft = await app.retryAnalysis(
      imagePath: receipt.imagePath,
      source: RetrySource.savedReceiptDetail,
      receiptId: receipt.id,
      replacedSavedReceiptId: receipt.id,
    );
    if (!mounted) return;
    setState(() => _reanalyzing = false);
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retry failed. Saved receipt was not changed.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptReviewScreen(
          draft: draft,
          onConfirm: (replacement) async {
            await app.saveReceipt(replacement.copyWith(id: receipt.id));
            if (!mounted) return true;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved receipt replaced.')),
            );
            return true;
          },
        ),
      ),
    );
  }
}

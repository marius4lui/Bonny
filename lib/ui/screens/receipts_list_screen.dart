import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/bonny_app.dart';
import '../../models/receipt.dart';
import '../../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bonny_card.dart';
import '../components/empty_state.dart';
import '../components/receipt_row.dart';
import 'add_receipt_screen.dart';
import 'receipt_detail_screen.dart';

class ReceiptsListScreen extends StatefulWidget {
  const ReceiptsListScreen({super.key});

  @override
  State<ReceiptsListScreen> createState() => _ReceiptsListScreenState();
}

class _ReceiptsListScreenState extends State<ReceiptsListScreen> {
  final TextEditingController _search = TextEditingController();
  int _filter = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final receipts = _filtered(app.receipts);
    final grouped = <String, List<Receipt>>{};
    for (final receipt in receipts) {
      final key = DateFormat.yMMMM().format(receipt.purchaseDate);
      grouped.putIfAbsent(key, () => []).add(receipt);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          const AppHeader(title: 'Receipts', subtitle: 'Saved and reviewed'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search merchant or item',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        'All',
                        0,
                        _filter,
                        (v) => setState(() => _filter = v),
                      ),
                      _FilterChip(
                        'This Month',
                        1,
                        _filter,
                        (v) => setState(() => _filter = v),
                      ),
                      _FilterChip(
                        'Excluded Items',
                        2,
                        _filter,
                        (v) => setState(() => _filter = v),
                      ),
                      _FilterChip(
                        'High Spend',
                        3,
                        _filter,
                        (v) => setState(() => _filter = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (app.receipts.isEmpty)
                  BonnyCard(
                    child: EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No receipts saved',
                      message: 'Your reviewed receipts will appear here.',
                      action: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddReceiptScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Receipt'),
                      ),
                    ),
                  )
                else if (receipts.isEmpty)
                  const BonnyCard(
                    child: EmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'No matching receipts',
                      message: 'Try another search or filter.',
                    ),
                  )
                else
                  for (final entry in grouped.entries) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 10, 0, 8),
                        child: Text(entry.key, style: context.text.labelSmall),
                      ),
                    ),
                    BonnyCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          for (final receipt in entry.value)
                            ReceiptRow(
                              receipt: receipt,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReceiptDetailScreen(receipt: receipt),
                                ),
                              ),
                              onDelete: () => _confirmDelete(receipt),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Receipt> _filtered(List<Receipt> receipts) {
    final query = _search.text.trim().toLowerCase();
    final now = DateTime.now();
    return receipts.where((receipt) {
      final matchesQuery =
          query.isEmpty ||
          receipt.merchant.toLowerCase().contains(query) ||
          receipt.items.any((item) => item.name.toLowerCase().contains(query));
      if (!matchesQuery) return false;
      if (_filter == 1) {
        return receipt.purchaseDate.year == now.year &&
            receipt.purchaseDate.month == now.month;
      }
      if (_filter == 2) return receipt.excludedTotal > 0;
      if (_filter == 3) return receipt.receiptTotal >= 50;
      return true;
    }).toList();
  }

  Future<void> _confirmDelete(Receipt receipt) async {
    final app = AppStateScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: Text(
          '${receipt.merchant} will be removed from local storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await app.deleteReceipt(receipt.id);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, this.value, this.selected, this.onSelected);

  final String label;
  final int value;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => onSelected(value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        selectedColor: context.colors.primaryAccent.withValues(alpha: 0.14),
        backgroundColor: context.colors.secondarySurface,
        labelStyle: context.text.labelMedium?.copyWith(
          color: isSelected
              ? context.colors.primaryAccent
              : context.colors.secondaryText,
        ),
      ),
    );
  }
}

import 'package:collection/collection.dart';

import '../models/receipt.dart';
import '../models/report.dart';

class ReportService {
  MonthlyReport buildMonthlyReport(List<Receipt> receipts, DateTime month) {
    final monthReceipts = receipts
        .where(
          (receipt) =>
              receipt.purchaseDate.year == month.year &&
              receipt.purchaseDate.month == month.month,
        )
        .toList();

    final allItems = monthReceipts.expand((receipt) => receipt.items).toList();
    final excludedItems = allItems.where((item) => !item.reimbursable).toList();

    return MonthlyReport(
      month: DateTime(month.year, month.month),
      receipts: monthReceipts,
      receiptTotal: _sum(monthReceipts.map((receipt) => receipt.receiptTotal)),
      reimbursableTotal: _sum(
        monthReceipts.map((receipt) => receipt.reimbursableTotal),
      ),
      excludedTotal: _sum(
        monthReceipts.map((receipt) => receipt.excludedTotal),
      ),
      itemCount: allItems.length,
      excludedItems: _aggregateItems(excludedItems),
      itemFrequency: _aggregateItems(allItems),
      categoryTotals: _aggregateCategories(allItems),
    );
  }

  List<ItemAggregate> _aggregateItems(List<ReceiptItem> items) {
    final grouped = groupBy(items, (item) => _normalizeName(item.name));
    final aggregates = grouped.entries.map((entry) {
      return ItemAggregate(
        name: entry.value.first.name,
        count: entry.value.length,
        total: _sum(entry.value.map((item) => item.totalPrice)),
      );
    }).toList();
    aggregates.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount == 0 ? b.total.compareTo(a.total) : byCount;
    });
    return aggregates;
  }

  List<CategoryAggregate> _aggregateCategories(List<ReceiptItem> items) {
    final grouped = groupBy(
      items,
      (item) => (item.category?.trim().isNotEmpty == true)
          ? item.category!.trim()
          : 'Other',
    );
    final aggregates = grouped.entries.map((entry) {
      return CategoryAggregate(
        category: entry.key,
        total: _sum(entry.value.map((item) => item.totalPrice)),
      );
    }).toList();
    aggregates.sort((a, b) => b.total.compareTo(a.total));
    return aggregates;
  }

  String _normalizeName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  double _sum(Iterable<double> values) {
    return double.parse(
      values.fold(0.0, (sum, value) => sum + value).toStringAsFixed(2),
    );
  }
}

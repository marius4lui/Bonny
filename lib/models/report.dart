import 'receipt.dart';

class MonthlyReport {
  MonthlyReport({
    required this.month,
    required this.receipts,
    required this.receiptTotal,
    required this.reimbursableTotal,
    required this.excludedTotal,
    required this.itemCount,
    required this.excludedItems,
    required this.itemFrequency,
    required this.categoryTotals,
  });

  final DateTime month;
  final List<Receipt> receipts;
  final double receiptTotal;
  final double reimbursableTotal;
  final double excludedTotal;
  final int itemCount;
  final List<ItemAggregate> excludedItems;
  final List<ItemAggregate> itemFrequency;
  final List<CategoryAggregate> categoryTotals;
}

class ItemAggregate {
  const ItemAggregate({
    required this.name,
    required this.count,
    required this.total,
  });

  final String name;
  final int count;
  final double total;
}

class CategoryAggregate {
  const CategoryAggregate({required this.category, required this.total});

  final String category;
  final double total;
}

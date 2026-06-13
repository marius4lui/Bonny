import 'receipt.dart';

class DraftReceipt {
  DraftReceipt({
    required this.imagePath,
    required this.merchant,
    required this.purchaseDate,
    required this.currency,
    required this.receiptTotal,
    required this.items,
    this.extractionId,
    this.warnings = const [],
  });

  final String imagePath;
  final String merchant;
  final DateTime purchaseDate;
  final String currency;
  final double receiptTotal;
  final List<ReceiptItem> items;
  final String? extractionId;
  final List<String> warnings;

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'merchant': merchant,
      'purchaseDate': purchaseDate.toIso8601String(),
      'currency': currency,
      'receiptTotal': receiptTotal,
      'items': items.map((item) => item.toJson()).toList(),
      'extractionId': extractionId,
      'warnings': warnings,
    };
  }

  Map<String, dynamic> summaryJson() {
    return {
      'imagePath': imagePath,
      'merchant': merchant,
      'purchaseDate': purchaseDate.toIso8601String(),
      'currency': currency,
      'receiptTotal': receiptTotal,
      'itemCount': items.length,
      'itemSum': calculateTotals(items).total,
      'extractionId': extractionId,
      'warnings': warnings,
    };
  }
}

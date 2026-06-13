import 'package:intl/intl.dart';

import '../models/report.dart';

class ExportService {
  String buildMonthlySummary(MonthlyReport report) {
    final month = DateFormat.yMMMM().format(report.month);
    final buffer = StringBuffer()
      ..writeln('Bonny monthly summary')
      ..writeln(month)
      ..writeln('')
      ..writeln('Receipts: ${report.receipts.length}')
      ..writeln('Items: ${report.itemCount}')
      ..writeln('Total spend: ${_money(report.receiptTotal)}')
      ..writeln('Reimbursable: ${_money(report.reimbursableTotal)}')
      ..writeln('Excluded: ${_money(report.excludedTotal)}')
      ..writeln('')
      ..writeln('Excluded items');

    if (report.excludedItems.isEmpty) {
      buffer.writeln('- None');
    } else {
      for (final item in report.excludedItems.take(20)) {
        buffer.writeln('- ${item.name}: ${item.count}x, ${_money(item.total)}');
      }
    }

    buffer
      ..writeln('')
      ..writeln('Category breakdown');
    if (report.categoryTotals.isEmpty) {
      buffer.writeln('- No items yet');
    } else {
      for (final category in report.categoryTotals) {
        buffer.writeln('- ${category.category}: ${_money(category.total)}');
      }
    }

    return buffer.toString();
  }

  String _money(double value) => 'EUR ${value.toStringAsFixed(2)}';
}

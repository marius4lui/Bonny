import 'package:bonny/models/receipt.dart';
import 'package:bonny/services/openrouter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt totals separate reimbursable and excluded items', () {
    final totals = calculateTotals([
      ReceiptItem.create(name: 'Bread', totalPrice: 2.49),
      ReceiptItem.create(
        name: 'Fanta',
        totalPrice: 1.99,
        reimbursable: false,
        excludeReason: 'Matched "Fanta"',
      ),
    ]);

    expect(totals.total, 4.48);
    expect(totals.reimbursable, 2.49);
    expect(totals.excluded, 1.99);
  });

  test('normalizes alternate receipt schema aliases', () {
    final normalized = normalizeReceiptJson({
      'merchant': 'Bäckerei Hieber GmbH',
      'iso_date': '2026-06-11',
      'currency': 'EUR',
      'final_receipt_total': 3.15,
      'line_items': [],
    });

    expect(normalized['merchant'], 'Bäckerei Hieber GmbH');
    expect(normalized['date'], '2026-06-11');
    expect(normalized['currency'], 'EUR');
    expect(normalized['receipt_total'], 3.15);
    expect(normalized['items'], isEmpty);
  });

  test('normalizes alternate item aliases', () {
    final normalized = normalizeReceiptJson({
      'merchant': 'Shop',
      'purchase_date': '2026-06-12',
      'total_amount': 5.5,
      'products': [
        {
          'description': 'Bread',
          'qty': 2,
          'price_each': 1.25,
          'line_total': 2.5,
        },
        {'item_name': 'Milk', 'price': 3.0, 'category': 'Groceries'},
      ],
    });

    final items = normalized['items'] as List;
    expect(normalized['date'], '2026-06-12');
    expect(normalized['receipt_total'], 5.5);
    expect(items.first['name'], 'Bread');
    expect(items.first['quantity'], 2);
    expect(items.first['unit_price'], 1.25);
    expect(items.first['total_price'], 2.5);
    expect(items.first['category'], 'Other');
    expect(items.last['name'], 'Milk');
    expect(items.last['total_price'], 3.0);
    expect(items.last['category'], 'Groceries');
  });
}

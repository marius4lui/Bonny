import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Receipt {
  Receipt({
    required this.id,
    required this.imagePath,
    required this.merchant,
    required this.purchaseDate,
    required this.currency,
    required this.receiptTotal,
    required this.reimbursableTotal,
    required this.excludedTotal,
    required this.createdAt,
    required this.items,
  });

  factory Receipt.create({
    required String imagePath,
    required String merchant,
    required DateTime purchaseDate,
    required String currency,
    required double receiptTotal,
    required List<ReceiptItem> items,
  }) {
    final calculated = calculateTotals(items);
    return Receipt(
      id: _uuid.v4(),
      imagePath: imagePath,
      merchant: merchant.trim().isEmpty ? 'Unknown merchant' : merchant.trim(),
      purchaseDate: purchaseDate,
      currency: currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase(),
      receiptTotal: receiptTotal <= 0 ? calculated.total : receiptTotal,
      reimbursableTotal: calculated.reimbursable,
      excludedTotal: calculated.excluded,
      createdAt: DateTime.now(),
      items: items,
    );
  }

  factory Receipt.fromJson(Map<dynamic, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((item) => ReceiptItem.fromJson(Map<dynamic, dynamic>.from(item)))
        .toList();
    return Receipt(
      id: json['id'] as String? ?? _uuid.v4(),
      imagePath: json['imagePath'] as String? ?? '',
      merchant: json['merchant'] as String? ?? 'Unknown merchant',
      purchaseDate:
          DateTime.tryParse(json['purchaseDate'] as String? ?? '') ??
          DateTime.now(),
      currency: json['currency'] as String? ?? 'EUR',
      receiptTotal: _asDouble(json['receiptTotal']),
      reimbursableTotal: _asDouble(json['reimbursableTotal']),
      excludedTotal: _asDouble(json['excludedTotal']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      items: items,
    ).recalculated();
  }

  final String id;
  final String imagePath;
  final String merchant;
  final DateTime purchaseDate;
  final String currency;
  final double receiptTotal;
  final double reimbursableTotal;
  final double excludedTotal;
  final DateTime createdAt;
  final List<ReceiptItem> items;

  Receipt copyWith({
    String? id,
    String? imagePath,
    String? merchant,
    DateTime? purchaseDate,
    String? currency,
    double? receiptTotal,
    double? reimbursableTotal,
    double? excludedTotal,
    DateTime? createdAt,
    List<ReceiptItem>? items,
  }) {
    return Receipt(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      merchant: merchant ?? this.merchant,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      currency: currency ?? this.currency,
      receiptTotal: receiptTotal ?? this.receiptTotal,
      reimbursableTotal: reimbursableTotal ?? this.reimbursableTotal,
      excludedTotal: excludedTotal ?? this.excludedTotal,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  Receipt recalculated() {
    final calculated = calculateTotals(items);
    return copyWith(
      receiptTotal: receiptTotal <= 0 ? calculated.total : receiptTotal,
      reimbursableTotal: calculated.reimbursable,
      excludedTotal: calculated.excluded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'merchant': merchant,
      'purchaseDate': purchaseDate.toIso8601String(),
      'currency': currency,
      'receiptTotal': receiptTotal,
      'reimbursableTotal': reimbursableTotal,
      'excludedTotal': excludedTotal,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class ReceiptItem {
  ReceiptItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unitPrice,
    required this.totalPrice,
    this.category,
    required this.reimbursable,
    this.excludeReason,
  });

  factory ReceiptItem.create({
    required String name,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? category,
    bool reimbursable = true,
    String? excludeReason,
  }) {
    final inferredTotal = totalPrice ?? ((quantity ?? 1) * (unitPrice ?? 0));
    return ReceiptItem(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Unnamed item' : name.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: inferredTotal,
      category: category?.trim().isEmpty == true ? null : category?.trim(),
      reimbursable: reimbursable,
      excludeReason: excludeReason,
    );
  }

  factory ReceiptItem.fromJson(Map<dynamic, dynamic> json) {
    return ReceiptItem(
      id: json['id'] as String? ?? _uuid.v4(),
      name: json['name'] as String? ?? 'Unnamed item',
      quantity: _nullableDouble(json['quantity']),
      unitPrice: _nullableDouble(json['unitPrice']),
      totalPrice: _asDouble(json['totalPrice']),
      category: json['category'] as String?,
      reimbursable: json['reimbursable'] as bool? ?? true,
      excludeReason: json['excludeReason'] as String?,
    );
  }

  final String id;
  final String name;
  final double? quantity;
  final double? unitPrice;
  final double totalPrice;
  final String? category;
  final bool reimbursable;
  final String? excludeReason;

  ReceiptItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? category,
    bool? reimbursable,
    String? excludeReason,
    bool clearExcludeReason = false,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      category: category ?? this.category,
      reimbursable: reimbursable ?? this.reimbursable,
      excludeReason: clearExcludeReason
          ? null
          : (excludeReason ?? this.excludeReason),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'category': category,
      'reimbursable': reimbursable,
      'excludeReason': excludeReason,
    };
  }
}

class ReceiptTotals {
  const ReceiptTotals({
    required this.total,
    required this.reimbursable,
    required this.excluded,
  });

  final double total;
  final double reimbursable;
  final double excluded;
}

ReceiptTotals calculateTotals(List<ReceiptItem> items) {
  var total = 0.0;
  var reimbursable = 0.0;
  var excluded = 0.0;
  for (final item in items) {
    total += item.totalPrice;
    if (item.reimbursable) {
      reimbursable += item.totalPrice;
    } else {
      excluded += item.totalPrice;
    }
  }
  return ReceiptTotals(
    total: _roundMoney(total),
    reimbursable: _roundMoney(reimbursable),
    excluded: _roundMoney(excluded),
  );
}

double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));

double _asDouble(dynamic value) => _nullableDouble(value) ?? 0;

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

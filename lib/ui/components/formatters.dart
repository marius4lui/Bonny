import 'package:intl/intl.dart';

String money(double value, [String currency = 'EUR']) {
  final formatter = NumberFormat.simpleCurrency(
    name: currency,
    decimalDigits: 2,
  );
  return formatter.format(value);
}

String monthLabel(DateTime date) => DateFormat.yMMMM().format(date);

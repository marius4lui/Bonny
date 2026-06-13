import '../models/receipt.dart';
import '../models/debug_log.dart';
import 'debug_log_service.dart';

class ExclusionService {
  ExclusionService({this.debugLog});

  DebugLogService? debugLog;

  List<ReceiptItem> applyRules(List<ReceiptItem> items, List<String> keywords) {
    return items.map((item) => applyToItem(item, keywords)).toList();
  }

  ReceiptItem applyToItem(ReceiptItem item, List<String> keywords) {
    final keyword = matchKeyword(item.name, keywords);
    final before = item.reimbursable;
    if (keyword == null) {
      return item.copyWith(reimbursable: true, clearExcludeReason: true);
    }
    final result = item.copyWith(
      reimbursable: false,
      excludeReason: 'Matched "$keyword"',
    );
    debugLog?.log(DebugLogType.rule, 'Exclusion rule matched', {
      'itemName': item.name,
      'normalizedName': _normalize(item.name),
      'matchedKeyword': keyword,
      'before': {'reimbursable': before, 'excludeReason': item.excludeReason},
      'after': {
        'reimbursable': result.reimbursable,
        'excludeReason': result.excludeReason,
      },
    });
    return result;
  }

  String? matchKeyword(String name, List<String> keywords) {
    final lowerName = _normalize(name);
    for (final keyword in keywords) {
      final normalized = _normalize(keyword);
      if (normalized.isNotEmpty && lowerName.contains(normalized)) {
        return keyword.trim();
      }
    }
    return null;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

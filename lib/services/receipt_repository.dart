import 'package:hive/hive.dart';

import '../models/receipt.dart';
import 'debug_log_service.dart';

class ReceiptRepository {
  ReceiptRepository({this.debugLog});

  static const _boxName = 'receipts';

  DebugLogService? debugLog;
  Box<Map>? _box;

  Future<void> open() async {
    final stopwatch = Stopwatch()..start();
    try {
      _box = await Hive.openBox<Map>(_boxName);
      await debugLog?.logStorage(
        operation: 'open',
        entity: 'receipt_box',
        success: true,
        duration: stopwatch.elapsed,
      );
    } catch (error, stackTrace) {
      await debugLog?.logStorage(
        operation: 'open',
        entity: 'receipt_box',
        success: false,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  List<Receipt> all() {
    final stopwatch = Stopwatch()..start();
    try {
      final receipts = _box!.values
          .map((json) => Receipt.fromJson(Map<dynamic, dynamic>.from(json)))
          .toList();
      receipts.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      debugLog?.logStorage(
        operation: 'read',
        entity: 'receipt',
        success: true,
        duration: stopwatch.elapsed,
        payload: {'count': receipts.length},
      );
      return receipts;
    } catch (error, stackTrace) {
      debugLog?.logStorage(
        operation: 'read',
        entity: 'receipt',
        success: false,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> save(Receipt receipt) async {
    final stopwatch = Stopwatch()..start();
    final payload = receipt.recalculated().toJson();
    try {
      await _box!.put(receipt.id, payload);
      await debugLog?.logStorage(
        operation: 'create_or_update',
        entity: 'receipt',
        entityId: receipt.id,
        success: true,
        duration: stopwatch.elapsed,
        payload: payload,
      );
    } catch (error, stackTrace) {
      await debugLog?.logStorage(
        operation: 'create_or_update',
        entity: 'receipt',
        entityId: receipt.id,
        success: false,
        duration: stopwatch.elapsed,
        payload: payload,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _box!.delete(id);
      await debugLog?.logStorage(
        operation: 'delete',
        entity: 'receipt',
        entityId: id,
        success: true,
        duration: stopwatch.elapsed,
      );
    } catch (error, stackTrace) {
      await debugLog?.logStorage(
        operation: 'delete',
        entity: 'receipt',
        entityId: id,
        success: false,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

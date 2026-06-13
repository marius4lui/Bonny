import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/debug_log.dart';

class DebugLogService {
  static const _boxName = 'debug_logs';
  static const _uuid = Uuid();
  static const maxEntries = 300;
  static final _base64ImagePattern = RegExp(
    r'data:image\/[a-zA-Z0-9.+-]+;base64,[A-Za-z0-9+/=]+',
  );

  Box<Map>? _box;
  bool enabled = false;

  Future<void> open() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  List<DebugLogEntry> entries({
    String? type,
    List<String>? types,
    String? queueId,
  }) {
    final values = _box?.values ?? const Iterable<Map>.empty();
    final logs = values
        .map((json) => DebugLogEntry.fromJson(Map<dynamic, dynamic>.from(json)))
        .where((entry) {
          final matchesType =
              (type == null && types == null) ||
              (type != null && entry.type == type) ||
              (types != null && types.contains(entry.type));
          final matchesQueue =
              queueId == null ||
              queueId.trim().isEmpty ||
              _containsQueueId(entry.data, queueId.trim());
          return matchesType && matchesQueue;
        })
        .toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  DebugLogEntry? latestFailedRequest() {
    return entries(
      type: DebugLogType.request,
    ).where((entry) => entry.isFailure).cast<DebugLogEntry?>().firstOrNull;
  }

  DebugLogEntry? latestError() {
    return entries(type: DebugLogType.error).cast<DebugLogEntry?>().firstOrNull;
  }

  DebugLogEntry? latestExtraction() {
    return entries(
      type: DebugLogType.extraction,
    ).cast<DebugLogEntry?>().firstOrNull;
  }

  Future<void> clear() async {
    await _box?.clear();
  }

  Future<void> log(
    String type,
    String title,
    Map<String, dynamic> data, {
    bool force = false,
  }) async {
    if (!enabled && !force) return;
    final entry = DebugLogEntry(
      id: _uuid.v4(),
      type: type,
      timestamp: DateTime.now(),
      title: title,
      data: sanitize(data),
    );
    await _box?.put(entry.id, entry.toJson());
    await _trim();
  }

  Future<void> logStorage({
    required String operation,
    required String entity,
    String? entityId,
    required bool success,
    required Duration duration,
    Map<String, dynamic>? payload,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return log(DebugLogType.storage, '$entity $operation', {
      'operation': operation,
      'entity': entity,
      'entityId': entityId,
      'success': success,
      'durationMs': duration.inMilliseconds,
      'payload': payload,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    });
  }

  Future<void> logError(
    Object error,
    StackTrace stackTrace, {
    String context = 'Unhandled error',
    Map<String, dynamic>? data,
  }) {
    final payload = <String, dynamic>{
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    };
    if (data != null) {
      payload['contextData'] = data;
    }
    return log(DebugLogType.error, context, payload);
  }

  Future<void> logAppInfo(Map<String, dynamic> data) {
    return log(DebugLogType.app, 'App info', data);
  }

  Future<void> logQueue(
    String title,
    Map<String, dynamic> data, {
    String type = DebugLogType.importQueue,
  }) {
    return log(type, title, data);
  }

  String exportBundle() {
    final bundle = {
      'app': 'Bonny',
      'exportedAt': DateTime.now().toIso8601String(),
      'sanitized': true,
      'debugModeEnabled': enabled,
      'entries': entries().map((entry) => entry.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(sanitize(bundle));
  }

  Map<String, dynamic> imageMetadata(File file) {
    final exists = file.existsSync();
    final stat = exists ? file.statSync() : null;
    return {
      'path': p.basename(file.path),
      'extension': p.extension(file.path),
      'exists': exists,
      'bytes': exists ? file.lengthSync() : 0,
      'modified': stat?.modified.toIso8601String(),
    };
  }

  dynamic sanitize(dynamic value) {
    if (value == null || value is num || value is bool) return value;
    if (value is String) return _sanitizeString(value);
    if (value is DateTime) return value.toIso8601String();
    if (value is List) return value.map(sanitize).toList();
    if (value is Map) {
      return value.map((key, entryValue) {
        final keyText = key.toString();
        if (_isSecretKey(keyText)) {
          return MapEntry(keyText, _redactedSecret(entryValue));
        }
        if (keyText == 'url' &&
            entryValue is String &&
            entryValue.startsWith('data:image/')) {
          return MapEntry(keyText, _imageDataUrlMetadata(entryValue));
        }
        return MapEntry(keyText, sanitize(entryValue));
      });
    }
    return _sanitizeString(value.toString());
  }

  Map<String, dynamic> requestImageMetadata(String dataUrl) {
    return _imageDataUrlMetadata(dataUrl);
  }

  Map<String, dynamic> _imageDataUrlMetadata(String dataUrl) {
    final commaIndex = dataUrl.indexOf(',');
    final header = commaIndex >= 0 ? dataUrl.substring(0, commaIndex) : dataUrl;
    final payload = commaIndex >= 0 ? dataUrl.substring(commaIndex + 1) : '';
    final decodedBytes = (payload.length * 3 / 4).floor();
    return {
      'type': 'redacted_base64_image',
      'mime': header.replaceFirst('data:', '').replaceFirst(';base64', ''),
      'base64Chars': payload.length,
      'estimatedBytes': decodedBytes,
    };
  }

  String _sanitizeString(String value) {
    var sanitized = value.replaceAllMapped(
      _base64ImagePattern,
      (match) => jsonEncode(_imageDataUrlMetadata(match.group(0)!)),
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+'),
      (_) => 'Bearer ${_redactedSecret('token')}',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(sk-or-v1-)[A-Za-z0-9._-]+'),
      (match) => '${match.group(1)}...redacted',
    );
    return sanitized;
  }

  bool _isSecretKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('authorization') ||
        lower.contains('api_key') ||
        lower.contains('apikey') ||
        lower == 'key' ||
        lower.contains('token') ||
        lower.contains('secret');
  }

  String _redactedSecret(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '[redacted]';
    final suffix = text.length > 6 ? text.substring(text.length - 4) : '';
    return suffix.isEmpty ? '[redacted]' : '[redacted]...$suffix';
  }

  Future<void> _trim() async {
    final box = _box;
    if (box == null || box.length <= maxEntries) return;
    final logs = entries();
    for (final entry in logs.skip(maxEntries)) {
      await box.delete(entry.id);
    }
  }

  bool _containsQueueId(dynamic value, String queueId) {
    if (value == null) return false;
    if (value is String) return value == queueId;
    if (value is List) {
      return value.any((entry) => _containsQueueId(entry, queueId));
    }
    if (value is Map) {
      return value.entries.any(
        (entry) =>
            (entry.key.toString() == 'queueId' &&
                entry.value?.toString() == queueId) ||
            _containsQueueId(entry.value, queueId),
      );
    }
    return false;
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

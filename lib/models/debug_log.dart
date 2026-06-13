class DebugLogEntry {
  const DebugLogEntry({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.data,
  });

  factory DebugLogEntry.fromJson(Map<dynamic, dynamic> json) {
    return DebugLogEntry(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      title: json['title'] as String? ?? 'Debug event',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }

  final String id;
  final String type;
  final DateTime timestamp;
  final String title;
  final Map<String, dynamic> data;

  bool get isFailure {
    final status = data['status']?.toString().toLowerCase();
    final success = data['success'];
    return type == DebugLogType.error ||
        status == 'error' ||
        status == 'failed' ||
        success == false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'data': data,
    };
  }
}

class DebugLogType {
  static const request = 'request';
  static const extraction = 'extraction';
  static const storage = 'storage';
  static const rule = 'rule';
  static const error = 'error';
  static const manualEdit = 'manual_edit';
  static const app = 'app';
  static const importQueue = 'import_queue';
  static const queueExtraction = 'queue_extraction';
  static const queueReview = 'queue_review';
  static const retry = 'retry';
}
